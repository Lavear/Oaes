module aes_controller(
    input clk, 
    input rst_n,
    input start,
    output reg state_en,
    output reg final_round,
    output reg done,
    output reg [3:0]round
);
endmodule