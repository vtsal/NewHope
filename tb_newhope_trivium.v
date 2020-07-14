`timescale 1ns / 1ps
`define P 10
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/06/2020 09:53:05 PM
// Design Name: 
// Module Name: tb_newhope_trivium
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


module tb_newhope_trivium;
    reg clk, rst_enc, start_enc, rst_key, en_key, start_key;
    wire done_enc, done_key;
    
    
    // input signals
    reg [31:0] input_dia_key;
    reg input_wea_key;
    reg [3:0] input_addra_key;
    
    // output signals
    reg [10:0] output_addr_key;
    wire [7:0] output_do_key;
    
    keygen KEYGEN(
        clk,
        rst_key,
        en_key,
        // control signals
        start_key,
        done_key,    
        // byte data input
        input_dia_key,
        input_wea_key,
        input_addra_key,
        // output (size mismatch with input should be fixed)
        output_addr_key, 
        output_do_key
    );
    
    reg [31:0] input1_dia_enc;
    reg input1_wea_enc, input2_wea_enc;
    reg [4:0] input1_addra_enc;
    reg [7:0] input2_dia_enc;
    reg [9:0] input2_addra_enc;
    reg [10:0] output_addr_enc;
    wire [7:0] output_do_enc;
    
    encrypter ENC(
        clk,
        rst_enc,
        // control signals
        start_enc,
        done_enc,    
        // byte data input
        input1_dia_enc,
        input1_wea_enc,
        input1_addra_enc,
        input2_dia_enc,
        input2_wea_enc,
        input2_addra_enc,
        // output byte data
        output_addr_enc, 
        output_do_enc
        );

    reg rst_dec, start_dec;
    wire done_dec;

    // input signals
    reg [7:0] input_dia_dec;
    reg input_wea_dec;
    reg [10:0] input_addra_dec;
    
    // output signals
    reg [2:0] output_addr_dec;
    wire [31:0] output_do_dec;

    decrypter DEC(
        clk,
        rst_dec,
        // control signals
        start_dec,
        done_dec,    
        // byte data input
        input_dia_dec,
        input_wea_dec,
        input_addra_dec,
        // output (size mismatch with input should be fixed)
        output_addr_dec, 
        output_do_dec
        );

    // test vectors
    reg [511:0] testvectors [9:0];
    reg [0:255] coin, m, seed;
    integer test_num, error_count, match_count, total_errors;
    integer k;
    reg [31:0] out_check, buffer32;    
    
    initial begin
        total_errors = 0;
        match_count = 0;
        error_count = 0;
    
        // initialize signals to zero
        clk = 0;
        input1_dia_enc = 0;
        input1_wea_enc = 0;
        input2_wea_enc = 0;
        input1_addra_enc = 0;
        input2_dia_enc = 0;
        input2_addra_enc = 0;
        output_addr_enc = 0;
        start_dec = 0;
        start_enc = 0;
        input_dia_dec = 0;
        input_wea_dec = 0;
        input_addra_dec = 0;
        output_addr_dec = 0;
        buffer32 = 0;
        
        // keygen signals
        en_key = 0; 
        start_key = 0;    
    
        input_dia_key = 32'd0;
        input_wea_key = 0;
        input_addra_key = 4'd0;
    
        // output signals
        output_addr_key = 10'd0;
        
        test_num = 0;
        error_count = 0;
        match_count = 0;
        total_errors = 0;
        
        rst_enc = 1'b1; rst_dec = 1'b1; rst_key = 1'b1; #(`P); 
        rst_enc = 1'b0; rst_dec = 1'b0; rst_key = 1'b0; #(`P); 
        
        
        
        // Hardcoded test values:
