module ntt(
    // basic control signals
    input clk,
    input rst,
    input start,
    input inverse,
    output reg done,
    // Poly RAM access signals
    output ram_wea,
    output ram_web,
    output wire [8:0] ram_addra,
    output wire [8:0] ram_addrb,
    output [15:0] ram_dia,
    output [15:0] ram_dib,
    input [15:0] ram_doa,
    input [15:0] ram_dob
    );

   // FSM states
   localparam 
     Swait         = 2'd0, // loading values through CI data lines
     Sbitrev       = 2'd1,
     Snttload      = 2'd2, // running NTT
     Snttunload    = 2'd3;
   reg  [1:0] state, state_next;  
   
   localparam PIPELINE_LENGTH = 3'd7;
   reg last_bf_loaded;
   
   /* --- reg and wire definitions --- */
   reg [7:0] bf_num;
   reg [3:0] layer_num;
   
   // bf address module wires
   wire [8:0] addr_a, addr_pair;
   
   // omega module wires
   wire [15:0] omega;
   
   // butterfly module wires
   reg bf_load, bf_en;
   wire [15:0] bf_a, bf_b;
   wire bf_valid;
   
   // Shift register module wires
   wire [8:0] addr_a_w, addr_pair_w;
   
   // bitrev wires
   reg bitrev_write;
   reg [8:0] bitrev_addr_a;
   wire [8:0] bitrev_addr_pair;
   reg bitrev_ram_we;
   
   // control registers
   reg [2:0] count;
   assign ram_wea = (state == Sbitrev & bitrev_addr_a != bitrev_addr_pair) ? bitrev_ram_we : 
                    (state == Snttunload) ? 1'b1 : 1'b0;
   assign ram_web = (state == Sbitrev & bitrev_addr_a != bitrev_addr_pair) ? bitrev_ram_we : 
                    (state == Snttunload) ? 1'b1 : 1'b0;
   assign ram_addra = (state == Sbitrev) ? bitrev_addr_a :
                       (state == Snttunload) ? addr_a_w : addr_a;
   assign ram_addrb = (state == Sbitrev) ? bitrev_addr_pair : 
                        (state == Snttunload) ? addr_pair_w : addr_pair;
   assign ram_dia = (state == Sbitrev) ? ram_dob : bf_a;
   assign ram_dib = (state == Sbitrev) ? ram_doa : bf_b;
   
   /*--- module instances --- */
   
   // calculates current address
   bf_addr addr_module(layer_num, bf_num, addr_a, addr_pair);
   
   // fetches appropriate omega value
   omega_lut omega_module(clk, layer_num, bf_num, inverse, omega);
   
   // performs calculation
   butterfly bf(clk, rst, ram_doa, ram_dob, omega, bf_load, bf_en, bf_a, bf_b, bf_valid);
    
   // stores addresses for BF output storage
   shift_registers_addr addr_sr (clk, 1'b1, {addr_a, addr_pair}, {addr_a_w, addr_pair_w});
   
   // bitreversal address map
   bitrev_map bitrev(bitrev_addr_a, bitrev_addr_pair);
    
    // combinational state logic
   always @(*) begin
      state_next = state;
      case (state)
      Swait: begin
        state_next = (start == 1'b1 & inverse == 1'b0) ? Snttload :
        (start == 1'b1 & inverse == 1'b1) ? Sbitrev : Swait;
      end
      Sbitrev: begin
        state_next = (bitrev_addr_a == 9'd511) ? Snttload : Sbitrev;
      end
      Snttload: begin
        state_next = (done == 1'd1) ? Swait
                        : (count < PIPELINE_LENGTH) ? Snttload
                        : Snttunload;
      end
      Snttunload: begin  
        state_next = (done == 1'd1) ? Swait 
                    : (count < PIPELINE_LENGTH) ? Snttunload : Snttload;      
      end
      endcase
   end

   // Synchronous state logic
   always @(posedge clk) begin
      state <= (rst) ? Swait : state_next;
   end   
   
   // synchronous output logic
   always @(posedge clk) begin
      // defaults
      done <= 1'b0;
      count <= 4'd0;
      
      bf_en <= 1'b0;
      bf_load <= 1'b0;
      bf_num <= bf_num;
      layer_num <= layer_num;
      bitrev_ram_we <= 1'b0;
      bitrev_addr_a <= 9'd0;
      bitrev_write <= 1'b0;
      last_bf_loaded <= 1'b0;

      if (rst == 1'b1) begin
         bf_num <= 8'd0; 
         layer_num <= 4'd0; 
      end else begin
          case (state)
          Swait: begin
             layer_num <= 4'd0;
             bf_num <= 8'd0;
          end
          Sbitrev: begin
             // alternate writing and reading
             if (bitrev_write == 1'b1) begin
                 bitrev_addr_a <= bitrev_addr_a;
                 bitrev_ram_we <= (bitrev_addr_a != 9'd0 & bitrev_addr_pair == 9'd0) ? 1'b0 : 1'b1;
                 bitrev_write <= 1'b0;
             end else begin
                bitrev_addr_a <= bitrev_addr_a + 9'd1;
                bitrev_ram_we <= 1'b0;
                bitrev_write <= 1'b1;
             end
          end
          Snttload: begin
            bf_en <= 1'b1;
            if (count < PIPELINE_LENGTH) begin
                bf_load <= 1'b1;
            end
            
            bf_num <= (bf_num == 255) ? 8'd0 : bf_num + 8'd1;
            layer_num <= (bf_num == 255) ? layer_num + 8'd1 : layer_num;
            last_bf_loaded <= (bf_num == 8'd255 && layer_num == 4'd8) ? 1'b1 : 1'b0;
            count <= count + 1; 
          end
          Snttunload: begin
            bf_en <= 1'b1;
            if (count <= PIPELINE_LENGTH) begin
                bf_en <= 1'b1;
                count <= count + 1;
            end  
            last_bf_loaded <= last_bf_loaded;
            done <= (~bf_valid && last_bf_loaded) ? 1'b1 : 1'b0;
          end
          endcase
      end         
   end
   
endmodule