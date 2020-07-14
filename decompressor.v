`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/26/2020 10:17:28 AM
// Design Name: 
// Module Name: decompressor
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


module decompressor(
    // basic inputs
    input clk,
    input rst,
    // control inputs
    input start,
    output reg done,
    // Input RAM signals
    output reg [9:0] byte_addr,
    input [7:0] byte_do,
    // output RAM signals
    output reg poly_wea,
    output reg [8:0] poly_addra,
    output [15:0] poly_dia
    );
    
    localparam
        HOLD             = 4'd0,
        LOAD_A0_STORE_R7 = 4'd1,
        LOAD_A1_STORE_R0 = 4'd2,
        LOAD_A2_STORE_R1 = 4'd3,
        STORE_R2         = 4'd4,
        STORE_R3         = 4'd5,
        STORE_R4         = 4'd6,
        STORE_R5         = 4'd7,
        STORE_R6         = 4'd8,
        FINAL_STORE_R7   = 4'd9;
    reg [3:0] state = HOLD, state_next;
    
    reg [5:0] c = 0;
    wire [9:0] i = {c, 3'b000};
    reg [7:0] a0, a1, a2;
    
    // MUX for 8 possible outputs
    reg [2:0] out_select = 0;
    assign poly_dia = (out_select == 0) ? 16'h0000 :
                      (out_select == 1) ? 16'h0600 :
                      (out_select == 2) ? 16'h0c00 :
                      (out_select == 3) ? 16'h1200 :
                      (out_select == 4) ? 16'h1801 :
                      (out_select == 5) ? 16'h1e01 :
                      (out_select == 6) ? 16'h2401 :
                      (out_select == 7) ? 16'h2a01 : 16'h0000;
    
    // combinational state logic
    always @(*) begin
        state_next = state;
    
        case (state) 
        HOLD: begin
            state_next = (start) ? LOAD_A0_STORE_R7 : state_next;
        end
        LOAD_A0_STORE_R7: begin
            state_next = LOAD_A1_STORE_R0;
        end
        LOAD_A1_STORE_R0: begin
            state_next = LOAD_A2_STORE_R1;
        end
        LOAD_A2_STORE_R1: begin
            state_next = STORE_R2;
        end      
        STORE_R2: begin
            state_next = STORE_R3;
        end 
        STORE_R3: begin
            state_next = STORE_R4;
        end
        STORE_R4: begin
            state_next = STORE_R5;
        end
        STORE_R5: begin
           state_next = STORE_R6;
        end
        STORE_R6: begin
           state_next = (c == 63) ? FINAL_STORE_R7 : LOAD_A0_STORE_R7;
        end
        FINAL_STORE_R7 : begin
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
        byte_addr <= byte_addr;
        c <= c;
        
        // poly ram defaults
        poly_wea   <= 0;
        poly_addra <= poly_addra;
        out_select   <= 0;
    
        if (rst == 1'b1) begin
            c <= 0;
            byte_addr <= 0;
            poly_addra <= 0;
        end else begin
            case (state) 
            HOLD: begin
                if (start) begin
                    byte_addr <= byte_addr + 1;
                end
            end
            LOAD_A0_STORE_R7: begin
                a0 <= byte_do;
                byte_addr <= byte_addr + 1;
                
                if (i != 0) begin
                    poly_addra <= i - 1;
                    poly_wea <= 1;
                    out_select <= a2[7:5];
                end
            end
            LOAD_A1_STORE_R0: begin
                a1 <= byte_do;
                byte_addr <= byte_addr + 1;
                
                poly_addra <= i;
                poly_wea <= 1;
                out_select <= a0[2:0];
            end
            LOAD_A2_STORE_R1: begin
                a2 <= byte_do;
                
                poly_addra <= i + 1;
                poly_wea <= 1;
                out_select <= a0[5:3];
            end      
            STORE_R2: begin

                poly_addra <= i + 2;
                poly_wea <= 1;
                out_select <= {a1[0], a0[7:6]};
            end 
            STORE_R3: begin

                poly_addra <= i + 3;
                poly_wea <= 1;
                out_select <= a1[3:1];
            end
            STORE_R4: begin

                poly_addra <= i + 4;
                poly_wea <= 1;
                out_select <= a1[6:4];
            end
            STORE_R5: begin
            
                poly_addra <= i + 5;
                poly_wea <= 1;
                out_select <= {a2[1:0], a1[7]};
            end
            STORE_R6: begin
                byte_addr <= byte_addr + 1;
            
                poly_addra <= i + 6;
                poly_wea <= 1;
                out_select <= a2[4:2];
                c <= (c == 63) ? 0 : c + 1;
            end
            FINAL_STORE_R7 : begin
                poly_addra <= 511;
                poly_wea <= 1;
                out_select <= a2[7:5];
                
                done <= 1;
            end
            endcase
        end
    end
    
endmodule
