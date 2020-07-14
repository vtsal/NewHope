`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/03/2020 08:14:18 AM
// Design Name: 
// Module Name: keygen
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


module keygen(
    input clk,
    input rst,
    input en,
    // control signals
    input start,
    output reg keygen_done,    
    // byte data input
    input [31:0] input_dia,
    input input_wea,
    input [3:0] input_addra,
    // output (size mismatch with input should be fixed)
    input [10:0] output_addr, 
    output reg [7:0] output_do
    );
        
    localparam
        S_ADDR = 1'd1,
        A_ADDR = 1'd0,
        E_ADDR = 1'd1,
        G_ADDR = 1'd0;
    
    localparam
        HOLD = 4'd0,
        S0   = 4'd1,
        S1   = 4'd2,
        S2   = 4'd3,
        S3   = 4'd4,
        S4   = 4'd5,
        S5   = 4'd6,
        S6   = 4'd7,
        S7   = 4'd8;
    reg [3:0] keygen_state = HOLD, keygen_state_next;
    
    /* --- POLYNOMIAL RAM 1 --- */    
    wire [15:0]  PR1_doa,   PR1_dob;
    reg  [15:0]  PR1_dia,   PR1_dib;
    reg          PR1_wea,   PR1_web;
    reg  [9:0]   PR1_addra, PR1_addrb;
    
    /* --- POLYNOMIAL RAM 2 --- */    
    wire [15:0] PR2_doc,   PR2_dod;
    reg  [15:0] PR2_dic,   PR2_did;
    reg         PR2_wec,   PR2_wed;
    reg  [9:0]  PR2_addrc, PR2_addrd;
    
    /* ---  INPUT RAM --- */
    wire [31:0] IR_doa,   IR_dob;  
    reg  [31:0] IR_dia,   IR_dib;
    reg         IR_wea,   IR_web;
    reg  [3:0]  IR_addra, IR_addrb;
      
   
    /* --- OUTPUT RAM --- */
    reg         OR_wea,   OR_web;
    reg  [10:0] OR_addra, OR_addrb;
    reg  [7:0]  OR_dia,   OR_dib;
    wire [7:0]  OR_doa,   OR_dob;   
      
    /* SEED EXPANDER WIRES*/   
    reg          start_se;
    wire         done_se;
    wire [3:0]   IR_addr_se;
    wire         IR_we_se;
    wire [31:0]  IR_di_se;
    wire [255:0] seed_se;
    wire         reseed_se, rdi_ready_se;
      
    /* GENA WIRES*/ 
    reg start_ga, rst_ga;
    wire done_ga;
    wire [2:0] IR_addr_ga;
    wire PR_we_ga;
    wire [8:0] PR_addr_ga;
    wire [15:0] PR_di_ga;
    wire [255:0] seed_ga;
    wire reseed_ga, rdi_ready_ga;
      
    /* SAMPLER WIRES */
    reg start_bs;
    reg reseed_needed_bs;
    wire done_bs;
    wire [2:0] IR_addr_bs;
    wire PR_we_bs;
    wire [8:0] PR_addr_bs;
    wire [15:0] PR_di_bs;
    wire [255:0] seed_bs;
    wire reseed_bs, rdi_ready_bs;
         
    /* NTT WIRES */
    reg start_ntt, inverse_ntt;
    wire done_ntt;
    wire PR_we1_ntt, PR_we2_ntt;
    wire [8:0] PR_addr1_ntt, PR_addr2_ntt;
    wire [15:0] PR_di1_ntt, PR_di2_ntt, PR_do1_ntt, PR_do2_ntt;
    assign PR_do1_ntt = (keygen_state == S4) ? PR1_doa : PR2_doc;
    assign PR_do2_ntt = (keygen_state == S4) ? PR1_dob : PR2_dod;
    
    /* POLY ARTHIMETIC WIRE */
    reg start_pa;
    wire done_pa;
    reg [1:0] op_code_pa;
    wire PR_we_pa;
    wire [8:0] PR_addr_pa;
    wire [15:0] PR_di_pa; 
    reg [15:0] PR_do1_pa, PR_do2_pa;
    
    /* POLY ENCODER WIRES */
    reg start_pe;
    wire done_pe, OR_we_pe;
    wire [9:0] OR_addr_pe;
    wire [7:0] OR_di_pe;
    wire [8:0] PR_addr_pe;
    
   /* TRIVIUM WIRES */
    reg en_prng;
    reg [255:0] seed;
    wire [127:0] rdi_data;
    reg reseed;
    wire reseed_ack, rdi_valid;
    reg rdi_ready;
    
    // TRIVIUM logic assignments
   always @(*) begin
        rdi_ready = 1'd0;
        en_prng = 1'd0;
        seed = seed_bs;
        reseed = 1'b0;
        
        case (keygen_state) 
        S0: begin
            en_prng = 1'd1;
            reseed = reseed_se;
            seed = seed_se;
            rdi_ready = rdi_ready_se;
        end
        S1: begin
            en_prng = 1'd1;
            reseed = reseed_ga;
            seed = seed_ga;
            rdi_ready = rdi_ready_ga;
        end
        S2: begin
            en_prng = 1'd1;
            reseed = reseed_bs;
            seed = seed_bs;
            rdi_ready = rdi_ready_bs;
        end
        S3: begin
            en_prng = 1'd1;
            reseed = reseed_bs;
            seed = seed_bs;
            rdi_ready = rdi_ready_bs;
        end

        endcase
    end
    
    // MUX logic for PA inputs
    always @(*) begin
        PR_do1_pa = 16'd0;
        PR_do2_pa = 16'd0;
        
        case (keygen_state) 
        S3: begin
            PR_do1_pa = PR1_doa;
            PR_do2_pa = PR2_dod;
        end
        S4: begin
            PR_do1_pa = PR2_doc;
            PR_do2_pa = PR2_dod;
        end
        S5: begin
            PR_do1_pa = PR1_doa;
            PR_do2_pa = PR1_dob;
        end
        S6: begin
            PR_do1_pa = PR1_doa;
            PR_do2_pa = PR2_dod;
        end
        endcase
    end

    
    /* SEED MOVER WIRES */
    reg start_sm;
    wire done_sm, OR_we_sm;
    wire [2:0] IR_addr_sm;
    wire [4:0] OR_addr_sm;
    wire [7:0] OR_di_sm;
    
    // combinational state input_ram MUX    
    always @(*) begin
        // DEFAULTS
        IR_dia   = 32'd0;
        IR_dib   = 32'd0;
        IR_wea   = 1'd0;
        IR_web   = 1'd0;
        IR_addra = 4'd0;
        IR_addrb = 4'd0;
        
        case (keygen_state) 
        HOLD: begin
            IR_dia = input_dia;
            IR_wea = input_wea;
            IR_addra = input_addra;
        end
        S0: begin
            IR_dib   = IR_di_se;
            IR_web   = IR_we_se;
            IR_addrb = IR_addr_se;
        end
        S1: begin
            IR_addrb = {1'd0, IR_addr_ga};
        end
        S2: begin   
             IR_addra = {1'd1, IR_addr_bs};
        end
        S7: begin
            IR_addrb = {1'd0, IR_addr_sm};
        end
        endcase
    end
    
    dual_port_ram #(.MEM_WIDTH(32), .MEM_SIZE(16)) I_RAM (clk, clk,en,en,IR_wea,IR_web,IR_addra,IR_addrb,IR_dia,IR_dib,IR_doa,IR_dob);
    
    /* --- POLY RAM --- */    
    poly_ram #(.LENGTH(1024)) P1_RAM(clk,clk,en,en,PR1_wea,PR1_web,PR1_addra,PR1_addrb,PR1_dia,PR1_dib,PR1_doa,PR1_dob);  
 
    poly_ram #(.LENGTH(1024), .FILENAME("D:/programming/git_backups/Newhope_Crypto/gammas.txt")) 
        P2_RAM (clk,clk,en,en,PR2_wec,PR2_wed,PR2_addrc,PR2_addrd,PR2_dic,PR2_did,PR2_doc,PR2_dod);  
   
    // combinational state polyram MUX    
    always @(*) begin
        // DEFAULTS
        PR1_dia = 16'd0;
        PR1_dib = 16'd0;
        PR2_dic = 16'd0;
        PR2_did = 16'd0;
        PR1_wea = 1'd0;
        PR1_web = 1'd0;
        PR2_wec = 1'd0;
        PR2_wed = 1'd0;
        PR1_addra = 9'd0;
        PR1_addrb = 9'd0;
        PR2_addrc = 9'd0;
        PR2_addrd = 9'd0;
        
        // RAM MUX assignments
        case (keygen_state)
        S1: begin
            PR1_dib = PR_di_ga;
            PR1_web = PR_we_ga;
            PR1_addrb = {A_ADDR, PR_addr_ga};
        end 
        S2: begin
            PR1_dia = PR_di_bs;
            PR1_wea = PR_we_bs;
            PR1_addra = {S_ADDR, PR_addr_bs};
        end
        S3: begin
            PR1_dia = PR_di_pa;
            PR1_wea = PR_we_pa;
            PR1_addra = {S_ADDR, PR_addr_pa};
            
            PR2_dic = PR_di_bs;
            PR2_wec = PR_we_bs;
            PR2_addrc = {E_ADDR, PR_addr_bs};
            
            PR2_addrd = {G_ADDR, PR_addr_pa};
        end
        S4: begin
            PR1_dia = PR_di1_ntt;
            PR1_wea = PR_we1_ntt;
            PR1_addra = {S_ADDR, PR_addr1_ntt};
            
            PR1_dib = PR_di2_ntt;
            PR1_web = PR_we2_ntt;
            PR1_addrb = {S_ADDR, PR_addr2_ntt};
            
            PR2_dic = PR_di_pa;
            PR2_wec = PR_we_pa;
            PR2_addrc = {E_ADDR, PR_addr_pa};
            
            PR2_addrd = {G_ADDR, PR_addr_pa};
        end
        S5: begin
            PR1_dia = PR_di_pa;
            PR1_wea = PR_we_pa;
            PR1_addra = {A_ADDR, PR_addr_pa};
            
            PR1_addrb = {S_ADDR, PR_addr_pa};
            
            PR2_dic = PR_di1_ntt;
            PR2_wec = PR_we1_ntt;
            PR2_addrc = {E_ADDR, PR_addr1_ntt};
            
            PR2_did = PR_di2_ntt;
            PR2_wed = PR_we2_ntt;
            PR2_addrd = {E_ADDR, PR_addr2_ntt};
        end
        S6: begin
            PR1_dia = PR_di_pa;
            PR1_wea = PR_we_pa;
            PR1_addra = {A_ADDR, PR_addr_pa};
            
            PR1_addrb = {S_ADDR, PR_addr_pe};
            
            PR2_addrd = {E_ADDR, PR_addr_pa};
        end
        S7: begin
            PR1_addrb = {A_ADDR, PR_addr_pe};
        end
        endcase
    end    
   
    dual_port_ram #(.MEM_WIDTH(8), .MEM_SIZE(1824)) O_RAM (clk,clk,en,en,OR_wea,OR_web,OR_addra,OR_addrb,OR_dia,OR_dib,OR_doa,OR_dob);

    // combinational state outram MUX    
    always @(*) begin
        // DEFAULTS
        OR_addra = 11'd0;
        OR_addrb = 11'd0;
        OR_wea = 1'd0;
        OR_web = 1'd0;
        OR_dia = 8'd0;
        OR_dib = 8'd0;

        output_do = 8'd0;
        
        case (keygen_state) 
        HOLD: begin
            OR_addra = output_addr;
            output_do = OR_doa;
        end
        S6: begin
            OR_dib = OR_di_pe;
            OR_web = OR_we_pe;
            OR_addrb = {1'd0, OR_addr_pe};
        end
        S7: begin
            OR_dia = OR_di_sm;
            OR_wea = OR_we_sm;
            OR_addra = OR_addr_sm + 11'd1792;
        
            OR_dib = OR_di_pe;
            OR_web = OR_we_pe;
            OR_addrb = {1'd0, OR_addr_pe} + 11'd896;
        end
        endcase
    end


    /* --- SUBMODULE INSTANCES --- */   
    seed_expander SEED_EXP (clk,rst,start_se,done_se,              // control inputs
                    IR_addr_se,IR_we_se,IR_di_se,IR_dob,           // input RAM signals
                    seed_se,reseed_se,reseed_ack,rdi_data,rdi_valid,rdi_ready_se); // Trivium module signals
    
    gen_a GENA(clk, rst, start_ga, done_ga,      // ctrl
                 IR_addr_ga, IR_dob,             // in ram
                 PR_we_ga, PR_addr_ga, PR_di_ga, // out ram
                 seed_ga, reseed_ga, reseed_ack, // trivium 
                 rdi_data, rdi_valid, rdi_ready_ga);      
    
    binomial_sampler SAMPLER(clk, rst, start_bs, // ctrl
                            done_bs, reseed_needed_bs, 
                            IR_addr_bs, IR_doa,             // in ram
                            PR_we_bs, PR_addr_bs, PR_di_bs,  // out ram
                            seed_bs, reseed_bs, reseed_ack,  // trivium 
                            rdi_data, rdi_valid, rdi_ready_bs); 
    
    poly_arithmetic POLY_ARITH1(clk, rst, start_pa, done_pa, op_code_pa, PR_we_pa,
                                PR_addr_pa, PR_do1_pa, PR_do2_pa, PR_di_pa);
   
    ntt NTT(clk, rst, start_ntt, 1'd0, done_ntt, PR_we1_ntt, PR_we2_ntt,
                PR_addr1_ntt, PR_addr2_ntt, PR_di1_ntt, PR_di2_ntt, 
                PR_do1_ntt, PR_do2_ntt);

    seed_mover SEED_MOV (clk, rst, start_sm, done_sm,// control inputs
                        IR_addr_sm, IR_dob,// input RAM signals
                        OR_addr_sm, OR_di_sm, OR_we_sm); // output RAM signals
          
    polynomial_encoder POLY_ENC(clk, rst, start_pe, done_pe, OR_we_pe,
                                OR_addr_pe, OR_di_pe, PR_addr_pe, PR1_dob);
    
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
        keygen_state_next = HOLD;
    
        case (keygen_state) 
        HOLD: begin
            keygen_state_next = (start) ? S0 : HOLD;
        end
        S0: begin
            keygen_state_next = (done_se) ? S1 : S0;
        end
        S1: begin
            keygen_state_next = (done_ga) ? S2 : S1;
        end
        S2: begin
            keygen_state_next = (done_bs) ? S3 : S2;
        end
        S3: begin
            keygen_state_next = (done_bs) ? S4 : S3;
        end
        S4: begin
            keygen_state_next = (done_ntt) ? S5 : S4;
        end
        S5 : begin
            keygen_state_next = (done_ntt) ? S6 : S5;
        end
        S6: begin
            keygen_state_next = (done_pe) ? S7 : S6;
        end
        S7: begin
            keygen_state_next = (done_pe) ? HOLD : S7;
        end
        endcase
    end
    
    // sequential state logic
    always @(posedge clk) begin
        keygen_state <= (rst) ? HOLD : keygen_state_next;
    end
    
    // sequential output logic
    always @(posedge clk) begin
        // defaults
        start_pa <= 1'b0;
        start_ntt <= 1'b0;
        start_ga <= 1'b0;
        start_bs <= 1'b0;
        start_pe <= 1'b0;
        start_sm <= 1'b0;
        start_se <= 1'b0;
        start_pe <= 1'b0;
        
        keygen_done <= 1'b0;
        op_code_pa <= op_code_pa;
    
        case (keygen_state) 
        HOLD: begin
            if (start) begin
                start_se <= 1'b1;
            end
        end
        S0: begin
            if (done_se) begin
                start_ga <= 1'b1;
//                $display("GenA");
            end
        end
        S1: begin
            if (done_ga) begin
                reseed_needed_bs <= 1'b1;
                start_bs <= 1'b1;
//                $display("BS sampling S");
            end
        end
        S2: begin
            
            if (done_bs) begin
                op_code_pa <= 2'd3; // mult_precomp
                start_pa <= 1'b1;
                start_bs <= 1'b1;
//                $display("BS sampling e");
            end
        end
        S3: begin
            
            if (done_bs) begin
                op_code_pa <= 2'd3; // mult_precomp
                start_ntt <= 1'b1;
                start_pa <= 1'b1;
            end
        end
        S4: begin
            
            if (done_ntt) begin
                op_code_pa <= 2'd0; // mult
                start_ntt <= 1'b1;
                start_pa <= 1'b1;
            end
        end
        S5: begin
            
            if (done_ntt) begin
                op_code_pa <= 2'd1; // add
                start_pe <= 1'b1;
                start_pa <= 1'b1;
            end
        end
        S6: begin
            if (done_pe) begin
                start_pe <= 1'b1;
                start_sm <= 1'b1;
            end
        end
        S7: begin
            if (done_pe) begin
                keygen_done <= 1'b1;
            end
        end
        endcase
    end
                
endmodule
