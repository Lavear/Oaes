`timescale 1ns/1ps

module tb_aes_top;

    // ---------------------------------
    // Testbench signals
    // ---------------------------------
    reg         clk;
    reg         rst_n;
    reg         start;
    reg [127:0] plaintext;
    reg [127:0] cipher_key;

    wire [127:0] ciphertext;
    wire         done;

    // ---------------------------------
    // Instantiate AES top module
    // ---------------------------------
    aes_top dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .plaintext  (plaintext),
        .cipher_key(cipher_key),
        .ciphertext (ciphertext),
        .done       (done)
    );

    // ---------------------------------
    // Clock generation (100 MHz)
    // ---------------------------------
    always #5 clk = ~clk;

    // ---------------------------------
    // Test sequence
    // ---------------------------------
    initial begin
        // Initialize signals
        clk       = 0;
        rst_n     = 0;
        start     = 0;
        plaintext = 128'b0;
        cipher_key = 128'b0;

        // Apply reset
        #20;
        rst_n = 1;

        // Apply test vector
        plaintext  = 128'h00112233445566778899aabbccddeeff;
        cipher_key = 128'h000102030405060708090a0b0c0d0e0f;

        // Start AES
        #10;
        start = 1;
        #10;
        start = 0;

        // Wait for encryption to complete
        wait (done);

        // Display result
        $display("Ciphertext = %h", ciphertext);

        // Check result
        if (ciphertext == 128'h69c4e0d86a7b0430d8cdb78070b4c55a)
            $display("✅ AES encryption PASSED");
        else
            $display("❌ AES encryption FAILED");

        #20;
        $finish;
    end

    // ---------------------------------
    // Dump waveform (for debugging/power)
    // ---------------------------------
    initial begin
        $dumpfile("aes.vcd");
        $dumpvars(0, tb_aes_top);
    end

endmodule
