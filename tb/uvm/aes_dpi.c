/*=====================================================================
 * aes_dpi.c  -  the "golden reference" AES-128, written in plain C
 *               straight from the FIPS-197 standard.
 *
 * The scoreboard calls c_aes_encrypt() through DPI-C to find out what
 * the ciphertext SHOULD be, then compares that against what your
 * hardware produced. (See aes_scoreboard.svh for how the bridge works.)
 *
 * Why C and not SystemVerilog? If the same person wrote both the RTL and
 * the reference in the same language on the same day, they tend to make
 * the same mistake twice. An independent implementation catches more.
 *
 * BYTE ORDER - must match aes_scoreboard.svh exactly:
 *     byte[0]  = the most significant byte  (bits 127:120)
 *     byte[15] = the least significant byte (bits 7:0)
 *
 * CHECK IT ON ITS OWN, before you ever start a simulation:
 *     gcc -DAES_DPI_SELFTEST aes_dpi.c -o aes_selftest && ./aes_selftest
 * It runs four official NIST vectors. Debug the answer key first, then
 * the hardware.
 *===================================================================*/

#include <stdint.h>
#include <string.h>

/*---------------------------------------------------------------------
 * AES S-box (FIPS-197 Figure 7). The non-linear substitution that gives
 * AES its "confusion" property.
 *-------------------------------------------------------------------*/
static const uint8_t SBOX[256] = {
    0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,
    0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,
    0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,
    0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75,
    0x09,0x83,0x2c,0x1a,0x1b,0x6e,0x5a,0xa0,0x52,0x3b,0xd6,0xb3,0x29,0xe3,0x2f,0x84,
    0x53,0xd1,0x00,0xed,0x20,0xfc,0xb1,0x5b,0x6a,0xcb,0xbe,0x39,0x4a,0x4c,0x58,0xcf,
    0xd0,0xef,0xaa,0xfb,0x43,0x4d,0x33,0x85,0x45,0xf9,0x02,0x7f,0x50,0x3c,0x9f,0xa8,
    0x51,0xa3,0x40,0x8f,0x92,0x9d,0x38,0xf5,0xbc,0xb6,0xda,0x21,0x10,0xff,0xf3,0xd2,
    0xcd,0x0c,0x13,0xec,0x5f,0x97,0x44,0x17,0xc4,0xa7,0x7e,0x3d,0x64,0x5d,0x19,0x73,
    0x60,0x81,0x4f,0xdc,0x22,0x2a,0x90,0x88,0x46,0xee,0xb8,0x14,0xde,0x5e,0x0b,0xdb,
    0xe0,0x32,0x3a,0x0a,0x49,0x06,0x24,0x5c,0xc2,0xd3,0xac,0x62,0x91,0x95,0xe4,0x79,
    0xe7,0xc8,0x37,0x6d,0x8d,0xd5,0x4e,0xa9,0x6c,0x56,0xf4,0xea,0x65,0x7a,0xae,0x08,
    0xba,0x78,0x25,0x2e,0x1c,0xa6,0xb4,0xc6,0xe8,0xdd,0x74,0x1f,0x4b,0xbd,0x8b,0x8a,
    0x70,0x3e,0xb5,0x66,0x48,0x03,0xf6,0x0e,0x61,0x35,0x57,0xb9,0x86,0xc1,0x1d,0x9e,
    0xe1,0xf8,0x98,0x11,0x69,0xd9,0x8e,0x94,0x9b,0x1e,0x87,0xe9,0xce,0x55,0x28,0xdf,
    0x8c,0xa1,0x89,0x0d,0xbf,0xe6,0x42,0x68,0x41,0x99,0x2d,0x0f,0xb0,0x54,0xbb,0x16
};

/* Round constants for the key schedule (FIPS-197 Sec 5.2). */
static const uint8_t RCON[10] = {
    0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x1b,0x36
};

/*---------------------------------------------------------------------
 * xtime() - multiply by x (i.e. by 0x02) in GF(2^8) modulo the AES
 * irreducible polynomial x^8 + x^4 + x^3 + x + 1 (0x11b).
 * Shift left; if bit7 was set, the result overflowed the field so we
 * reduce it by XORing 0x1b.
 *-------------------------------------------------------------------*/
