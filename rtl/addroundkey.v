module addroundkey(
    input [127:0]in_state,
    input [127:0]round_key,
    output [127:0]out_state
);
assign out_state = in_state ^ round_key;
endmodule