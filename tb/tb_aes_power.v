module tb_aes_power; // Renamed to distinguish
    reg clk, rst_n, start;
    reg [127:0] plaintext, key;
    wire [127:0] ciphertext;
    wire done;

    // Instantiate the DUT (This will now be the Netlist!)
    aes_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .plaintext(plaintext),
        .cipher_key(key),
        .ciphertext(ciphertext),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        // --- POWER ANALYSIS MAGIC ---
        $dumpfile("aes_power.vcd"); // The file we need for Step 4
        $dumpvars(0, tb_aes_power.dut); // Record all signals inside DUT
        // ----------------------------

        clk = 0; rst_n = 0; start = 0;
        key = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        plaintext = 128'h6bc1bee22e409f96e93d7e117393172a;

        #20 rst_n = 1;
        #20 start = 1;
        #10 start = 0;

        wait(done);
        $display("Ciphertext: %h", ciphertext);
        
        #50 $finish;
    end
endmodule