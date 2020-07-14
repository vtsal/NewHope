`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/19/2020 02:12:51 PM
// Design Name: 
// Module Name: dynpreaddmultadd
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


// Pre-add/subtract select with Dynamic control
// dynpreaddmultadd.v
module dynpreaddmultadd # (parameter SIZEIN = 16)
    (
        input clk, ce, rst, subadd,
        input signed [SIZEIN-1:0] a, b, c, d,
        output signed [2*SIZEIN:0] dynpreaddmultadd_out
    );
    // Declare registers for intermediate values
    reg signed [SIZEIN-1:0] a_reg, b_reg, c_reg;
    reg signed [SIZEIN:0] add_reg;
    reg signed [2*SIZEIN:0] d_reg, m_reg, p_reg;
    
    always @(posedge clk) begin
        if (rst) begin
            a_reg <= 0; // Sub_a
            b_reg <= 0; // sub_a_pair
            c_reg <= 0; // sub_omega
            d_reg <= 0; // 0
            add_reg <= 0;
            m_reg <= 0;
            p_reg <= 0;
        end else if (ce) begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
            d_reg <= d;
            if (subadd)
                add_reg <= a_reg - b_reg;
            else
                add_reg <= a_reg + b_reg;
            m_reg <= add_reg * c_reg;
            p_reg <= m_reg + d_reg;
        end
    end
    // Output accumulation result
    assign dynpreaddmultadd_out = p_reg;

endmodule // dynpreaddmultadd