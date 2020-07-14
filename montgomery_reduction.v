`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Virginia Tech
// Engineer: Luke Beckwith
// 
// Create Date: 05/07/2019 09:23:33 PM
// Module Name: montgomery_reduction
// Project Name:  NTT
// Description:  Performs montgomery reduction of a 32-bit values
//  Expects start signal for 1 cycle to begin process. When finished done will
//  go high for 1 cycle and out will be set to ther reduced value. Reset is
//  synchronous
//////////////////////////////////////////////////////////////////////////////////

module montgomery_reduction(
    input clk,
    input load,
    input en,
    input reset,
    input [31:0] in,
    output [15:0] out,
    output valid
    );
   
    // reg used to store intermediate states
    reg [17:0] MULT_Q_stage_u = 0;
    reg [31:0]  MULT_Q_stage_in = 0;
    reg [31:0] out_reg = 0;
                
    reg [1:0] valid_sr = 0;
    
    assign out = {2'b00, out_reg[31:18]};
    assign valid = valid_sr[1];

    always @(posedge clk)  
    begin
        // synchronous reset 
        if (reset) begin           
            valid_sr <= 1'd0;
        end
        else if (en) begin
            // NOTE: These two calculations are inferred as DSPs
        
            // MULT_QINV calculation
            MULT_Q_stage_u <= (in * 14'd12287) & 18'd262143;
            MULT_Q_stage_in <= in;

            // MULT_Q calculation
            out_reg <= (MULT_Q_stage_u * 14'd12289) + MULT_Q_stage_in;
            
            valid_sr <= {valid_sr[0], load};
        end 
        
    end

endmodule
