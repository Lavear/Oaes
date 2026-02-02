//======================================================
// File: aes_top.v
// Description:
// Top-level AES-128 encryption module.
// Implements correct AES flow including
// INITIAL AddRoundKey (round 0).
//======================================================

module aes_top (
    input         clk,
    input         rst_n,
    input         start,
    input  [127:0] plaintext,
    input  [127:0] cipher_key,
    output [127:0] ciphertext,
    output        done
);

    // --------------------------------------------------
    // Internal wires
    // --------------------------------------------------
    wire [127:0] state_q;        // current AES state
    wire [127:0] next_state;     // datapath output
    wire [127:0] round_key;      // round key
    wire [127:0] initial_state;  // plaintext ⊕ key (round 0)
    wire [3:0]   round;          // round counter
    wire         state_en;       // state enable
    wire         final_round;    // final round indicator

    // --------------------------------------------------
    // Initial AddRoundKey (round 0 only)
    // --------------------------------------------------
    // FIX APPLIED HERE: Used cipher_key instead of round_key
    assign initial_state = plaintext ^ cipher_key;

    // --------------------------------------------------
    // State Register
    // --------------------------------------------------
    state_reg u_state_reg (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (state_en),
        .d     ( (round == 4'd0) ? initial_state : next_state ),
        .q     (state_q)
    );

    // --------------------------------------------------
    // AES Datapath (one round)
    // --------------------------------------------------
    aes_datapath u_datapath (
        .state_in   (state_q),
        .round_key  (round_key),
        .final_round(final_round),
        .state_out  (next_state)
    );

    // --------------------------------------------------
    // Sequential Key Expansion
    // --------------------------------------------------
    key_expansion u_key_expansion (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (state_en),     // advance key with state
        .round      (round),
        .cipher_key (cipher_key),
        .round_key  (round_key)
    );

    // --------------------------------------------------
    // AES Controller
    // --------------------------------------------------
    aes_controller u_controller (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .round      (round),
        .state_en   (state_en),
        .final_round(final_round),
        .done       (done)
    );

    // --------------------------------------------------
    // Ciphertext output
    // --------------------------------------------------
    assign ciphertext = state_q;

endmodule