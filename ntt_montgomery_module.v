`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Virginia Tech
// Engineer: Luke Beckwith
// 
// Create Date: 05/07/2019 10:37:11 PM
// Module Name: ntt_montgomery_module
// Project Name:  NTT
// Description: calculates the second butterfly calculation red(W* (a - 3q - a_d))
//  Expects start signal for 1 cycle to begin process. When finished done will
//  go high for 1 cycle and out will be set to ther reduced value. Reset is
//  synchronous
//////////////////////////////////////////////////////////////////////////////////

module ntt_montgomery_module(
    input clk,
    input load,
    input en,
    input reset,
    input [15:0] a,
    input [15:0] a_pair,
    input [15:0] omega,
    output [15:0] b_pair,
    output valid
    );

    // pipeline registers
    reg [17:0] SUB_a = 0, MULT_a2 = 0;
    wire [36:0] REDUCE_a;
    reg [15:0] SUB_a_pair = 0, omega_preadder_delay = 0, SUB_omega = 0;
    //**Note for above: the DSP slice does not have a register to delay
    // the mult value so it must be done manually
    
    reg [4:0] load_sr = 0;
        
    // instance of pipelined reduction module
    montgomery_reduction reducer(clk, load_sr[4], en, reset, REDUCE_a[31:0], b_pair, valid);
    
    // DSP instance for max efficieny
    dynpreaddmultadd #(.SIZEIN(18)) DSP0 (
        clk, 1'd1, reset, 1'd1,
        SUB_a, {2'd0, SUB_a_pair}, {2'd0, SUB_omega}, 18'd0,
        REDUCE_a
    );
    
    always @(posedge clk)  
    begin
        // synchronous reset 
        if (reset) begin
            load_sr <= 5'd0;
        end
        else if (en) begin
            // ADD_3Q calculation
            SUB_a <= a + 16'd24578; //14'd12289;// <- 1 LUT smaller
            SUB_a_pair <= a_pair;
            
            omega_preadder_delay <= omega;
            SUB_omega <= omega_preadder_delay;
        
            load_sr <= {load_sr[3:0], load};           
        
            /*
             * pipelined calculation continues in montgomery_reduction
             */
           
        end 
    end
    
endmodule
