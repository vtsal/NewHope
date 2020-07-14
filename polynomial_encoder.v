`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/02/2020 05:09:42 PM
// Design Name: 
// Module Name: polynomial_encoder
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


module polynomial_encoder(
    // basic inputs
    input clk,
    input rst,
    // control inputs
    input start,
    output reg done,
    // byte RAM signals
    output reg byte_we,
    output reg [9:0] byte_addr,
    output reg [7:0] byte_di,
    // poly RAM signals
    output reg [8:0] poly_addra,
    input [15:0] poly_doa
    );
    
    localparam
        HOLD    = 4'd0,
        LOAD_S0 = 4'd1,
        LOAD_S1 = 4'd2,
        LOAD_S2_STORE_R0 = 4'd3,
        LOAD_S3_STORE_R1 = 4'd4,
        STORE_R2 = 4'd5,
        STORE_R3 = 4'd6,
        STORE_R4 = 4'd7,
        STORE_R5 = 4'd8,
        STORE_R6 = 4'd9,
        FINAL    = 4'd11;
    reg [3:0] state, state_next;

    reg [6:0] i;
    reg [13:0] t0, t1, t2, t3; // an corresponds to a_(i+n) in algorithmic description
    
    reg bar_en, bar_valid;
    wire bar_valid_out;
    wire [13:0] bar_result;
    
    barrett_reducer b_reducer (clk, rst, bar_en, poly_doa, bar_valid, bar_valid_out, bar_result);
    
    // combinational state logic
    always @(*) begin
        state_next = state;
    
        case (state) 
        HOLD: begin
            state_next = (start) ? LOAD_S0  : state_next;
        end
        LOAD_S0 : begin
            state_next = LOAD_S1 ;
        end
        LOAD_S1 : begin
            state_next = LOAD_S2_STORE_R0 ;
        end
        LOAD_S2_STORE_R0 : begin
            state_next = LOAD_S3_STORE_R1 ;
        end      
        LOAD_S3_STORE_R1 : begin
            state_next = STORE_R2 ;
        end 
        STORE_R2: begin
            state_next = STORE_R3 ;
        end
        STORE_R3 : begin
            state_next = STORE_R4 ;
        end
        STORE_R4 : begin
            state_next = STORE_R5 ;
        end
        STORE_R5 : begin
           state_next = STORE_R6  ;
        end
        STORE_R6  : begin
           state_next = (i == 127) ? FINAL : LOAD_S0;
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
        poly_addra <= poly_addra;
        i <= i;
        
        // poly ram defaults
        byte_we   <= 0;
        byte_addr <= byte_addr;
        byte_di   <= 0;
        
        // reducer control
        bar_valid <= 0;
        bar_en <= 0;
    
        if (rst == 1'b1) begin
            i <= 0;
        end else begin
            case (state) 
            HOLD: begin
                i <= 0;
                poly_addra <= 0;
                byte_addr  <= 0;
                if (start) begin
                    poly_addra <= 1;
                    bar_valid <= 1;
                    bar_en <= 1;
                end
            end
            LOAD_S0: begin
                poly_addra <= poly_addra + 1;
                bar_valid <= 1;
                bar_en <= 1;
               
            end
            LOAD_S1: begin
                poly_addra <= poly_addra + 1;
                bar_valid <= 1;
                bar_en <= 1;
                
                
            end
            LOAD_S2_STORE_R0: begin
                poly_addra <= poly_addra + 1;
                bar_en <= 1;

                // store output
                byte_di <= bar_result[7:0];
                byte_we <= 1;
                if (byte_addr != 0) begin
                    byte_addr <= byte_addr + 1;
                end

                // load out reducer
                t0 <= bar_result;
            end      
            LOAD_S3_STORE_R1: begin
                bar_en <= 1;

                // store output
                byte_di <= {bar_result[1:0], t0[13:8]};
                byte_we <= 1;
                byte_addr <= byte_addr + 1;

                // load out reducer
                t1 <= bar_result;
            end 
            STORE_R2: begin    
                bar_en <= 1;        

                // store output
                byte_di <= {t1[9:2]};
                byte_we <= 1;
                byte_addr <= byte_addr + 1;

                // load out reducer
                t2 <= bar_result;
            end
            STORE_R3 : begin
                // store output
                byte_di <= {t2[3:0], t1[13:10]};
                byte_we <= 1;
                byte_addr <= byte_addr + 1;
                
                // load out reducer
                t3 <= bar_result;
            end
            STORE_R4: begin
                // store output
                byte_di <= {t2[11:4]};
                byte_we <= 1;
                byte_addr <= byte_addr + 1;
            end
            STORE_R5: begin
                // store output
                byte_di <= {t3[5:0], t2[13:12]};
                byte_we <= 1;
                byte_addr <= byte_addr + 1;
            end
            STORE_R6: begin
                // store output
                byte_di <= {t3[13:6]};
                byte_we <= 1;
                byte_addr <= byte_addr + 1;  
                
                i <= (i < 127) ? i + 1 : 0;
                
                // start next load
                bar_valid <= 1;
                bar_en <= 1;
                poly_addra <= poly_addra + 1;
            end
            FINAL: begin
                done <= 1;
            end
            endcase
        end
    end
endmodule
