`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/17/2020 12:24:17 PM
// Design Name: 
// Module Name: poly_add_coeff
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
module poly_add_coeff(
  // basic control signals
  input clk,
  input en,
  // data signals
  input [15:0] dia,
  input [15:0] dib,
  output reg [15:0] dout
  );
  localparam NEWHOPE_Q = 14'd12289, NEWHOPE_2Q = 15'd24578;
  reg [15:0] sum;
  
  always @(posedge clk) begin
    if (en) begin
        sum <= dia + dib;
        
        dout <= (sum >= NEWHOPE_2Q) ? sum - NEWHOPE_2Q :
                    (sum >= NEWHOPE_Q) ? sum - NEWHOPE_Q : sum;
    end
  end

endmodule
