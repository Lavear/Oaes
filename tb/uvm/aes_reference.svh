//======================================================================
// aes_reference.svh  -  FEATURE 2 (the "answer key"), written in plain
// SystemVerilog straight from the FIPS-197 standard.
//
// This used to be a separate C file reached over DPI-C. That's the more
// common real-world setup (an independent implementation, in a different
// language, catches more bugs than one written by the same person on the
// same day). It's kept out here only because DPI needs a full simulator
// license to link the C object file, and this project needs to run on
// ModelSim Starter Edition / EDA Playground, which don't support DPI-C.
// A plain SystemVerilog function has no such requirement.
//
// aes_scoreboard.svh calls aes_encrypt() below exactly the way it used
// to call the C function - same inputs, same output, same job.
//======================================================================

// S-box: FIPS-197 Figure 7. Given a byte, replace it with the value at
// that position in this table. This is the "Confusion" step.
//
// This is a data declaration with a compile-time initializer, not
// procedural code - the `'{ ... }` array-assignment-pattern syntax is
// the SystemVerilog way to write an array literal. It's legal here
// because this file gets `included` inside a `package` (aes_pkg.sv),
// and a package can only hold declarations - an `initial` block would
// not be allowed.
const bit [7:0] AES_SBOX [0:255] = '{
    8'h63,8'h7c,8'h77,8'h7b,8'hf2,8'h6b,8'h6f,8'hc5,8'h30,8'h01,8'h67,8'h2b,8'hfe,8'hd7,8'hab,8'h76,
    8'hca,8'h82,8'hc9,8'h7d,8'hfa,8'h59,8'h47,8'hf0,8'had,8'hd4,8'ha2,8'haf,8'h9c,8'ha4,8'h72,8'hc0,
    8'hb7,8'hfd,8'h93,8'h26,8'h36,8'h3f,8'hf7,8'hcc,8'h34,8'ha5,8'he5,8'hf1,8'h71,8'hd8,8'h31,8'h15,
    8'h04,8'hc7,8'h23,8'hc3,8'h18,8'h96,8'h05,8'h9a,8'h07,8'h12,8'h80,8'he2,8'heb,8'h27,8'hb2,8'h75,
    8'h09,8'h83,8'h2c,8'h1a,8'h1b,8'h6e,8'h5a,8'ha0,8'h52,8'h3b,8'hd6,8'hb3,8'h29,8'he3,8'h2f,8'h84,
    8'h53,8'hd1,8'h00,8'hed,8'h20,8'hfc,8'hb1,8'h5b,8'h6a,8'hcb,8'hbe,8'h39,8'h4a,8'h4c,8'h58,8'hcf,
    8'hd0,8'hef,8'haa,8'hfb,8'h43,8'h4d,8'h33,8'h85,8'h45,8'hf9,8'h02,8'h7f,8'h50,8'h3c,8'h9f,8'ha8,
    8'h51,8'ha3,8'h40,8'h8f,8'h92,8'h9d,8'h38,8'hf5,8'hbc,8'hb6,8'hda,8'h21,8'h10,8'hff,8'hf3,8'hd2,
    8'hcd,8'h0c,8'h13,8'hec,8'h5f,8'h97,8'h44,8'h17,8'hc4,8'ha7,8'h7e,8'h3d,8'h64,8'h5d,8'h19,8'h73,
    8'h60,8'h81,8'h4f,8'hdc,8'h22,8'h2a,8'h90,8'h88,8'h46,8'hee,8'hb8,8'h14,8'hde,8'h5e,8'h0b,8'hdb,
    8'he0,8'h32,8'h3a,8'h0a,8'h49,8'h06,8'h24,8'h5c,8'hc2,8'hd3,8'hac,8'h62,8'h91,8'h95,8'he4,8'h79,
    8'he7,8'hc8,8'h37,8'h6d,8'h8d,8'hd5,8'h4e,8'ha9,8'h6c,8'h56,8'hf4,8'hea,8'h65,8'h7a,8'hae,8'h08,
    8'hba,8'h78,8'h25,8'h2e,8'h1c,8'ha6,8'hb4,8'hc6,8'he8,8'hdd,8'h74,8'h1f,8'h4b,8'hbd,8'h8b,8'h8a,
    8'h70,8'h3e,8'hb5,8'h66,8'h48,8'h03,8'hf6,8'h0e,8'h61,8'h35,8'h57,8'hb9,8'h86,8'hc1,8'h1d,8'h9e,
    8'he1,8'hf8,8'h98,8'h11,8'h69,8'hd9,8'h8e,8'h94,8'h9b,8'h1e,8'h87,8'he9,8'hce,8'h55,8'h28,8'hdf,
    8'h8c,8'ha1,8'h89,8'h0d,8'hbf,8'he6,8'h42,8'h68,8'h41,8'h99,8'h2d,8'h0f,8'hb0,8'h54,8'hbb,8'h16
};