//        seed = 256'h7C9935A0B0769FAA0C6D10E4DB6B1ADD2FD81A25CCB148032DCD739936737F2D;
//        coin = 256'hA056B4E015FD9EB0237338FB0EFCC59556D9656EDA3A4AEC68F1F2E7B083DF78;
        m = 256'h000102030405060708090a0b0c0d0E0f101112131415161718191a1b1c1d1e1f;
        
        // read in test data
        $readmemh("D:/programming/NewHopeTrivium/NewHopeCrypto/newhope_tv.txt", testvectors);
        #(`P);
         for (test_num = 0; test_num < 10; test_num=test_num+1) begin
            seed = testvectors[test_num][511:256];
            coin = testvectors[test_num][255:0];
         
            @ (negedge clk);
         
            // 1) KEY GENERATION
            en_key = 1'b1; #(`P);
            for (k = 0; k < 8; k = k + 1) begin
                input_addra_key = k;
                input_dia_key = seed[k*32+:32];
                #(`P); input_wea_key = 1'b1; #(`P); input_wea_key = 1'b0; #(`P);
            end
        
            $display("Start KeyGen"); 
            start_key = 1'b1; #(`P);  start_key = 1'b0; #(`P); 
            while (done_key != 1) #(`P);
            rst_key = 1'b1; #(`P); rst_key = 1'b0; #(`P); 
            $display("KeyGen done"); 
        
            // 2) ENCRYPTION
            // load coin           
            for (k = 0; k < 8; k = k + 1) begin
                input1_addra_enc = k;
                input1_dia_enc = coin[k*32+:32];
                input1_wea_enc = 1'b1; #(`P); input1_wea_enc = 1'b0; #(`P);
            end
            // load pubseed           
            for (k = 0; k < 32; k = k + 4) begin
                output_addr_key = k + 11'd1792; #(`P);
                buffer32[7:0] = output_do_key; #(`P);
                
                output_addr_key = k + 11'd1793; #(`P);
                buffer32[15:8] = output_do_key; #(`P);
                
                output_addr_key = k + 11'd1794; #(`P);
                buffer32[23:16] = output_do_key; #(`P);
                
                output_addr_key = k + 11'd1795; #(`P);
                buffer32[31:24] = output_do_key; #(`P);
                
                input1_addra_enc = (k>>2)+8;
                input1_dia_enc = buffer32;
                input1_wea_enc = 1'b1; #(`P); input1_wea_enc = 1'b0; #(`P);
                
            end
            // load m    
            for (k = 0; k < 8; k = k + 1) begin
                input1_addra_enc = k+16;
                input1_dia_enc = m[k*32+:32];
                input1_wea_enc = 1'b1; #(`P); input1_wea_enc = 1'b0; #(`P);
            end
            // load pk
            for (k = 0; k < 896; k = k + 1) begin
                output_addr_key = k + 11'd896; #(`P);
        
                input2_addra_enc = k;
                input2_dia_enc = output_do_key;
                input2_wea_enc = 1'b1; #(`P); input2_wea_enc = 1'b0; #(`P);
 
            end
            
            en_key = 1'b0; #(`P);
            $display("Start Encryption"); 
            rst_enc = 1'b1; #(`P); rst_enc = 1'b0; #(`P); 
            start_enc = 1'b1; #(`P);  start_enc = 1'b0; #(`P); 
            while (done_enc != 1) #(`P);
            $display("Encryption done"); 
            
            
            // 3) DECRYPTION
            // load ct into decrypter
            for (k = 0; k < 1088; k = k + 1) begin
                output_addr_enc = k; #(`P);
                input_addra_dec = k;
                input_dia_dec = output_do_enc;
                input_wea_dec = 1'b1; #(`P); input_wea_dec = 1'b0; #(`P);
            end
            
            // 5) load sk into decrypter
            en_key = 1'b1; #(`P);
            for (k = 0; k < 896; k = k + 1) begin
                output_addr_key = k; #(`P);
            
                input_addra_dec = k + 1088;
                input_dia_dec = output_do_key;
                input_wea_dec = 1'b1; #(`P); input_wea_dec = 1'b0; #(`P);
            end
            en_key = 1'b0; #(`P);
            
            $display("Start Decryption"); 
            rst_dec = 1'b1; #(`P); rst_dec = 1'b0; #(`P);
            start_dec = 1'b1; #(`P);  start_dec = 1'b0; #(`P); 
            while (done_dec != 1) #(`P);
            $display("Decryption done"); 
            
            
            // 4) CHECK RESULTS
            #(`P);
            error_count = 0;
            match_count = 0;
            for (k = 0; k < 8; k=k+1) begin
                out_check = m[k*32+:32];
                output_addr_dec = k; #(`P);
                if (out_check !== output_do_dec) begin
                    error_count = error_count  + 1;
                    $display("Error at entry %d: %h %h", k, out_check, output_do_dec); 
                    total_errors = total_errors + 1;
                end
                else begin
                    match_count = match_count  + 1;
                    $display("Match at entry %d: %h %h", k, out_check, output_do_dec);
                end
                
                #(`P);
            end
            $display("Done checking test %d. Correct: %d, Errors: %d", test_num, match_count, error_count);
        end
            


        $display("Total errors: %d", total_errors);
        
        $finish;
    end
    
    always #(`P/2) clk = ~ clk;

endmodule
`undef P