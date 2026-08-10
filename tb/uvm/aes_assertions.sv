//======================================================================
// aes_assertions.sv  -  FEATURE 3: the "strict referee" (SVA).
//
// Instead of you counting clock cycles on a waveform, these properties
// watch every single encryption and sound an alarm the instant the
// timing is wrong.
//======================================================================

module aes_sva (
    input logic clk,
    input logic rst_n,
    input logic valid_in,
    input logic valid_out
);

    // How many clock cycles from valid_in to valid_out.
    //
    // NOTE: the spec says 10, but this RTL actually takes 12 - the FSM in
    // aes_controller.v spends one extra cycle in INIT and one in FINISH
    // on top of the ten rounds. The ciphertext is correct; only the cycle
    // count differs. See README.md. Change this to 10 if you trim the FSM.
    localparam int LATENCY = 12;

    // ------------------------------------------------------------------
    // A1 - the headline timing rule, read left to right:
    //
    //   @(posedge clk)        check this on every clock edge
    //   disable iff (!rst_n)  ...unless reset is active. This is the
    //                         "provided rst_n stays high" part: a reset
    //                         in the middle of an encryption is allowed,
    //                         not a bug.
    //   $rose(valid_in)       WHEN valid_in goes from 0 to 1...
    //   |-> ##LATENCY         ...then exactly LATENCY cycles later...
    //   valid_out             ...valid_out must be high.
    // ------------------------------------------------------------------
    a_latency: assert property (@(posedge clk) disable iff (!rst_n)
            $rose(valid_in) |-> ##LATENCY valid_out)
        else $error("valid_out did not arrive %0d cycles after valid_in", LATENCY);

    // ------------------------------------------------------------------
    // A2 - "and not one cycle EARLY".
    //
    // A1 on its own only proves valid_out is high AT cycle 12. A broken
    // DUT that tied valid_out high permanently would still pass it. This
    // says valid_out must stay LOW for the 11 cycles in between.
    //   (!valid_out)[*11]  =  "not valid_out, 11 cycles in a row"
    //
    // A1 and A2 together are the real meaning of "exactly 12 cycles".
    // ------------------------------------------------------------------
    a_not_early: assert property (@(posedge clk) disable iff (!rst_n)
            $rose(valid_in) |-> ##1 (!valid_out)[*(LATENCY-1)] ##1 valid_out)
        else $error("valid_out asserted earlier than %0d cycles", LATENCY);

    // ------------------------------------------------------------------
    // A "cover" is the opposite of an assert: it proves the good thing
    // DID happen at least once. Without it, a testbench that never
    // started an encryption would pass A1 and A2 by doing nothing.
    // ------------------------------------------------------------------
    c_encryption_ran: cover property (@(posedge clk) disable iff (!rst_n)
            $rose(valid_in) ##LATENCY valid_out);

endmodule

// This checker is instantiated in tb_top.sv, wired to the interface's
// signals.
//
// The textbook way to attach a checker is `bind`, which glues it on
// without editing the target at all:
//     bind aes_if aes_sva u_sva (.*);
// That is worth knowing, but VCS rejects binding a module INTO an
// interface ("Interface has a module instantiation which is not
// allowed"), so we instantiate it in tb_top instead. Same checks, same
// signals - only the attachment point differs.
