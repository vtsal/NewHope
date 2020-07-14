`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/13/2020 05:40:10 PM
// Design Name: 
// Module Name: poly_arithmetic
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


module poly_arithmetic(
  // basic control signals
  input clk,
  input rst,
  input start,
  output reg done = 0,
  // operation control signals
  input [1:0] opCode,
  // Poly RAM access signals
  output reg ram_we,
  output wire [8:0] ram_addr_out,
  input [15:0] ram_doa,
  input [15:0] ram_dob,
  output [15:0] dout
  );

  // Module operations
  localparam 
    MULTIPLY         = 2'b00, 
    ADD              = 2'b01, 
    SUBTRACT         = 2'b10,
    MULTIPLY_PRECOMP = 2'b11;

  localparam 
    MULT_PIPELINE = 3'd6, 
    MULT_PRECOMP_PIPELINE = 3'd3,
    SUB_PIPELINE = 3'd2,
    ADD_PIPELINE = 3'd2;
  reg [2:0] pipeline_count = 0;
  reg [2:0] PIPELINE_LENGTH;

  always @* begin
    case (opCode) 
    MULTIPLY: begin
        PIPELINE_LENGTH = MULT_PIPELINE;
    end
    MULTIPLY_PRECOMP: begin
        PIPELINE_LENGTH = MULT_PRECOMP_PIPELINE;
    end
    SUBTRACT: begin
        PIPELINE_LENGTH = SUB_PIPELINE;
    end
    ADD: begin
        PIPELINE_LENGTH = ADD_PIPELINE;
    end
    endcase
  end

   // states operations
  reg [1:0] state, state_next;
  localparam 
    HOLD      = 2'b00, 
    LOAD      = 2'b01, 
    UNLOAD    = 2'b10;


  // keeps track of which coefficients are being affected
  reg [9:0] coeff_count, coeff_count_next;
  wire [9:0] ram_addr;
  assign ram_addr = (state == UNLOAD) ? coeff_count - pipeline_count : coeff_count;
  assign ram_addr_out = ram_addr[8:0];

  // arithmetic modules
  wire [15:0] add_out, sub_out, mult_out;
  reg sub_start;
  wire sub_done;
  wire precomp;
  reg en_mult = 1;
  reg en_add = 1;
  reg en_sub = 1;
  
  assign precomp = (opCode == MULTIPLY_PRECOMP) ? 1'b1 : 1'b0;
  
  assign dout = (opCode == MULTIPLY) ? mult_out :
                    (opCode == ADD) ? add_out :
                    (opCode == SUBTRACT) ? sub_out : 
                    (opCode == MULTIPLY_PRECOMP) ? mult_out :16'd0;

  poly_add_coeff add_module(clk, en_add, ram_doa, ram_dob, add_out);
  poly_sub_coeff sub_module(clk, en_sub, ram_doa, ram_dob, sub_out);
  poly_mult_coeff mult_module(clk, en_mult, precomp, ram_doa, ram_dob, mult_out);
  
  // combination state logic
  always @(*) begin
    // defaults
    state_next = state;
    coeff_count_next = coeff_count;
    
    case (state) 
    HOLD: begin
        coeff_count_next = 0;
        if (start) begin
            state_next = LOAD;
        end
    end
    LOAD: begin
        state_next = (done) ? HOLD 
                    : (pipeline_count == PIPELINE_LENGTH) ? UNLOAD : LOAD;
                    
        coeff_count_next = coeff_count + 1;
    end
    UNLOAD: begin
        state_next = (done) ? HOLD :
                (pipeline_count == 1) ? LOAD : UNLOAD;
    end
    endcase
  end

  // synchronous state logic
  always @(posedge clk) begin
    state <= (rst) ? HOLD : state_next;
    coeff_count <= (rst) ? 9'd0 : coeff_count_next;
  end

  // sequential output logic 
  always @(posedge clk) begin
    // default
    ram_we <= 1'b0;
    done <= 1'b0;
  
    case (state) 
    HOLD: begin
        ram_we <= 1'b0;
        pipeline_count <= 0;
    end
    LOAD: begin
        pipeline_count <= pipeline_count + 1;
        ram_we <= (pipeline_count == PIPELINE_LENGTH) ? 1'b1 : 1'b0; 
    end
    UNLOAD: begin
        if (ram_addr >= 511 && pipeline_count > 0) begin
            if (ram_addr == 511)
                done <= 1'b1;
            ram_we <= 1'b0;
        end else begin
            done <= 1'b0;
            ram_we <= 1'b1;
        end
       
        pipeline_count <= (pipeline_count == 1) ? 0 : pipeline_count - 1;
    end
    endcase
  end
endmodule
