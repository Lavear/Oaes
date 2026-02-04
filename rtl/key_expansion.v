module key_expansion (
    input         clk,
    input         rst_n,
    input         en,
    input  [3:0]  round,
    input  [127:0] cipher_key,
    output [127:0] round_key
);
    reg [127:0] key_reg;

    // Select source: Round 0 uses CipherKey, others use Register
    wire [127:0] prev_key;
    assign prev_key = (round == 0) ? cipher_key : key_reg;

    wire [31:0] w0, w1, w2, w3;
    assign w0 = prev_key[127:96];
    assign w1 = prev_key[95:64];
    assign w2 = prev_key[63:32];
    assign w3 = prev_key[31:0];

    // g-function
    wire [31:0] rotword;
    assign rotword = {w3[23:0], w3[31:24]};

    wire [31:0] subword;
    wire [7:0] sb0, sb1, sb2, sb3;
    aes_sbox u_s0(.in_byte(rotword[31:24]), .out_byte(sb0));
    aes_sbox u_s1(.in_byte(rotword[23:16]), .out_byte(sb1));
    aes_sbox u_s2(.in_byte(rotword[15:8 ]), .out_byte(sb2));
    aes_sbox u_s3(.in_byte(rotword[7 :0 ]), .out_byte(sb3));
    assign subword = {sb0, sb1, sb2, sb3};

    // --- FIXED: Rcon Lookup Table (Replaces the broken loop) ---
    function [7:0] get_rcon;
        input [3:0] r;
        case(r)
            0: get_rcon = 8'h01; 1: get_rcon = 8'h02; 2: get_rcon = 8'h04;
            3: get_rcon = 8'h08; 4: get_rcon = 8'h10; 5: get_rcon = 8'h20;
            6: get_rcon = 8'h40; 7: get_rcon = 8'h80; 8: get_rcon = 8'h1b;
            9: get_rcon = 8'h36; default: get_rcon = 8'h00;
        endcase
    endfunction

    wire [31:0] rcon_word;
    assign rcon_word = {get_rcon(round), 24'h0};

    wire [31:0] g_out;
    assign g_out = subword ^ rcon_word;

    // XOR Chain
    wire [31:0] w4, w5, w6, w7;
    assign w4 = w0 ^ g_out;
    assign w5 = w1 ^ w4;
    assign w6 = w2 ^ w5;
    assign w7 = w3 ^ w6;

    wire [127:0] next_key;
    assign next_key = {w4, w5, w6, w7};

    assign round_key = key_reg; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            key_reg <= 128'b0;
        else if (en) 
            key_reg <= next_key;
    end
endmodule
