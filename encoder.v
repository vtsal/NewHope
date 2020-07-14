`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/24/2020 05:57:19 PM
// Design Name: 
// Module Name: encoder
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


module encoder( // basic inputs
    input clk,
    input rst,
    // control inputs
    input start,
    output reg done,
    // Input RAM signals
    output [2:0] byte_addr,
    input [0:31] byte_do,
    // output RAM signals
    output reg poly_wea,
    output wire [8:0] poly_addra,
    output reg [15:0] poly_dia,
    output poly_web,
    output wire [8:0] poly_addrb,
    output [15:0] poly_dib);
    
    reg [15:0] NEWHOPE_HALF_Q = 16'd6144;
    
    localparam
        HOLD    = 3'd0,
        UPDATE    = 3'd1,
        LOAD    = 3'd2,
        STORE  = 3'd3;
    reg [2:0] state, state_next;
    reg [8:0] i;
    reg [2:0] j;
    wire [4:0] bit_select;
    
   // byte addr assigment
    assign byte_addr = i[4:2]; 
    assign poly_addra = (i << 3) | j; 
    assign poly_addrb = ((i << 3) | j) + 256;
    assign bit_select = {i[1:0], 3'd7 - j[2:0]};
    
    // a and b ports are paralell for we and di
    assign poly_dib = poly_dia;
    assign poly_web = poly_wea;
    
    // combinational state logic
    always @(*) begin
        state_next = state;
    
        case (state) 
        HOLD: begin
            state_next = (start == 1'b1) ? STORE : HOLD;
        end
        UPDATE: begin
            // update ctr variables
            state_next = (i[1:0] == 2'b11) ? LOAD : STORE;
        end
        LOAD: begin
            // let new word load from byte ram
            state_next = STORE;
        end
        STORE: begin
            // 1 cycle to store corresponding values, also check if complete
            state_next = (j == 7 & i == 31) ? HOLD : UPDATE;
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
        done <= 1'b0;
    
       // output ram (polynomial)
        poly_wea   <= 1'b0;
        poly_dia   <= 16'b0;
        
        if (rst == 1'b1) begin
            i <= 0;
            j <= 0;
        end else begin
            case (state) 
            HOLD: begin
                i <= 0;
                j <= 0;
            end
            UPDATE: begin
                // update i and j
                j <= (j < 7) ? j + 1 : 0;
                
                i <= (j < 7) ? i :
                     (i < 31 & j == 7) ? i + 1 : 0;
            end
            LOAD: begin
                // let BYTE RAM update
            end            
            STORE: begin
                // write value to output poly
                poly_dia <= (byte_do[bit_select] == 1'b1) ? NEWHOPE_HALF_Q : 16'd0; 
                poly_wea <= 1;
                
                j <= j;
                i <= i;
                done <= (i == 31 & j == 7) ? 1 : 0;
            end
            endcase
        end
    end

endmodule
