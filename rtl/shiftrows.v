module shiftrows(
    input [127:0]in_state,
    output [127:0]out_state
);

assign out_state[127:120] = in_state[127:120];
assign out_state[95:88]   = in_state[95:88];
assign out_state[63:56]   = in_state[63:56];
assign out_state[31:24]   = in_state[31:24];

assign out_state[119:112] = in_state[87:80];
assign out_state[87:80]   = in_state[55:48];   
assign out_state[55:48]   = in_state[23:16];  
assign out_state[23:16]   = in_state[119:112];

assign out_state[111:104] = in_state[47:40];
assign out_state[79:72]   = in_state[15:8];
assign out_state[47:40]   = in_state[111:104];
assign out_state[15:8]    = in_state[79:72];

assign out_state[103:96] = in_state[7:0];
assign out_state[71:64]   = in_state[103:96];
assign out_state[39:32]   = in_state[71:64];
assign out_state[7:0]     = in_state[39:32];

endmodule