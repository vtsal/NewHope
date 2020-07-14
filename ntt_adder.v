`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Virginia Tech
// Engineer: Luke Beckwith
// 
// Create Date: 05/08/2019 02:24:04 PM
// Module Name: ntt_adder
// Project Name: NTT 
// Description: Performs addition with or without reduction  based on 'lazy'
//  Expects start signal for 1 cycle to begin process. When finished done will
//  go high for 1 cycle and out will be set to ther reduced value. Reset is
//  synchronous
//////////////////////////////////////////////////////////////////////////////////


module ntt_adder(
    input clk,
    input en,
    input reset,
    input lazy,
    input [15:0] a,
    input [15:0] a_pair,
    output [15:0] b
);

    // pipeline registers
    reg [15:0] REDUCE_a = 0, OUT_a = 0;
    reg REDUCE_lazy = 0;
    
    assign b = OUT_a;
    
    always @(posedge clk)  
    begin
        // synchronous reset 
        if (reset) begin
            OUT_a <= 16'b0;
        end
        else if (en) begin
            // ADDITION calculation
            REDUCE_a <= a + a_pair;
            REDUCE_lazy <= lazy;
            
            // REDUCTION calculation (if not lazy)
            OUT_a <= (~REDUCE_lazy & REDUCE_a >= 15'd24578) ? REDUCE_a - 15'd24578 : 
                     (~REDUCE_lazy & REDUCE_a >= 14'd12289) ? REDUCE_a - 14'd12289 : REDUCE_a;            
        end
    end

endmodule
