`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/08/2019 03:18:03 PM
// Module Name: poly_ram
// Project Name:  NTT
// Description: Vivado BRAM block. 
// (https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_3/ug901-vivado-synthesis.pdf)
// Page 122
//////////////////////////////////////////////////////////////////////////////////


module poly_ram (clka,clkb,ena,enb,wea,web,addra,addrb,dia,dib,doa,dob);
    parameter FILENAME = "";
    parameter LENGTH = 2048;

    input clka, clkb, ena, enb, wea, web;
    input [$clog2(LENGTH)-1:0] addra, addrb;
    input [15:0] dia, dib;
    output [15:0] doa, dob;
    reg [15:0] ram [LENGTH-1:0];
    reg [15:0] doa, dob;
        
    // addr a logic
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
    
    // initialize top of RAM with gammas_inv_montgomery
    initial begin
      if (FILENAME != "") begin
        $readmemh(FILENAME, ram);
      end
    end
       
    
endmodule