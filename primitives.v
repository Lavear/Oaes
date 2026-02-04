
// Yosys Simulation Primitives
module \$_AND_ (input A, B, output Y); assign Y = A & B; endmodule
module \$_OR_ (input A, B, output Y); assign Y = A | B; endmodule
module \$_XOR_ (input A, B, output Y); assign Y = A ^ B; endmodule
module \$_NOT_ (input A, output Y); assign Y = ~A; endmodule
module \$_NAND_ (input A, B, output Y); assign Y = ~(A & B); endmodule
module \$_NOR_ (input A, B, output Y); assign Y = ~(A | B); endmodule
module \$_XNOR_ (input A, B, output Y); assign Y = ~(A ^ B); endmodule
module \$_MUX_ (input A, B, S, output Y); assign Y = S ? B : A; endmodule

// D Flip-Flop (Positive Edge)
module \$_DFF_P_ (input D, C, output reg Q);
    always @(posedge C) Q <= D;
endmodule

// D Flip-Flop with Reset (Active Low) - Generic mapping
module \$_DFFE_PN0P_ (input D, C, E, R, output reg Q);
    always @(posedge C or negedge R) begin
        if (!R) Q <= 1'b0;
        else if (E) Q <= D;
    end
endmodule

