`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/03/2020 09:41:42 AM
// Design Name: 
// Module Name: seed_mover
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module seed_mover(
    // basic inputs
    input clk,
    input rst,
    // control inputs
    input start,
    output reg done = 0,
    // input RAM signals
    output reg [2:0] IR_addr = 0,
    input [31:0] IR_do,
    // output RAM signals
    output reg [4:0] OR_addr = 0,
    output reg [7:0] OR_di,
    output reg OR_we
    );
    
    localparam
        HOLD  = 2'd0,
        LOAD  = 2'd1,
        STORE = 2'd2;
    reg [2:0] state, state_next;
    
    reg [1:0] ctr;
    
        // combinational state logic
    always @(*) begin
        state_next = state;
    
        case (state) 
        HOLD: begin
            state_next = (start == 1'b1) ? STORE : HOLD;
        end
        LOAD: begin
            state_next = STORE;
        end
        STORE: begin
            state_next = (OR_addr == 31) ? HOLD
                            : (ctr == 2'b11) ? LOAD : STORE;
        end      
        endcase
    end
    
    // sequential state logic
    always @(posedge clk) begin
        state <= (rst) ? HOLD : state_next;
    end
    
    // sequential output logic
    always @(posedge clk) begin
        // defaults
        done    <= 1'b0;
        ctr     <= 0;
        
        // input RAM signals
        IR_addr <= 0;
        // output RAM signals
        OR_di <= 0;
        OR_we <= 0;
        
        if (rst == 1'b1) begin
            OR_addr <= 0;
            IR_addr <= 0;
        end else begin
            case (state) 
            HOLD: begin
                if (start) begin
                    OR_addr <= 0;
                    IR_addr <= 0;
                end
            end
            LOAD: begin
                IR_addr <= IR_addr;
            end
            STORE: begin
                IR_addr <= IR_addr;
                
                ctr <= ctr + 1;
                OR_we <= 1'b1;
                OR_di <= IR_do[8*ctr+:8];
                OR_addr <= {IR_addr, ctr};
                
                if (ctr == 2'b11)
                    IR_addr <= IR_addr + 1;
                
                if (OR_addr == 31)
                    done <= 1'd1;
            end        
            endcase
        end
    end
    
    
endmodule
