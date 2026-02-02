module mixcolumns(
    input [127:0]in_state,
    output [127:0]out_state
);

function [7:0]xtime;
input [7:0]b;
begin
    xtime = (b[7] == 1'b0)? (b<<1) : ((b<<1)^8'h1b);
end
endfunction

genvar i;
generate
    for(i=0; i<4; i=i+1) begin : MC 

    wire [7:0]s0 = in_state[127 - i*32 -: 8];
    wire [7:0]s1 = in_state[119 - i*32 -: 8];
    wire [7:0]s2 = in_state[111 - i*32 -: 8];
    wire [7:0]s3 = in_state[103 - i*32 -: 8];

    wire [7:0]m0 = xtime(s0) ^ (xtime(s1)^s1) ^ s2 ^ s3;
    wire [7:0]m1 = s0 ^ xtime(s1) ^ (xtime(s2) ^ s2) ^ s3;
    wire [7:0]m2 = s0 ^ s1 ^ xtime(s2) ^ (xtime(s3) ^ s3);
    wire [7:0]m3 = (xtime(s0) ^ s0) ^ s1 ^ s2 ^ xtime(s3);

    assign out_state[127 - i*32 -: 8] = m0;
    assign out_state[119 - i*32 -: 8] = m1;
    assign out_state[111 - i*32 -: 8] = m2;
    assign out_state[103 - i*32 -: 8] = m3;

    end
endgenerate
endmodule