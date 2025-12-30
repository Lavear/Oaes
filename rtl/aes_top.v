module aes_top(
    input clk, 
    input rst_n,
    input start,
    input [127:0]plaintext,
    input [127:0]key,
    output [127:0]ciphertext,
    output done
);
endmodule