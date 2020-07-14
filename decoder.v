`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/03/2020 05:16:32 PM
// Design Name: 
// Module Name: encoder
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


module decoder( 
    // basic inputs
    input clk,
    input rst,
    // control inputs
    input start,
    output reg done,
    // output RAM signals
    output reg byte_we,
    output reg [2:0] byte_addr,
    output reg [0:31] byte_di,
    // input RAM signals
    output reg [8:0] poly_addra,
    input [15:0] poly_doa
    );

    localparam
        HOLD = 4'd0,
        S0   = 4'd1,
        S1   = 4'd2,
        S2   = 4'd3,
        S3   = 4'd4;
    reg [2:0] state = HOLD, state_next;

    // combinational state logic
    reg[7:0] i = 0;
    reg [15:0] t = 0;
    wire [4:0] bit_sel;
    assign bit_sel = {i[4:3], 3'd7-i[2:0]}; // store order is byte-wise little endian
    
    reg [15:0] NEWHOPE_HALF_Q = 16'd6144;
    
    always @(*) begin
        state_next = state;
    
        case (state) 
        HOLD: begin
            state_next = (start) ? S0 : state_next;
        end
        S0: begin
            state_next = S1;
        end      
        S1: begin
            state_next = S2;
        end 
        S2: begin
            state_next = S3;
        end
        S3: begin
            state_next = (i == 255) ? HOLD : S0;
        end
        endcase
    end
    
    // sequential state logic
    always @(posedge clk) begin
        state <= (rst) ? HOLD : state_next;
    end
    
always @(posedge clk) begin
        // defaults
        done <= 1'b0;
        i <= i;

        // Output RAM signals
        byte_we <= 0;
        byte_addr <= 0;
        byte_di <= byte_di;
        
        // Input RAM signals
        poly_addra <= poly_addra;

        if (rst == 1'b1) begin
            poly_addra <= 0;
            i <= 0;
            t <= 0;
            byte_di <= 0;
        end else begin
            case (state) 
            HOLD: begin
                poly_addra <= 0;
                i <= 0;
                t <= 0;
                byte_di <= 0;
                if (start) begin
                    poly_addra <= {1'b1, poly_addra};
                end
            end
            S0: begin
                // begin calculations
                t <= (poly_doa < NEWHOPE_HALF_Q) ? (NEWHOPE_HALF_Q - poly_doa) : (poly_doa - NEWHOPE_HALF_Q);
            end      
            S1: begin
                t <= (poly_doa < NEWHOPE_HALF_Q) ? (t + NEWHOPE_HALF_Q - poly_doa) : (t + poly_doa - NEWHOPE_HALF_Q);
            end 
            S2: begin
                t <= t - NEWHOPE_HALF_Q;
                
                // get next value from poly_ram
                poly_addra <= {1'b0, i+1};
            end
            S3: begin
                // store result
                byte_di[bit_sel] <= t[15];
                
                // if 32 bits have been set, store
                if (i != 0 & i[4:0] == 5'b11111) begin
                    byte_addr <= i[7:5];
                    byte_we <= 1;
                end

                // get next value from poly_ram
                poly_addra <= {1'b1, i+1};
                // update counter
                i <= i + 1;
                if (i == 255) begin
                    done <= 1;
                end
            end
            endcase
        end
    end
endmodule
