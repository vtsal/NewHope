`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2020 12:24:17 PM
// Design Name: 
// Module Name: poly_mult_coeff
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

// sequential module, takes multiple clock cycles
module poly_mult_coeff(
  // basic control signals
  input clk,
  input en,
  input precomp,
  // data signals
  input [15:0] doa,
  input [15:0] dob,
  output [15:0] dout
  );
 
  // montgomery reduction module
  reg mont_start;
  reg [31:0] reduce_t_in, reduce_r_in;
  wire [15:0] reduce_t_out, reduce_r_out, doa_delay;
  wire outvalid1, outvalid2;
  
  montgomery_reduction REDUCE_T (clk, 1'b0, en, 1'b0, reduce_t_in, reduce_t_out, outvalid1);
  montgomery_reduction REDUCE_R (clk, 1'b0, en, 1'b0, reduce_r_in, reduce_r_out, outvalid2);

  shift_register_bf #(.LENGTH(3)) SR (clk, ~precomp, doa, doa_delay);

  assign dout = reduce_r_out;

  // pipeline logic 
  always @(posedge clk) begin
    if (precomp) begin
        reduce_r_in <= doa*dob;
    end else begin
        reduce_t_in <= 13'd3186*dob;
        reduce_r_in <= doa_delay*reduce_t_out;
    end
  end

endmodule