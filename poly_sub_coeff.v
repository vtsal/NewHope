`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2020 12:24:17 PM
// Design Name: 
// Module Name: poly_sub_coeff
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

// combinational module, take one cycle.
module poly_sub_coeff(
  // basic control signals
  input clk,
  input en,
  // data signals
  input [15:0] dia,
  input [15:0] dib,
  output reg [15:0] red_out
  );
  
  localparam NEWHOPE_Q = 14'd12289;
  reg [15:0] dout;
    
  always @(posedge clk) begin
    if (en) begin
        dout    <= (dib > dia) ?  dia + NEWHOPE_Q - dib : dia - dib;
        red_out <= (dout > NEWHOPE_Q) ? dout - NEWHOPE_Q : dout;
    end
  end

endmodule