static uint8_t xtime(uint8_t x)
{
    return (uint8_t)((x << 1) ^ ((x & 0x80) ? 0x1b : 0x00));
}

/* Multiply two GF(2^8) elements (only small constants are needed here). */
static uint8_t gmul(uint8_t a, uint8_t b)
{
    uint8_t r = 0;
    for (int i = 0; i < 8; i++) {
        if (b & 1) r ^= a;
        a = xtime(a);
        b >>= 1;
    }
    return r;
}

/*---------------------------------------------------------------------
 * Key expansion: 128-bit cipher key -> 11 round keys of 16 bytes each.
 * Words are 4 bytes; w[0..3] come from the key, then
 *     w[i] = w[i-4] ^ ( (i%4==0) ? SubWord(RotWord(w[i-1])) ^ Rcon : w[i-1] )
 *-------------------------------------------------------------------*/
static void aes128_key_expansion(const uint8_t *key, uint8_t rk[11][16])
{
    memcpy(rk[0], key, 16);

    for (int r = 1; r <= 10; r++) {
        const uint8_t *prev = rk[r - 1];
        uint8_t t[4];

        /* RotWord: take last word (bytes 12..15) and rotate left by one byte */
        t[0] = prev[13];
        t[1] = prev[14];
        t[2] = prev[15];
        t[3] = prev[12];

        /* SubWord: apply the S-box to each of the four bytes */
        for (int i = 0; i < 4; i++) t[i] = SBOX[t[i]];

        /* XOR with the round constant (only the first byte is non-zero) */
        t[0] ^= RCON[r - 1];

        /* w[4r] = w[4r-4] ^ g(w[4r-1]) */
        for (int i = 0; i < 4; i++) rk[r][i] = prev[i] ^ t[i];

        /* w[4r+k] = w[4r+k-1] ^ w[4r+k-4]  for k = 1,2,3 */
        for (int w = 1; w < 4; w++)
            for (int i = 0; i < 4; i++)
                rk[r][w * 4 + i] = rk[r][(w - 1) * 4 + i] ^ prev[w * 4 + i];
    }
}

/*---------------------------------------------------------------------
 * The AES state is a 4x4 byte matrix filled COLUMN-first, so the flat
 * byte index i maps to state[row = i % 4][col = i / 4].
 *-------------------------------------------------------------------*/

static void sub_bytes(uint8_t s[16])
{
    for (int i = 0; i < 16; i++) s[i] = SBOX[s[i]];
}

/* Row r is rotated left by r positions. */
static void shift_rows(uint8_t s[16])
{
    uint8_t t[16];
    for (int c = 0; c < 4; c++)
        for (int r = 0; r < 4; r++)
            t[c * 4 + r] = s[((c + r) & 3) * 4 + r];
    memcpy(s, t, 16);
}

/* Each column is multiplied by the fixed polynomial matrix. */
static void mix_columns(uint8_t s[16])
{
    for (int c = 0; c < 4; c++) {
        uint8_t *a = &s[c * 4];
        uint8_t b0 = (uint8_t)(gmul(a[0],2) ^ gmul(a[1],3) ^ a[2]          ^ a[3]);
        uint8_t b1 = (uint8_t)(a[0]          ^ gmul(a[1],2) ^ gmul(a[2],3) ^ a[3]);
        uint8_t b2 = (uint8_t)(a[0]          ^ a[1]          ^ gmul(a[2],2) ^ gmul(a[3],3));
        uint8_t b3 = (uint8_t)(gmul(a[0],3) ^ a[1]          ^ a[2]          ^ gmul(a[3],2));
        a[0] = b0; a[1] = b1; a[2] = b2; a[3] = b3;
    }
}

static void add_round_key(uint8_t s[16], const uint8_t rk[16])
{
    for (int i = 0; i < 16; i++) s[i] ^= rk[i];
}

/*=====================================================================
 * c_aes_encrypt - the function imported by the UVM scoreboard.
 *
 * NOTE ON `const`: the SV side declares pt/key as `input`, so the
 * simulator guarantees it will not write through those pointers. Marking
 * them const in C documents that contract and lets the compiler help.
 *===================================================================*/
