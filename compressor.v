`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/10/2020 11:56:14 AM
// Design Name: 
// Module Name: compressor
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


module compressor(
    // basic inputs
    input clk,
    input rst,
    // control inputs
    input start,
    output reg done,
    // Input RAM signals
    output reg [7:0] byte_addr,
    output reg [7:0] byte_di,
    output reg byte_we,
    // output RAM signals
    output [8:0] poly_addra,
    input [15:0] poly_doa
    );
    
    localparam
        HOLD              = 4'd0,
        LOAD_T0_STORE_H3  = 4'd1,
        LOAD_T1           = 4'd2,
        LOAD_T2           = 4'd3,
        LOAD_T3_STORE_H0 = 4'd4,
        LOAD_T4          = 4'd5,
        LOAD_T5          = 4'd6,
        LOAD_T6_STORE_H1 = 4'd7,
        LOAD_T7          = 4'd8,
        FINAL_STORE_H3    = 4'd9;
    reg [3:0] state, state_next;    
    
    reg [6:0] L;
    reg [2:0] j;
    assign poly_addra = {L[5:0], j};
    
    reg [2:0] t0, t1, t2, t3, t4, t5, t6, t7;
    
    // LUT for calculation (((t_j << 3) + q/2)/q) & 7
    wire [2:0] map_out;
    assign map_out = (poly_doa < 16'd769) ? 3'd0 :
                        (poly_doa < 16'd2305) ? 3'd1 :
                        (poly_doa < 16'd3841) ? 3'd2 :
                        (poly_doa < 16'd5377) ? 3'd3 :
                        (poly_doa < 16'd6913) ? 3'd4 :
                        (poly_doa < 16'd8449) ? 3'd5 :
                        (poly_doa < 16'd9985) ? 3'd6 :
                        (poly_doa < 16'd11521) ? 3'd7 : 0;
    
    // combinational state logic
    always @(*) begin
        state_next = state;
    
        case (state) 
        HOLD: begin
            state_next = (start) ? LOAD_T0_STORE_H3 : HOLD;
        end
        LOAD_T0_STORE_H3: begin
            state_next = LOAD_T1;
        end
        LOAD_T1: begin
            state_next = LOAD_T2;
        end
        LOAD_T2: begin
            state_next = LOAD_T3_STORE_H0;
        end      
        LOAD_T3_STORE_H0: begin
            state_next = LOAD_T4;
        end 
        LOAD_T4: begin
            state_next = LOAD_T5;
        end
        LOAD_T5: begin
            state_next = LOAD_T6_STORE_H1;
        end
        LOAD_T6_STORE_H1: begin
           state_next = LOAD_T7;
        end
        LOAD_T7: begin
           state_next = (L == 64) ? FINAL_STORE_H3 : LOAD_T0_STORE_H3;
        end
         FINAL_STORE_H3: begin
            state_next = HOLD;
        end
        endcase
    end
    
    // sequential state logic
    always @(posedge clk) begin
        state <= (rst) ? HOLD : state_next;
    end
    
    always @(posedge clk) begin
        // defaults
        done <= 1'b0;
        L <= L;
        j <= j;
        
        // ram defaults
        byte_we   <= 0;
        byte_addr <= byte_addr;
        byte_di   <= 0;
    
        if (rst == 1'b1) begin
            L <= 0;
            j <= 0;
            byte_we <= 0;
            byte_addr <= 0;
        end else begin
            case (state) 
            HOLD: begin
                byte_addr <= 0;
                if (start) begin
                    j <= j + 1;
                end                
            end
            LOAD_T0_STORE_H3: begin
                // load in poly values
                t0 <= map_out;
                j <= j + 1;
                
                if (L != 0) begin
                    // if its not the first round, store H7
                    byte_di <= {t7, t6, t5[2:1]};
                    byte_we <= 1;
                    byte_addr <= byte_addr + 1;
                end
            end
            LOAD_T1: begin
                // load in poly values
                t1 <= map_out;
                j <= j + 1;
            end
            LOAD_T2: begin
                // load in poly values
                t2 <= map_out;
                j <= j + 1;
            end      
            LOAD_T3_STORE_H0: begin
                // load in poly values
                t3 <= map_out;
                j <= j + 1;
                
                // store val
                byte_di <= {t2[1:0], t1, t0};
                byte_we <= 1;
                byte_addr <= (L == 0) ? byte_addr : byte_addr + 1;
            end 
            LOAD_T4: begin
                // load in poly values
                t4 <= map_out;
                j <= j + 1;
            end
            LOAD_T5: begin
                // load in poly values
                t5 <= map_out;
                j <= j + 1;
            end
            LOAD_T6_STORE_H1: begin
                // load in poly values
                t6 <= map_out;
                j <= j + 1;
                L <= L + 1;
                
                // store val
                byte_di <= {t5[0], t4, t3, t2[2]};
                byte_we <= 1;
                byte_addr <= byte_addr + 1;
            end
            LOAD_T7: begin
                // load in poly values
                t7 <= map_out;
                j <= j + 1;
            end
            FINAL_STORE_H3: begin
                byte_di <= {t7, t6, t5[2:1]};
                byte_we <= 1;
                byte_addr <= byte_addr + 1;
                
                done <= 1;
            end
            endcase
        end
    end
    
    
endmodule
