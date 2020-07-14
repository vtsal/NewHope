`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/25/2020 11:18:28 PM
// Design Name: 
// Module Name: polynomial_decoder
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


module polynomial_decoder(
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
        HOLD    = 4'd0,
        LOAD_A0 = 4'd1,
        LOAD_A1 = 4'd2,
        LOAD_A2 = 4'd3,
        LOAD_A3 = 4'd4,
        LOAD_A4 = 4'd5,
        LOAD_A5 = 4'd6,
        LOAD_A6 = 4'd7,
        FINAL   = 4'd8;
    reg [3:0] state = HOLD, state_next;

    reg [6:0] i = 0;
    reg [7:0] a0, a1, a2, a3, a4, a5, a6; // an corresponds to a_(i+n) in algorithmic description
    
    reg [15:0] poly_out;
    assign poly_dia = poly_out;
    
     // combinational state logic
    always @(*) begin
        state_next = state;
    
        case (state) 
        HOLD: begin
            state_next = (start) ? LOAD_A0 : state_next;
        end
        LOAD_A0: begin
            state_next = LOAD_A1;
        end
        LOAD_A1: begin
            state_next = LOAD_A2;
        end
        LOAD_A2: begin
            state_next = LOAD_A3;
        end      
        LOAD_A3: begin
            state_next = LOAD_A4;
        end 
        LOAD_A4: begin
            state_next = LOAD_A5;
        end
        LOAD_A5: begin
            state_next = LOAD_A6;
        end
        LOAD_A6: begin
           state_next = (i == 127) ? FINAL : LOAD_A0;
        end
        FINAL : begin
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
        byte_addr <= 0;
        i <= i;
        
        // poly ram defaults
        poly_wea   <= 0;
        poly_addra <= 0;
        poly_out   <= 0;
    
        if (rst == 1'b1) begin
            i <= 0;
        end else begin
            case (state) 
            HOLD: begin
                i <= 0;
                if (start) begin
                    byte_addr <= byte_addr + 1;
                end
            end
            LOAD_A0: begin
                a0 <= byte_do;
                byte_addr <= byte_addr + 1; 
                
                // store r_(4i+3) from last round
                if (i != 0) begin
                    poly_addra <= ((i-1) << 2) | 3;
                    poly_wea <= 1;
                    poly_out <= {2'b00, a6, a5[7:2]};
                end
            end
            LOAD_A1: begin
                a1 <= byte_do;
                byte_addr <= byte_addr + 1; 
            end
            LOAD_A2: begin
                a2 <= byte_do;
                byte_addr <= byte_addr + 1; 
                
                // store r_(4i)
                poly_addra <= (i << 2);
                poly_wea <= 1;
                poly_out <= {2'b00, a1[5:0], a0};
            end      
            LOAD_A3: begin
                a3 <= byte_do;
                byte_addr <= byte_addr + 1; 
            end 
            LOAD_A4: begin
                a4 <= byte_do;
                byte_addr <= byte_addr + 1; 
                
                // store r_(4i+1)
                poly_addra <= (i << 2) | 1;
                poly_wea <= 1;
                poly_out <= {2'b00, a3[3:0], a2, a1[7:6]};
            end
            LOAD_A5: begin
                a5 <= byte_do;
                byte_addr <= byte_addr + 1; 
            end
            LOAD_A6: begin
                a6 <= byte_do;
                byte_addr <= byte_addr + 1;
                i <= (i < 127) ? i + 1 : 0; 
                
                // store r_(4i+2)
                poly_addra <= (i << 2) | 2;
                poly_wea <= 1;
                poly_out <= {2'b00, a5[1:0], a4, a3[7:4]};
            end
            FINAL: begin
                done <= 1;
            
                // store r_(4i+3) from final round
                poly_addra <= (127 << 2) | 3;
                poly_wea <= 1;
                poly_out <= {2'b00, a6, a5[7:2]};
            end
            endcase
        end
    end
    
endmodule
