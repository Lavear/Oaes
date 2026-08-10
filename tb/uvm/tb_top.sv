//======================================================================
// tb_top.sv  -  the only module in the testbench.
//
// Clock, reset, the DUT, the interface, and the call that starts UVM.
// Everything else is classes inside aes_pkg.
//======================================================================

`timescale 1ns/1ps

module tb_top;

    import uvm_pkg::*;
    import aes_pkg::*;
    `include "uvm_macros.svh"

    logic clk;
    logic rst_n;

    // 100 MHz clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset: assert at time 0, release after 5 clocks.
    initial begin
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n <= 1;
    end

    // The interface carries the pins.
    aes_if vif (.clk(clk), .rst_n(rst_n));

    // The SVA checker from aes_assertions.sv, watching the same signals.
    aes_sva u_sva (
        .clk      (clk),
        .rst_n    (rst_n),
        .valid_in (vif.valid_in),
        .valid_out(vif.valid_out)
    );

    // ------------------------------------------------------------------
    // Your RTL, connected directly. The interface uses the spec's names
    // (valid_in / plain_text / ...) and aes_top uses its own names
    // (start / plaintext / ...), so we translate right here - no wrapper
    // file needed, and your RTL is untouched.
    // ------------------------------------------------------------------
    aes_top dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (vif.valid_in),
        .plaintext  (vif.plain_text),
        .cipher_key (vif.key),
        .ciphertext (vif.cipher_text),
        .done       (vif.valid_out)
    );

    initial begin
        // Hand the interface to the class world. The driver and monitor
        // fetch it with a matching ::get() call. This is THE handshake
        // that connects UVM to your hardware.
        uvm_config_db#(virtual aes_if)::set(null, "*", "vif", vif);

        // Safety net: if the testbench ever deadlocks, stop loudly.
        uvm_top.set_timeout(10ms, 0);

        // Starts everything. Reads +UVM_TESTNAME from the command line,
        // falling back to aes_test.
        run_test("aes_test");
    end

    // Optional waveform dump:  vsim ... +DUMP_WAVES
    initial begin
        if ($test$plusargs("DUMP_WAVES")) begin
            $dumpfile("aes_uvm.vcd");
            $dumpvars(0, tb_top);
        end
    end

endmodule
