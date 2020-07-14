`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/03/2020 08:19:21 AM
// Design Name: 
// Module Name: seed_expander
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


module seed_expander(
    // basic inputs
    input clk,
    input rst,
    // control inputs
    input start,
    output reg done = 0,
    // input RAM signals
    output reg [3:0] seed_ram_addr = 0,
    output reg seed_ram_we = 0,
    output reg [31:0] seed_ram_di,
    input [31:0] seed_ram_do,
    // Trivium module signals
    output reg [255:0] seed = 0,
    output reg reseed = 0,
    input reseed_ack,
	input [127:0] rdi_data,
	input rdi_valid,
	output reg rdi_ready = 0
    );
    
    localparam
        HOLD       = 2'd0,
        SETUP_SEED = 2'd1,
        RUN_PRNG   = 2'd2,
        STORE      = 2'd3;
    reg [1:0] state, state_next;
    reg [3:0] j;   
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
            state_next = (rdi_valid) ? STORE : RUN_PRNG;
        end
        STORE: begin
            state_next = (j == 15) ? HOLD
                            : (j[1:0] == 2'b11) ? RUN_PRNG : STORE;
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
        
        // seed ram (polynomial)
        seed_ram_addr <= 0;
        seed_ram_we <= 0;
        seed_ram_di <= 0;
    
        // Trivium signals
        rdi_ready <= 1'b0;
        reseed <= 0;
    
        j <= 0;
        
        if (rst == 1'b1) begin
            seed_ram_addr <= 0;
        end else begin
               
            case (state) 
            HOLD: begin
                if (start) begin
                    rdi_ready <= 1;
                end
            end
            SETUP_SEED: begin
                if (j < 8) begin
                    seed_ram_addr <= j;
                    seed[j*32+:32] <= seed_ram_do;
                    j <= j + 1;
                end else begin
                    reseed <= 1'b1;
                    j <= (reseed_ack) ? 0 : j;
                end
            end
            RUN_PRNG: begin
                rdi_ready <= 1'b0;
                j <= j;
            end
            STORE: begin
                seed_ram_addr <= j;
                seed_ram_we <= 1;
                seed_ram_di <= rdi_data[32*j[1:0]+:32];
                
                // run PRNG if ready
                if (j[1:0] == 2'b11) begin
                    rdi_ready <= 1'b1;
                end
                
                if (j == 15) begin
                    done <= 1;
                end 
                else if (j[1:0] == 2'b11) begin
                    rdi_ready <= 1'b1;
                    j <= j + 1;
                end else begin
                    j <= j + 1;
                end
            end        
            endcase
        end
    end
    
endmodule
