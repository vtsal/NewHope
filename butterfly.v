`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Virginia Tech
// Engineer: Luke Beckwith
// 
// Create Date: 05/08/2019 05:46:15 PM
// Module Name: butterfly
// Description: wrapper for ntt_motgomery_module and ntt_adder
//////////////////////////////////////////////////////////////////////////////////


module butterfly(
    input clk,
    input reset,
    input [15:0] ina,
    input [15:0] inb,
    input [15:0] omega,
    input in_valid,
    input en,
    output [15:0] outa,
    output [15:0] outb,
    output valid
    );
    
    wire mont_valid;
    wire [15:0] adder_out, mont_out;
    
    assign valid = mont_valid;
    assign outb = mont_out;
    
    ntt_montgomery_module mont_mod(clk, in_valid, en, reset, ina, inb, omega, mont_out, mont_valid);
    
    ntt_adder add_mod(clk, en, reset, 1'b0, ina, inb, adder_out);
    
    // buffer add_mod output by 2 cycles and the outputs to butterfly
    shift_register_bf #(.LENGTH(5)) adder_buffer (clk, en, adder_out, outa);
    
endmodule