// Round constants: FIPS-197 section 5.2, used once per round during key
// expansion.
const bit [7:0] AES_RCON [0:10] = '{
    8'h00,8'h01,8'h02,8'h04,8'h08,8'h10,8'h20,8'h40,8'h80,8'h1b,8'h36
};

// Galois-field "times 2", FIPS-197 section 4.2.1. Used by MixColumns.
function automatic bit [7:0] aes_xtime(input bit [7:0] b);
    aes_xtime = (b << 1) ^ (b[7] ? 8'h1B : 8'h00);
endfunction

// The whole encryption, FIPS-197 section 5.1. `automatic` gives every
// call its own local variables, which matters here because the
// scoreboard may call this from many transactions back to back.
function automatic bit [127:0] aes_encrypt(input bit [127:0] plain_text,
                                            input bit [127:0] key);
    bit [7:0] s   [0:15];   // the working "state" - 16 bytes
    bit [7:0] tmp [0:15];
    bit [7:0] rk  [0:175];  // 11 round keys x 16 bytes, expanded from `key`
    bit [7:0] t0, t1, t2, t3, u0, u1, u2, u3;
    bit [7:0] a0, a1, a2, a3;

    // Unpack the 128-bit inputs into bytes, most-significant byte first -
    // this ordering must match aes_scoreboard.svh's to_bytes()/from_bytes().
    for (int i = 0; i < 16; i++) begin
        s [i] = plain_text[127 - 8*i -: 8];
        rk[i] = key       [127 - 8*i -: 8];
    end

    // Key expansion: turn the 16-byte key into 11 round keys (176 bytes).
    for (int i = 4; i < 44; i++) begin
        t0 = rk[4*(i-1) + 0];
        t1 = rk[4*(i-1) + 1];
        t2 = rk[4*(i-1) + 2];
        t3 = rk[4*(i-1) + 3];
        if (i % 4 == 0) begin
            // Once per 4 words: rotate, substitute through the S-box,
            // then XOR in the round constant.
            u0 = AES_SBOX[t1] ^ AES_RCON[i/4];
            u1 = AES_SBOX[t2];
            u2 = AES_SBOX[t3];
            u3 = AES_SBOX[t0];
            t0 = u0; t1 = u1; t2 = u2; t3 = u3;
        end
        rk[4*i + 0] = rk[4*(i-4) + 0] ^ t0;
        rk[4*i + 1] = rk[4*(i-4) + 1] ^ t1;
        rk[4*i + 2] = rk[4*(i-4) + 2] ^ t2;
        rk[4*i + 3] = rk[4*(i-4) + 3] ^ t3;
    end

    // Round 0: AddRoundKey only.
    for (int i = 0; i < 16; i++) s[i] = s[i] ^ rk[i];

    // Rounds 1-10.
    for (int round = 1; round <= 10; round++) begin

        // SubBytes - look every byte up in the S-box.
        for (int i = 0; i < 16; i++) s[i] = AES_SBOX[s[i]];

        // ShiftRows - row r shifts left by r positions. State is stored
        // column-major (index = row + 4*column), which is why the index
        // math looks like this rather than a simple rotate.
        for (int c = 0; c < 4; c++)
            for (int r = 0; r < 4; r++)
                tmp[r + 4*c] = s[r + 4*((c + r) % 4)];
        for (int i = 0; i < 16; i++) s[i] = tmp[i];

        // MixColumns - skipped on the final round (FIPS-197 5.1).
        if (round != 10) begin
            for (int c = 0; c < 4; c++) begin
                a0 = s[4*c+0]; a1 = s[4*c+1]; a2 = s[4*c+2]; a3 = s[4*c+3];
                s[4*c+0] =  aes_xtime(a0)          ^ (aes_xtime(a1) ^ a1) ^  a2                 ^  a3;
                s[4*c+1] =  a0                     ^  aes_xtime(a1)      ^ (aes_xtime(a2) ^ a2) ^  a3;
                s[4*c+2] =  a0                     ^  a1                 ^  aes_xtime(a2)       ^ (aes_xtime(a3) ^ a3);
                s[4*c+3] = (aes_xtime(a0) ^ a0)     ^  a1                 ^  a2                 ^  aes_xtime(a3);
            end
        end

        // AddRoundKey.
        for (int i = 0; i < 16; i++) s[i] = s[i] ^ rk[16*round + i];
    end

    // Repack the bytes into the 128-bit ciphertext.
    aes_encrypt = '0;
    for (int i = 0; i < 16; i++) aes_encrypt[127 - 8*i -: 8] = s[i];
endfunction
