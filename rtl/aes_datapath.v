module aes_datapath(
    input [127:0]state_in,
    input [127:0]round_key,
    input final_round,
    output [127:0]state_out
);

wire [127:0]subbytes_out;
wire [127:0]shiftrows_out;
wire [127:0]mixcolumns_out;
wire [127:0]addroundkey_in;

subbytes u_subbytes(
    .in_state(state_in),
    .out_state(subbytes_out)
);

shiftrows u_shiftrows(
    .in_state(subbytes_out),
    .out_state(shiftrows_out)
);

mixcolumns u_mixcolumns(
    .in_state(shiftrows_out),
    .out_state(mixcolumns_out)
);

assign addroundkey_in = final_round ? shiftrows_out : mixcolumns_out;

addroundkey u_addroundkey(
    .in_state(addroundkey_in),
    .round_key(round_key),
    .out_state(state_out)
);

endmodule