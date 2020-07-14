`timescale 1ns / 1ps
// 16-bit, 5 length Shift Register
// Rising edge clock
// Active high clock enable
// Concatenation-based template
// File: shift_registers_bf.v

module shift_register_bf (
        input clk, 
        input clken, 
        input [15:0] SI, 
        output [15:0] SO
    );
    parameter LENGTH = 2;

    (* shreg_extract = "yes" *) reg [15:0] shreg[LENGTH-1:0];
    integer i;
    
    assign SO = shreg[LENGTH-1];
        
    initial begin
        for (i = 0; i < LENGTH; i = i + 1)
            shreg[i] = 0;
    end
    
    always @(posedge clk) begin
     if (clken) begin
         for (i = 0; i < LENGTH-1; i = i+1)
            shreg[i+1] <= shreg[i];
         shreg[0] <= SI; 
        end
     end
      
endmodule