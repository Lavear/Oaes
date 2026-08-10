//======================================================================
// aes_if.sv  -  the wires between the testbench and the DUT.
//
// UVM code lives in classes, and classes cannot touch module pins
// directly. So we bundle the pins into an "interface", and hand the
// classes a handle to it. That handle is the only way the driver and
// monitor reach your hardware.
//======================================================================

interface aes_if (input logic clk, input logic rst_n);

    // The DUT pins, using the names from the spec. tb_top.sv connects
    // these to your RTL's actual port names (start, plaintext, ...).
    logic         valid_in;
    logic [127:0] plain_text;
    logic [127:0] key;
    logic         valid_out;
    logic [127:0] cipher_text;

    // ------------------------------------------------------------------
    // Clocking blocks exist to stop the testbench and the DUT from
    // fighting over the same clock edge ("a race").
    //   input  #1step -> read signals as they were JUST BEFORE the edge,
    //                    which is exactly what the RTL's flip-flops see.
    //   output #1ns   -> drive signals 1ns AFTER the edge, so on a
    //                    waveform you can clearly see cause and effect.
    // The driver uses drv_cb; the monitor uses mon_cb (all inputs,
    // because a monitor only ever watches).
    // ------------------------------------------------------------------
    clocking drv_cb @(posedge clk);
        default input #1step output #1ns;
        output valid_in, plain_text, key;
        input  valid_out, cipher_text;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input valid_in, plain_text, key, valid_out, cipher_text;
    endclocking

endinterface
