
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