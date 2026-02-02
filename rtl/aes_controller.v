//======================================================
// File: aes_controller.v
// Description:
// FSM to control AES rounds (1 to 10).
// FIXED: Loop counting and Final Round flag timing.
//======================================================
module aes_controller (
    input        clk,
    input        rst_n,
    input        start,
    output reg [3:0] round,
    output reg   state_en,
    output reg   final_round,
    output reg   done
);

    // State Encoding
    localparam IDLE   = 2'b00;
    localparam INIT   = 2'b01;
    localparam ROUND  = 2'b10;
    localparam FINISH = 2'b11;

    reg [1:0] state, next_state;

    // State Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    // Round Counter Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            round <= 4'd0;
        else begin
            if (state == INIT)
                round <= 4'd1;          // Prepare Round 1
            else if (state == ROUND && round < 4'd10)
                round <= round + 1'b1;  // Increment
            else if (state == IDLE)
                round <= 4'd0;
        end
    end

    // FSM Combinational Logic
    always @(*) begin
        // Defaults
        next_state  = state;
        state_en    = 1'b0;
        final_round = 1'b0;
        done        = 1'b0;

        case (state)
            IDLE: begin
                if (start) next_state = INIT;
            end

            INIT: begin
                // In this state, we load Initial State (Round 0) into the register
                // and prepare to move to Round 1.
                state_en   = 1'b1;
                next_state = ROUND;
            end

            ROUND: begin
                state_en = 1'b1;
                
                // If we are currently processing Round 10:
                if (round == 4'd10) begin
                    final_round = 1'b1;   // Tell Datapath to skip MixCols
                    next_state  = FINISH; // Done after this clock
                end
            end

            FINISH: begin
                done = 1'b1;
                // Optional: Wait for handshake or go to IDLE
                next_state = IDLE;
            end
        endcase
    end

endmodule