`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Virginia Tech
// Engineer: Luke Beckwith
// 
// Create Date: 05/07/2019 10:37:11 PM
// Module Name: get_address
// Project Name:  NTT
// Description: Given the bf_num and layer, this determines what
//  addresses should be the input to the butterfly module
//////////////////////////////////////////////////////////////////////////////////

module bf_addr(
    input [3:0] layer_num,
    input [7:0] bf_num,
    output [8:0] addr_a,
    output [8:0] addr_pair 
    );
    
    reg [8:0] addr_a_reg, addr_pair_reg;
    assign addr_a = addr_a_reg[8:0];
    assign addr_pair = addr_pair_reg[8:0];

    reg [8:0] offset; 
    
    // combinational block
    always @(*) begin       
        offset = (bf_num >> (8-layer_num));

        addr_a_reg = (({bf_num[7:0],1'd0} << layer_num) & 9'd511) + offset;
        addr_pair_reg = (({bf_num[7:0],1'd1} << layer_num) & 9'd511) + offset; 
    end
   
endmodule
