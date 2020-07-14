`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/08/2019 03:18:03 PM
// Module Name: output_ram
// Description: Vivado BRAM block. 
// (https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_3/ug901-vivado-synthesis.pdf)
// Page 122
//////////////////////////////////////////////////////////////////////////////////


// Single-Port Block RAM Write-First Mode (recommended template)
// File: rams_sp_wf.v
module dual_port_ram (clka,clkb,ena,enb,wea,web,addra,addrb,dia,dib,doa,dob);
    parameter MEM_WIDTH = 8,
              MEM_SIZE = 896;

    input clka, clkb, ena, enb, wea, web;
    input [$clog2(MEM_SIZE)-1:0] addra, addrb;
    input [MEM_WIDTH-1:0] dia, dib;
    output [MEM_WIDTH-1:0] doa, dob;
    reg [MEM_WIDTH-1:0] ram [MEM_SIZE-1:0];
    reg [MEM_WIDTH-1:0] doa, dob;
        
    // addra logic
    always @(posedge clka)
    begin
        if (ena)
        begin
            if (wea)
                ram[addra] <= dia;
            doa <= ram[addra];
        end
    end
    
    // addrb logic
    always @(posedge clkb)
        begin
        
        if (enb)
        begin
            if (web)
                ram[addrb] <= dib;
            dob <= ram[addrb];
        end
    end
endmodule