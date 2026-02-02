module key_expansion (
    input         clk,
    input         rst_n,
    input         en,
    input  [3:0]  round,
    input  [127:0] cipher_key,
    output [127:0] round_key
);
    reg [127:0] key_reg;

    // Select the source for the current round's calculation
    // If Round 0: We are calculating Key 1 from CipherKey.
    // If Round > 0: We are calculating Key N+1 from Key N (stored in reg).
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

    reg [7:0] rcon;
    integer i;
    always @(*) begin
        // The Rcon index depends on the round number being generated
        // We are generating Key for Round (round + 1)
        rcon = 8'h01;
        for (i = 0; i < round; i = i + 1) begin
             // If round=0, we want Rcon(1). Loop runs 0 times? No.
             // Standard: Rcon[1]=01, Rcon[2]=02...
             // If input 'round' is 0, we are generating Key 1. Need Rcon(1).
             rcon = (rcon[7] == 1'b0) ? (rcon << 1) : ((rcon << 1) ^ 8'h1b);
        end
        // Correcting Rcon Logic:
        // Round 0 (generating Key 1) -> use Rcon(1) = 01
        // Round 1 (generating Key 2) -> use Rcon(2) = 02
        if (round == 0) rcon = 8'h01; 
    end
    
    // Actually, simpler Rcon lookup table for robustness:
    function [7:0] get_rcon;
        input [3:0] r;
        case(r)
            0: get_rcon = 8'h01; // Generating Key 1
            1: get_rcon = 8'h02;
            2: get_rcon = 8'h04;
            3: get_rcon = 8'h08;
            4: get_rcon = 8'h10;
            5: get_rcon = 8'h20;
            6: get_rcon = 8'h40;
            7: get_rcon = 8'h80;
            8: get_rcon = 8'h1b;
            9: get_rcon = 8'h36;
            default: get_rcon = 8'h00;
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

    // Output: 
    // During Round 1, we need Key 1.
    // 'key_reg' holds Key 1.
    // During Round 0, we output Cipher Key? No, aes_top handles Round 0 directly.
    // But aes_datapath needs "round_key".
    // If round == 1, output key_reg.
    assign round_key = key_reg; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            key_reg <= 128'b0;
        else if (en) begin
            key_reg <= next_key;
        end
    end
endmodule