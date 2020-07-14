`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/18/2020 01:53:01 PM
// Design Name: 
// Module Name: gen_a
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


module gen_a(
    // basic inputs
    input clk,
    input rst,
    // control inputs
    input start,
    output reg done = 0,
    // input RAM signals
    output reg [2:0] byte_addr = 0,
    input [31:0] byte_do,
    // output RAM signals
    output reg poly_wea = 0,
    output reg [8:0] poly_addra = 0,
    output reg [15:0] poly_dia = 0,
    // Trivium module signals
    output reg [255:0] seed = 0,
    output reg reseed = 0,
    input reseed_ack,
	input [127:0] rdi_data,
	input rdi_valid,
	output reg rdi_ready = 0
	);
    
//    always @(posedge clk) begin
//        if (poly_wea) begin
//            $display("GenA,%d,%h",poly_addra,poly_dia);
//        end
//    end
    
    localparam NEWHOPE_5Q = 16'd61445;
    localparam
        HOLD       = 3'd0,
        SETUP_SEED = 3'd1,
        RUN_PRNG   = 3'd2,
        PARSE      = 3'd3;
    reg [2:0] state, state_next;
    
    // iterate registers registers
    reg [9:0] ctr;
    reg [4:0] j;
       
    wire value_valid;
    assign value_valid = (j < 16 && {rdi_data[(j+1)*8+:8], rdi_data[j*8+:8]} < NEWHOPE_5Q) ? 1'b1 : 1'b0;
       
    // combinational state logic
    always @(*) begin
        state_next = state;
    
        case (state) 
        HOLD: begin
            state_next = (start == 1'b1) ? SETUP_SEED : HOLD;
        end
        SETUP_SEED: begin
            state_next = (reseed_ack) ? RUN_PRNG : SETUP_SEED;
        end
        RUN_PRNG: begin
            state_next = (rdi_valid) ? PARSE : RUN_PRNG;
        end
        PARSE: begin
            // this logic may need adjustment (need to add squeeze logic)
            state_next = (j == 16 && ctr < 512) ? RUN_PRNG : 
                         (ctr == 511 && value_valid) ? HOLD : PARSE;
        end        
        endcase
    end
    
    // sequential state logic
    always @(posedge clk) begin
        state <= (rst) ? HOLD : state_next;
    end
    
    // sequential output logic
    always @(posedge clk) begin
        // defaults
        done <= 1'b0;
    
       // output ram (polynomial)
        poly_wea   <= 1'b0;
        
        byte_addr <= 0;
    
        // Trivium signals
        rdi_ready <= 1'b0;
        reseed <= 0;
        
        // parse state defaults
        j <= 0;        
        
        if (rst == 1'b1) begin
            ctr <= 0;
        end else begin
               
            case (state) 
            HOLD: begin
                if (start) begin
                    rdi_ready <= 1;
                end
            end
            SETUP_SEED: begin
                if (j < 8) begin
                    byte_addr <= j;
                    seed[j*32+:32] <= byte_do;
                    j <= j + 1;
                end else begin
                    j <= j;
                end
            
                if (j == 7)                
                    reseed <= 1'b1;
            end
            RUN_PRNG: begin
                rdi_ready <= 1'b0;
                j <= 0;
            end
            PARSE: begin
                if (value_valid) begin
                    // write value to poly memory
                    poly_wea <= 1'b1;
                    poly_addra <= ctr;
                    poly_dia <= {rdi_data[(j+1)*8+:8], rdi_data[j*8+:8]};
                    ctr <= ctr + 1;
                end else begin
                    ctr <= ctr;
                end
                
                if (j == 16 & ctr < 511) begin
                    // Run PRNG
                    rdi_ready <= 1'b1;
                end else if (ctr == 511 && value_valid) begin
                    done <= 1'b1;
                    ctr <= 0;
                end
                else begin
                    // continue parse
                    j <= j + 2;
                end
                
            end        
            endcase
        end
    end
    
endmodule
