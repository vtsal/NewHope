`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/08/2019 03:18:03 PM
// Module Name: input_ram
// Description: Vivado BRAM block. 
// (https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_3/ug901-vivado-synthesis.pdf)
// Page 122
//////////////////////////////////////////////////////////////////////////////////


module single_port_ram (clk, we, en, addr, di, dout);
    parameter MEM_WIDTH = 32,
              MEM_SIZE = 24;
              
    input clk;
    input we;
    input en;
    input [$clog2(MEM_SIZE)-1:0] addr;
    input [MEM_WIDTH-1:0] di;
    output [MEM_WIDTH-1:0] dout;
    reg [MEM_WIDTH-1:0] RAM [MEM_SIZE-1:0];
    reg [MEM_WIDTH-1:0] dout;
    
    always @(posedge clk) begin
         if (en) begin
             if (we) begin
                 RAM[addr] <= di;
                 dout <= di;
             end
             else
                dout <= RAM[addr];
         end
    end
endmodule