void c_aes_encrypt(const uint8_t *pt, const uint8_t *key, uint8_t *ct)
{
    uint8_t rk[11][16];
    uint8_t state[16];

    aes128_key_expansion(key, rk);
    memcpy(state, pt, 16);

    /* Round 0: initial AddRoundKey only. */
    add_round_key(state, rk[0]);

    /* Rounds 1..9: full round. */
    for (int r = 1; r <= 9; r++) {
        sub_bytes(state);
        shift_rows(state);
        mix_columns(state);
        add_round_key(state, rk[r]);
    }

    /* Round 10: final round has NO MixColumns. This asymmetry is what the
     * RTL's `final_round` control signal exists to implement. */
    sub_bytes(state);
    shift_rows(state);
    add_round_key(state, rk[10]);

    memcpy(ct, state, 16);
}

/*---------------------------------------------------------------------
 * Optional standalone self-test. Not compiled into the simulation.
 *-------------------------------------------------------------------*/
#ifdef AES_DPI_SELFTEST
#include <stdio.h>

static int check(const char *name,
                 const uint8_t *k, const uint8_t *p, const uint8_t *exp)
{
    uint8_t got[16];
    c_aes_encrypt(p, k, got);
    if (memcmp(got, exp, 16) != 0) {
        printf("FAIL %s\n  got ", name);
        for (int i = 0; i < 16; i++) printf("%02x", got[i]);
        printf("\n  exp ");
        for (int i = 0; i < 16; i++) printf("%02x", exp[i]);
        printf("\n");
        return 1;
    }
    printf("PASS %s\n", name);
    return 0;
}

int main(void)
{
    int fails = 0;

    /* FIPS-197 Appendix C.1 */
    {
        uint8_t k[16] = {0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,
                         0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f};
        uint8_t p[16] = {0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77,
                         0x88,0x99,0xaa,0xbb,0xcc,0xdd,0xee,0xff};
        uint8_t e[16] = {0x69,0xc4,0xe0,0xd8,0x6a,0x7b,0x04,0x30,
                         0xd8,0xcd,0xb7,0x80,0x70,0xb4,0xc5,0x5a};
        fails += check("FIPS-197 C.1", k, p, e);
    }

    /* FIPS-197 Appendix B */
    {
        uint8_t k[16] = {0x2b,0x7e,0x15,0x16,0x28,0xae,0xd2,0xa6,
                         0xab,0xf7,0x15,0x88,0x09,0xcf,0x4f,0x3c};
        uint8_t p[16] = {0x32,0x43,0xf6,0xa8,0x88,0x5a,0x30,0x8d,
                         0x31,0x31,0x98,0xa2,0xe0,0x37,0x07,0x34};
        uint8_t e[16] = {0x39,0x25,0x84,0x1d,0x02,0xdc,0x09,0xfb,
                         0xdc,0x11,0x85,0x97,0x19,0x6a,0x0b,0x32};
        fails += check("FIPS-197 B", k, p, e);
    }

    /* NIST SP 800-38A F.1.1 ECB-AES128 block #1 */
    {
        uint8_t k[16] = {0x2b,0x7e,0x15,0x16,0x28,0xae,0xd2,0xa6,
                         0xab,0xf7,0x15,0x88,0x09,0xcf,0x4f,0x3c};
        uint8_t p[16] = {0x6b,0xc1,0xbe,0xe2,0x2e,0x40,0x9f,0x96,
                         0xe9,0x3d,0x7e,0x11,0x73,0x93,0x17,0x2a};
        uint8_t e[16] = {0x3a,0xd7,0x7b,0xb4,0x0d,0x7a,0x36,0x60,
                         0xa8,0x9e,0xca,0xf3,0x24,0x66,0xef,0x97};
        fails += check("SP800-38A F.1.1", k, p, e);
    }

    /* All-zero key and plaintext (an important edge case for our sequence). */
    {
        uint8_t k[16] = {0};
        uint8_t p[16] = {0};
        uint8_t e[16] = {0x66,0xe9,0x4b,0xd4,0xef,0x8a,0x2c,0x3b,
                         0x88,0x4c,0xfa,0x59,0xca,0x34,0x2b,0x2e};
        fails += check("all-zeros", k, p, e);
    }

    printf("%s\n", fails ? "SELF-TEST FAILED" : "ALL SELF-TESTS PASSED");
    return fails ? 1 : 0;
}
#endif
