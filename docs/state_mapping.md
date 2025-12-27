# AES State Mapping Definition

## 1. Purpose
This document defines the internal representation of the 128-bit AES state used in the AES cryptographic datapath. A consistent state mapping is critical for correct implementation of SubBytes, ShiftRows, MixColumns and AddRoundKey operations.


All RTL Modules in this project strictly follow the mapping defined here.


## 2. State Vector Representation

The AES state is represented as a single 128-bit vector:

 state[127:0]

The vector is divided into 16 bytes, each 8 bits wide, as shown below

| Byte Index | Bit Range       |
|-----------:|-----------------|
| byte 0     | state[127:120]  |
| byte 1     | state[119:112]  |
| byte 2     | state[111:104]  |
| byte 3     | state[103:96]   |
| byte 4     | state[95:88]    |
| byte 5     | state[87:80]    |
| byte 6     | state[79:72]    |
| byte 7     | state[71:64]    |
| byte 8     | state[63:56]    |
| byte 9     | state[55:48]    |
| byte 10    | state[47:40]    |
| byte 11    | state[39:32]    |
| byte 12    | state[31:24]    |
| byte 13    | state[23:16]    |
| byte 14    | state[15:8]     |
| byte 15    | state[7:0]      |


## 3. AES State Matrix Layout

The 16 bytes are arranged into the AES 4x4 state matrix using column-major ordering, as defined in the AES standard.

    | byte 0   byte 4   byte 8   byte 12 |
    | byte 1   byte 5   byte 9   byte 13 |
    | byte 2   byte 6   byte 10  byte 14 |
    | byte 3   byte 7   byte 11  byte 15 |

This layout is used by:
- ShiftRows operation
- MixColumns operation
- Round key alignment

## 4. PLaintext and Ciphertext Convention

The 128-bit plaintext input is mapped directly into the state vector according to the byte ordering defined above.

- The most significant byte of the plaintext corresponds to byte 0
- The least significant byte corresponds to byte 15

## 5. Design Rationale

- Byte-level indexing simplifies SubBytes implementation
- Column-major ordering matches the AES mathematical definition
- Consistent mapping prevents byte permutation errors
- The mapping is compatible with standard AES test vectors

## 6. Reference

This state mapping is consistent with the byte ordering used in
open-source AES reference implementations.

Reference repository:
- secworks/aes

Reference file:
- src/rtl/aes_encipher_block.v

The reference was used only to understand byte ordering conventions.
No RTL code was reused.

## 7. Usage Rule

All AES datapath modules must treat the state vector according to this
document. Any change to the state representation must be reflected here
and in all dependent RTL modules.