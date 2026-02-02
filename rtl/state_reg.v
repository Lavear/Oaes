//======================================================
// File: state_reg.v
// Description:
// 128-bit AES state register.
// Stores the AES state between rounds.
//======================================================

module state_reg (
    input         clk,        // system clock
    input         rst_n,      // active-low reset
    input         en,         // enable (load new state)
    input  [127:0] d,         // next state (from datapath)
    output reg [127:0] q      // current state
);

    // Sequential logic: update state on clock edge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 128'b0;      // reset state to zero
        else if (en)
            q <= d;           // load next state
        // else: hold previous state
    end

endmodule
