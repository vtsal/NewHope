`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Virginia Tech
// Engineer: Luke Beckwith
// 
// Create Date: 05/07/2019 10:37:11 PM
// Module Name: encrypter
// Project Name:  NewHope
// Description: Performs newhope encryption
//////////////////////////////////////////////////////////////////////////////////


module encrypter(
    input clk,
    input rst,
    // control signals
    input start,
    output reg encrypter_done,    
    // byte data input
    input [31:0] input1_dia,
    input input1_wea,
    input [4:0] input1_addra,
    input [7:0] input2_dia,
    input input2_wea,
    input [9:0] input2_addra,
    // output byte data
    input [10:0] output_addr, 
    output [7:0] output_do
    );
    
    // state regs
    localparam
        HOLD = 4'd0,
        S0   = 4'd1,
        S1   = 4'd2,
        S2   = 4'd3,
        S3   = 4'd4,
        S4   = 4'd5,
        S5   = 4'd6,
        S6   = 4'd7,
        S7   = 4'd8,
        S8   = 4'd9,
        S9   = 4'd10;
    reg [3:0] encrypter_state = HOLD, encrypter_state_next;
    reg done_op1, done_op2;
    wire s_done;
    assign s_done = done_op1 & done_op2;
    
    /* --- POLYNOMIAL RAM 1 --- */    
    wire [15:0] PR1_doa, PR1_dob;
    reg [15:0] PR1_dia, PR1_dib;
    reg PR1_wea, PR1_web;
    reg [10:0] PR1_addra, PR1_addrb;
    
    /* --- POLYNOMIAL RAM 2 --- */    
    wire [15:0] PR2_doc, PR2_dod;
    reg [15:0] PR2_dic, PR2_did;
    reg PR2_wec, PR2_wed;
    reg [10:0] PR2_addrc, PR2_addrd;
    
    /* POLY ARTHIMETIC 1 WIRE */
    reg start_pa1;
    wire done_pa1;
    reg [1:0] op_code_pa1;
    wire PR_we_pa1;
    wire [8:0] PR_addr_pa1;
    wire [15:0] PR_di_pa1, PR_do1_pa1, PR_do2_pa1;
    assign PR_do1_pa1 = PR1_doa;
    assign PR_do2_pa1 = (encrypter_state == S8) ? PR2_dod : PR1_dob;
    
    /* POLY ARTHIMETIC 2 WIRE */
    reg start_pa2;
    wire done_pa2;
    reg [1:0] op_code_pa2;
    wire PR_we_pa2;
    wire [8:0] PR_addr_pa2;
    wire [15:0] PR_di_pa2, PR_do1_pa2, PR_do2_pa2;
    assign PR_do1_pa2 = PR2_doc;
    assign PR_do2_pa2 = (encrypter_state == S1) ? PR1_doa : 
                        (encrypter_state == S8) ? PR1_dob : PR2_dod;

    /* NTT WIRES */
    reg start_ntt, inverse_ntt;
    wire done_ntt;
    wire PR_wea_ntt, PR_web_ntt;
    wire [8:0] PR_addra_ntt, PR_addrb_ntt;
    wire [15:0] PR_dia_ntt, PR_dib_ntt, PR_doa_ntt, PR_dob_ntt;
    assign PR_doa_ntt = (encrypter_state == S7) ? PR1_doa : PR2_doc;
    assign PR_dob_ntt = (encrypter_state == S7) ? PR1_dob : PR2_dod;
    
    /* ENCODER WIRES */
    reg start_enc;
    wire done_enc, PR1_wea_enc, PR1_web_enc;
    wire [2:0] IR_addr_enc;
    wire [8:0] PR1_addra_enc, PR1_addrb_enc;
    wire [15:0] PR1_dia_enc, PR1_dib_enc;
    
    /* COMPRESSOR WIRES */
    reg start_comp;
    wire done_comp, OR_we_comp;
    wire [7:0] OR_addr_comp;
    wire [7:0] OR_di_comp;
    wire [8:0] PR1_addr_comp;

    /* POLY DECODER WIRES */
    reg start_pd;
    wire done_pd, PR2_wed_pd;
    wire [9:0] IR_addr_pd; 
    wire [8:0] PR2_addrd_pd;
    wire [15:0] PR2_did_pd;
    
    /* POLY ENCODER WIRES */
    reg start_pe;
    wire done_pe, OR_we_pe;
    wire [9:0] OR_addr_pe;
    wire [7:0] OR_di_pe;
    wire [8:0] PR2_addrc_pe;
        
    /* GENA WIRES*/
    reg start_ga, rst_ga;
    wire done_ga, PR2_wed_ga;
    wire [2:0] IR_addr_ga;
    wire [8:0] PR2_addrd_ga;
    wire [15:0] PR2_did_ga;
    wire [255:0] seed_ga;
    wire reseed_ga, rdi_ready_ga;
   
    /* SAMPLER WIRES */
    reg start_bs;
    reg rst_bs;
    reg reseed_needed_bs;
    wire done_bs;
    wire [2:0] IR_addra_bs;
    wire PR_we_bs;
    wire [8:0] PR_addr_bs;
    wire [15:0] PR_di_bs;
    wire [255:0] seed_bs;
    wire reseed_bs, rdi_ready_bs;
    
   
    /* Trivium Wires */
    reg en_prng = 0;
    wire [255:0] seed;
    wire [127:0] rdi_data;
    wire reseed;
    wire reseed_ack, rdi_valid, rdi_ready;

    
    // if state == S1, then genA gets control, otherwise sampler
    assign rdi_ready = (encrypter_state == S1) ? rdi_ready_ga : rdi_ready_bs;
    assign reseed =  (encrypter_state == S1) ? reseed_ga : reseed_bs;
    assign rdi_ready =  (encrypter_state == S1) ? rdi_ready_ga : rdi_ready_bs;
    assign seed = (encrypter_state == S1) ? seed_ga : seed_bs;
    
    /* ---  INPUT RAM 1 --- */
    wire IR1_we;
    wire [4:0] IR1_addr;
    wire [31:0] IR1_di, IR1_dout;
    assign IR1_we = (encrypter_state == HOLD) ? input1_wea : 1'b0;
    assign IR1_addr = (encrypter_state == HOLD) ? input1_addra :
                        (encrypter_state == S1) ? {2'd1, IR_addr_ga} :
                        (encrypter_state == S4) ? {2'd2, IR_addr_enc} : {2'd0, IR_addra_bs};
    assign IR1_di = (encrypter_state == HOLD) ? input1_dia : 32'd0;
    
    single_port_ram #(.MEM_WIDTH(32), .MEM_SIZE(24)) I1_RAM (clk, IR1_we, 1'b1, IR1_addr, IR1_di, IR1_dout);
    
    /* ---  INPUT RAM 2 --- */
    wire IR2_we;
    wire [9:0] IR2_addr;
    wire [7:0] IR2_di, IR2_dout;
    assign IR2_we = input2_wea;
    assign IR2_addr = (encrypter_state == HOLD) ? input2_addra : IR_addr_pd;
    assign IR2_di = input2_dia;
    
    single_port_ram #(.MEM_WIDTH(8), .MEM_SIZE(896)) I2_RAM (clk, IR2_we, 1'b1, IR2_addr, IR2_di, IR2_dout);
   
   /* --- POLY RAM --- */    
    poly_ram #(.FILENAME("D:/programming/git_backups/Newhope_Crypto/gammas.txt")) P1_RAM(clk,clk,1'b1, 1'b1, PR1_wea, PR1_web, PR1_addra, PR1_addrb, PR1_dia, PR1_dib, PR1_doa, PR1_dob);  
 
    poly_ram #(.FILENAME("D:/programming/git_backups/Newhope_Crypto/gammas_inv.txt")) P2_RAM(clk,clk,1'b1, 1'b1, PR2_wec, PR2_wed, PR2_addrc, PR2_addrd, PR2_dic, PR2_did, PR2_doc, PR2_dod);  
    
     /* --- OUTPUT RAM --- */
    wire OR_clka, OR_clkb, OR_wea, OR_web;
    wire [10:0] OR_addra, OR_addrb;
    wire [7:0] OR_dia, OR_dib, OR_doa, OR_dob;    
    
    // A port assignments  
    assign OR_addra = (encrypter_state == HOLD) ? output_addr : OR_addr_comp+10'd896;
    assign OR_wea = OR_we_comp;
    assign OR_dia = OR_di_comp;
    assign output_do = OR_doa;
    
    // B port assignments  
    assign OR_addrb = OR_addr_pe;
    assign OR_web = OR_we_pe;
    assign OR_dib = OR_di_pe;
    
    
    dual_port_ram #(.MEM_WIDTH(8), .MEM_SIZE(1088)) O_RAM (clk,clk,1'b1,1'b1,OR_wea,OR_web,OR_addra,OR_addrb,OR_dia,OR_dib,OR_doa,OR_dob);
    
    /* --- SUBMODULE INSTANCES --- */   
    poly_arithmetic POLY_ARITH1(clk, rst, start_pa1, done_pa1, op_code_pa1, PR_we_pa1,
                                PR_addr_pa1, PR_do1_pa1, PR_do2_pa1, PR_di_pa1);
                                
    poly_arithmetic POLY_ARITH2(clk, rst, start_pa2, done_pa2, op_code_pa2, PR_we_pa2,
                                PR_addr_pa2, PR_do1_pa2, PR_do2_pa2, PR_di_pa2);
    
    ntt NTT(clk, rst, start_ntt, inverse_ntt, done_ntt, PR_wea_ntt, PR_web_ntt,
            PR_addra_ntt, PR_addrb_ntt, PR_dia_ntt, PR_dib_ntt, 
            PR_doa_ntt, PR_dob_ntt);
    
    encoder ENC(clk, rst, start_enc, done_enc, IR_addr_enc, IR1_dout, PR1_wea_enc, 
                PR1_addra_enc, PR1_dia_enc, PR1_web_enc, PR1_addrb_enc, PR1_dib_enc);
    
    compressor COMPRESSOR(clk, rst, start_comp, done_comp, OR_addr_comp, OR_di_comp,
                    OR_we_comp, PR1_addr_comp, PR1_dob);
    
    polynomial_decoder POLY_DEC(clk, rst, start_pd, done_pd, IR_addr_pd, IR2_dout,
                                PR2_wed_pd, PR2_addrd_pd, PR2_did_pd);
    
    polynomial_encoder POLY_ENC(clk, rst, start_pe, done_pe, OR_we_pe,
                                OR_addr_pe, OR_di_pe, PR2_addrc_pe, PR2_doc);
    
    gen_a GENA(clk, rst, start_ga, done_ga,            // ctrl
                 IR_addr_ga, IR1_dout,                 // in ram
                 PR2_wed_ga, PR2_addrd_ga, PR2_did_ga, // out ram
                 seed_ga, reseed_ga, reseed_ack, rdi_data, rdi_valid, rdi_ready_ga);      // trivium 
    
    binomial_sampler SAMPLER(clk, rst_bs, start_bs, done_bs, reseed_needed_bs, // ctrl
                            IR_addra_bs, IR1_dout,                 // in ram
                            PR_we_bs, PR_addr_bs, PR_di_bs,  // out ram
                            seed_bs, reseed_bs, reseed_ack, rdi_data, rdi_valid, rdi_ready_bs); // trivium 

    prng_trivium_enhanced 
        #(.N(2)) 
    PRNG (
        .clk(clk),
        .rst(rst),
        .en_prng(en_prng),
        .seed(seed),
        .reseed(reseed),
        .reseed_ack(reseed_ack),
        .rdi_data(rdi_data),
        .rdi_ready(rdi_ready),
        .rdi_valid(rdi_valid)
     );  
    /* --- Start controller logic --- */
    
    
    // combinational state logic
    always @(*) begin
        encrypter_state_next = encrypter_state;
    
        case (encrypter_state) 
        HOLD: begin
            encrypter_state_next = (start) ? S0 : HOLD;
        end
        S0: begin
            encrypter_state_next = (s_done) ? S1 : S0;
        end
        S1: begin
            encrypter_state_next = (s_done) ? S2 : S1;
        end
        S2: begin
            encrypter_state_next = (s_done) ? S3 : S2;
        end
        S3: begin
            encrypter_state_next = (s_done) ? S4 : S3;
        end
        S4: begin
            encrypter_state_next = (s_done) ? S5 : S4;
        end
        S5: begin
            encrypter_state_next = (s_done) ? S6 : S5;
        end
        S6: begin
            encrypter_state_next = (s_done) ? S7 : S6;
        end
        S7: begin
            encrypter_state_next = (s_done) ? S8 : S7;
        end
        S8: begin
            encrypter_state_next = (s_done) ? S9 : S8;
        end
        S9: begin
            encrypter_state_next = (s_done) ? HOLD : S9;
        end
        endcase
    end
    
    // sequential state logic
    always @(posedge clk) begin
        encrypter_state <= (rst) ? HOLD : encrypter_state_next;
    end
    
// combinational for PolyRam 1 and 2 logic
   always @(*) begin 
        PR1_addra = 11'd0;
        PR1_wea = 1'd0;
        PR1_dia = 16'd0;
        
        PR1_addrb = 11'd0;
        PR1_web = 1'd0;
        PR1_dib = 16'd0;       
       
        PR2_addrc = 11'd0;
        PR2_wec = 1'd0;
        PR2_dic = 16'd0;
        
        PR2_addrd = 11'd0;
        PR2_wed = 1'd0;
        PR2_did = 16'd0;     
       
        case (encrypter_state) 
        S0: begin
            PR2_addrc = {2'd3 , PR_addr_bs};
            PR2_wec = PR_we_bs;
            PR2_dic = PR_di_bs;
            
            PR2_addrd = {2'd1 , PR2_addrd_pd};
            PR2_wed = PR2_wed_pd;
            PR2_did = PR2_did_pd;  
        end
        S1: begin
            PR1_addra = {2'd0, PR_addr_pa2};
            
            PR2_addrc = {2'd3 , PR_addr_pa2};
            PR2_wec = PR_we_pa2;
            PR2_dic = PR_di_pa2;
            
            PR2_addrd = {2'd2 , PR2_addrd_ga};
            PR2_wed = PR2_wed_ga;
            PR2_did = PR2_did_ga;  
        end
        S2: begin
            PR1_addra = {2'd2, PR_addr_bs};
            PR1_wea = PR_we_bs;
            PR1_dia = PR_di_bs;
            
            PR2_addrc = {2'd3 , PR_addra_ntt};
            PR2_wec = PR_wea_ntt;
            PR2_dic = PR_dia_ntt;
            
            PR2_addrd = {2'd3 , PR_addrb_ntt};
            PR2_wed = PR_web_ntt;
            PR2_did = PR_dib_ntt;  
        end
        S3: begin
            PR1_addra = {2'd1, PR_addr_bs};
            PR1_wea = PR_we_bs;
            PR1_dia = PR_di_bs;
            
            PR2_addrc = {2'd1 , PR_addr_pa2};
            PR2_wec = PR_we_pa2;
            PR2_dic = PR_di_pa2;
            
            PR2_addrd = {2'd3 , PR_addr_pa2};
        end
        S4: begin
            PR1_addra = {2'd3, PR1_addra_enc};
            PR1_wea = PR1_wea_enc;
            PR1_dia = PR1_dia_enc;
            
            PR1_addrb = {2'd3, PR1_addrb_enc};
            PR1_web = PR1_web_enc;
            PR1_dib = PR1_dib_enc;  
            
            PR2_addrc = {2'd1 , PR_addra_ntt};
            PR2_wec = PR_wea_ntt;
            PR2_dic = PR_dia_ntt;
            
            PR2_addrd = {2'd1 , PR_addrb_ntt};
            PR2_wed = PR_web_ntt;
            PR2_did = PR_dib_ntt; 
        end
        S5: begin
            PR1_addra = {2'd3, PR_addr_pa1};
            PR1_wea = PR_we_pa1;
            PR1_dia = PR_di_pa1;
            
            PR1_addrb = {2'd1, PR_addr_pa1};
            
            PR2_addrc = {2'd1 , PR_addr_pa2};
            PR2_wec = PR_we_pa2;
            PR2_dic = PR_di_pa2;
            
            PR2_addrd = {2'd0 , PR_addr_pa2};
        end
        S6: begin
            PR1_addra = {2'd2, PR_addr_pa1};
            PR1_wea = PR_we_pa1;
            PR1_dia = PR_di_pa1;
            
            PR1_addrb = {2'd0, PR_addr_pa1};
            
            PR2_addrc = {2'd2 , PR_addr_pa2};
            PR2_wec = PR_we_pa2;
            PR2_dic = PR_di_pa2;
            
            PR2_addrd = {2'd3 , PR_addr_pa2};
        end
        S7: begin
            PR1_addra = {2'd2, PR_addra_ntt};
            PR1_wea = PR_wea_ntt;
            PR1_dia = PR_dia_ntt;
            
            PR1_addrb = {2'd2, PR_addrb_ntt};
            PR1_web = PR_web_ntt;
            PR1_dib = PR_dib_ntt;  
        end
        S8: begin
            PR1_addra = {2'd3, PR_addr_pa1};
            PR1_wea = PR_we_pa1;
            PR1_dia = PR_di_pa1;
            
            PR1_addrb = {2'd2, PR_addr_pa2};
            
            PR2_addrc = {2'd2 , PR_addr_pa2};
            PR2_wec = PR_we_pa2;
            PR2_dic = PR_di_pa2;
            
            PR2_addrd = {2'd1 , PR_addr_pa1};
        end
        S9: begin
            PR1_addrb = {2'd3, PR1_addr_comp};
            
            PR2_addrc = {2'd2, PR2_addrc_pe};
        end
        endcase
    end
    
    // sequential output logic
    always @(posedge clk) begin  
        // defaults
        done_op1 <= done_op1;
        done_op2 <= done_op2;
        inverse_ntt <= 1'b0;

        encrypter_done <= 1'b0;
        
        rst_bs <= 1'b0;
     
        start_bs   <= 1'b0;
        start_pd   <= 1'b0;
        start_pa1  <= 1'b0;
        start_pa2  <= 1'b0;
        start_ga   <= 1'b0;
        start_ntt  <= 1'b0;
        start_enc  <= 1'b0;
        start_pe   <= 1'b0;
        start_comp <= 1'b0;
        
        op_code_pa1 <= op_code_pa1;
        op_code_pa2 <= op_code_pa2;
        
        en_prng <= 1'b0;
        reseed_needed_bs <= 1'b0;
        
        if (rst == 1'b1) begin
            rst_bs <= 1'b1;
        end else begin
            case (encrypter_state) 
            HOLD: begin
                op_code_pa1 <= 2'd0;
                op_code_pa2 <= 2'd0;
                done_op1 <= 1'b0;
                done_op2 <= 1'b0;
                if (start) begin
                    reseed_needed_bs <= 1'b1;
                    start_bs <= 1'b1;
                    start_pd <= 1'b1;
//                    $display("BS sampling s'");
                end
            end
            S0: begin
                en_prng <= 1'b1;
                if (s_done) begin
                    done_op1 <= 1'b0;
                    done_op2 <= 1'b0;
                    
                    op_code_pa2 <= 3'd3; // MULTIPLY_PRECOMP
                    start_pa2 <= 1'b1;
                    start_ga <= 1'b1;
//                    $display("GenA");
                end 
                if (done_bs) begin
                    done_op1 <= 1'b1;
                    rst_bs <= 1'b1;
                end 
                if (done_pd) begin
                    done_op2 <= 1'b1;
                end
            end
            S1: begin
                en_prng <= 1'b1;
                if (s_done) begin
                    done_op1 <= 1'b0;
                    done_op2 <= 1'b0;
                    
                    start_ntt <= 1'b1;
                    start_bs <= 1'b1;
//                    $display("BS sampling e'");
                end 
                if (done_pa2) begin
                    done_op1 <= 1'b1;
                end 
                if (done_ga) begin
                    done_op2 <= 1'b1;
                end
            end
            S2: begin
                en_prng <= 1'b1;
                if (s_done) begin
                    done_op1 <= 1'b0;
                    done_op2 <= 1'b0;
                    
                    op_code_pa2 <= 3'd0; // MULTIPLY
                    start_pa2 <= 1'b1;
                    start_bs <= 1'b1;
//                    $display("BS sampling e''");
                end 
                if (done_ntt) begin
                    done_op1 <= 1'b1;
                end 
                if (done_bs) begin
                    rst_bs <= 1'b1;
                    done_op2 <= 1'b1;
                end
            end
            S3: begin
                en_prng <= 1'b1;
                if (s_done) begin
                    done_op1 <= 1'b0;
                    done_op2 <= 1'b0;
                    inverse_ntt <= 1'b1;
                    
                    start_ntt <= 1'b1;
                    start_enc <= 1'b1;
                end 
                if (done_pa2) begin
                    done_op1 <= 1'b1;
                end 
                if (done_bs) begin
                    rst_bs <= 1'b1;
                    done_op2 <= 1'b1;
                end
            end
            S4 : begin
                inverse_ntt <= 1'b1;
                if (s_done) begin
                    done_op1 <= 1'b0;
                    done_op2 <= 1'b0;
                    
                    op_code_pa1 <= 3'd1; // ADD 
                    op_code_pa2 <= 3'd3; // MULTIPLY_PRECOMP
                    start_pa1 <= 1'b1;
                    start_pa2 <= 1'b1;
                end 
                if (done_ntt) begin
                    done_op1 <= 1'b1;
                end 
                if (done_enc) begin
                    done_op2 <= 1'b1;
                end
            end
            S5: begin
                if (s_done) begin
                    done_op1 <= 1'b0;
                    done_op2 <= 1'b0;
                    
                    op_code_pa1 <= 3'd3; // MULTIPLY_PRECOMP 
                    op_code_pa2 <= 3'd0; // MULTIPLY
                    start_pa1 <= 1'b1;
                    start_pa2 <= 1'b1;
                end 
                if (done_pa1) begin
                    done_op1 <= 1'b1;
                end 
                if (done_pa2) begin
                    done_op2 <= 1'b1;
                end
            end
            S6: begin
                if (s_done) begin
                    done_op1 <= 1'b0;
                    done_op2 <= 1'b0;
                    
                    start_ntt <= 1'b1;
                end 
                if (done_pa1) begin
                    done_op1 <= 1'b1;
                end 
                if (done_pa2) begin
                    done_op2 <= 1'b1;
                end
            end
            S7: begin
                if (s_done) begin
                    done_op1 <= 1'b0;
                    done_op2 <= 1'b0;
                    
                    op_code_pa1 <= 3'd1; // ADD 
                    op_code_pa2 <= 3'd1; // ADD
                    start_pa1 <= 1'b1;
                    start_pa2 <= 1'b1;
                end 
                if (done_ntt) begin
                    done_op1 <= 1'b1;
                    done_op2 <= 1'b1;
                end
            end
            S8: begin
                if (s_done) begin
                    done_op1 <= 1'b0;
                    done_op2 <= 1'b0;
                    
                    start_pe <= 1'b1;
                    start_comp <= 1'b1;
                end 
                if (done_pa1) 
                    done_op1 <= 1'b1;
                if (done_pa2) 
                    done_op2 <= 1'b1;
                
            end
            S9: begin
                if (s_done) begin
                    done_op1 <= 1'b0;
                    done_op2 <= 1'b0;
 
                    encrypter_done <= 1'b1;
                end 
                if (done_pe) 
                    done_op1 <= 1'b1;
                if (done_comp) 
                    done_op2 <= 1'b1;
            end
            endcase
        end
    end
    
endmodule
