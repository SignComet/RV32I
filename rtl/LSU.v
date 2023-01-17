`timescale 1ns / 1ps

module LSU(
              input                 clk_i,
              input                 arstn_i,          // reset

              //core protocol  load в core
              input         [31:0]  lsu_addr_i,       //  from the processor comes the address of the memory cell to which it wants to appeal
              input                 lsu_we_i, 
              input         [2:0]   lsu_size_i,       // 
              input         [31:0]  lsu_data_i,       // data to be written to memory
              input                 lsu_req_i,        // 1 - memory access signal
              output                lsu_stall_req_o,  // =!enable pc
              output        [31:0]  lsu_data_o,       // data read from memory
              
              //memory protocol  запрошенные данные в rf
              input         [31:0]  data_rdata_i,     // requested data
              output                data_req_o,       // 1 - memory access signal
              output                data_we_o,        // 1 - write
              output        [3:0]   data_be_o,        // which bytes of the word are being accessed
              output        [31:0]  data_addr_o,      // address of the appeal
              output        [31:0]  data_wdata_o,     // data to be written to memory
              input                 en_counter
          );

reg [1:0] count = 0;
always@(posedge clk_i) begin // to raise the signals by only one clock cycle
if(en_counter) begin
  if(count == 2'h1) 
   count  <= 0;
  else
   count <= count + 1;
end
end

assign data_req_o = (lsu_req_i && lsu_we_i  && count == 2'h0) ? lsu_req_i  :    
                    (lsu_req_i && lsu_we_i  && count == 2'h1) ? ~lsu_req_i : 
                    (lsu_req_i && ~lsu_we_i && count == 2'h0) ? lsu_req_i  :
                    (lsu_req_i && ~lsu_we_i && count == 2'h1) ? ~lsu_req_i : 1'bx;
                    
assign data_we_o =  (lsu_req_i && lsu_we_i  && count == 2'h0) ? lsu_we_i   :
                    (lsu_req_i && lsu_we_i  && count == 2'h1) ? ~lsu_we_i  :
                    (lsu_req_i && ~lsu_we_i && count == 2'h0) ? lsu_we_i   :
                    (lsu_req_i && ~lsu_we_i && count == 2'h1) ? lsu_we_i   : 1'bx;
                    
assign lsu_stall_req_o = data_req_o;
                    
assign data_be_o =  ((lsu_size_i  == `LDST_H  &&  (lsu_addr_i%4 == 0 || lsu_addr_i == 0)))               ? 4'b0011 :         
                    ((lsu_size_i  == `LDST_H  && !(lsu_addr_i%4 == 0)))                                  ? 4'b1100 :
                    ((lsu_size_i  == `LDST_HU &&  (lsu_addr_i%4 == 0 || lsu_addr_i == 0)))               ? 4'b0011 : 
                    ((lsu_size_i  == `LDST_HU && !(lsu_addr_i%4 == 0)))                                  ? 4'b1100 : 
                    ((lsu_size_i  == `LDST_B  &&  (lsu_addr_i%4 == 0 || lsu_addr_i == 0)))               ? 4'b0001 :
                    ((lsu_size_i  == `LDST_B  &&  ((lsu_addr_i - 32'd1)%4 == 0 || lsu_addr_i == 32'h1))) ? 4'b0010 :
                    ((lsu_size_i  == `LDST_B  &&  ((lsu_addr_i - 32'd2)%4 == 0 || lsu_addr_i == 32'h2))) ? 4'b0100 :
                    ((lsu_size_i  == `LDST_B  &&  ((lsu_addr_i - 32'd3)%4 == 0 || lsu_addr_i == 32'h3))) ? 4'b1000 :
                    ((lsu_size_i  == `LDST_BU &&  (lsu_addr_i%4 == 0 || lsu_addr_i == 0))  )             ? 4'b0001 :
                    ((lsu_size_i  == `LDST_BU &&  ((lsu_addr_i - 32'd1)%4 == 0 || lsu_addr_i == 32'h1))) ? 4'b0010 :
                    ((lsu_size_i  == `LDST_BU &&  ((lsu_addr_i - 32'd2)%4 == 0 || lsu_addr_i == 32'h2))) ? 4'b0100 :
                    ((lsu_size_i  == `LDST_BU &&  ((lsu_addr_i - 32'd3)%4 == 0 || lsu_addr_i == 32'h3))) ? 4'b1000 :
                    (lsu_size_i   == `LDST_W)                                                            ? 4'b1111 : 4'b0000;  // 0000 - no such combination

assign data_addr_o =  ((lsu_size_i  == `LDST_H || lsu_size_i == `LDST_HU) && data_be_o ==  4'b0011)     ? lsu_addr_i :
                       (lsu_size_i  == `LDST_W && data_be_o ==  4'b1111)                                ? lsu_addr_i :
                       ((lsu_size_i == `LDST_B || lsu_size_i == `LDST_BU) && data_be_o ==  4'b0001)     ? lsu_addr_i :
                       ((lsu_size_i == `LDST_H || lsu_size_i == `LDST_HU) && data_be_o ==  4'b1100)     ? (lsu_addr_i - 32'd2) : 
                       ((lsu_size_i == `LDST_B || lsu_size_i == `LDST_BU) && data_be_o ==  4'b0010)     ? (lsu_addr_i - 32'd1) :
                       ((lsu_size_i == `LDST_B || lsu_size_i == `LDST_BU) && data_be_o ==  4'b0100)     ? (lsu_addr_i - 32'd2) : 
                       ((lsu_size_i == `LDST_B || lsu_size_i == `LDST_BU) && data_be_o ==  4'b1000)     ? (lsu_addr_i - 32'd3) : 32'b0; 
                              
//WORD ADDRESS!!!!!! ADDR_I ADDRESS WITH A SHIFT inside the word
                         
//STORE
assign data_wdata_o =   (data_be_o == 4'b0001 || data_be_o == 4'b0010 || data_be_o == 4'b0100 || data_be_o == 4'b1000 ) ? {4{lsu_data_i[7:0]}}  :
                        (data_be_o == 4'b0011 || data_be_o == 4'b1100)                                                  ? {2{lsu_data_i[15:0]}} :
                        (data_be_o == 4'b1111)                                                                          ? lsu_data_i[31:0]      : 32'b0;

//LOAD                        
assign lsu_data_o  =    (lsu_size_i == `LDST_BU && data_be_o ==  4'b0001) ? {{24{1'b0}}, data_rdata_i[7:0]}               :   
                        (lsu_size_i == `LDST_BU && data_be_o ==  4'b0010) ? {{24{1'b0}}, data_rdata_i[15:8]}              :
                        (lsu_size_i == `LDST_BU && data_be_o ==  4'b0100) ? {{24{1'b0}}, data_rdata_i[23:16]}             :
                        (lsu_size_i == `LDST_BU && data_be_o ==  4'b1000) ? {{24{1'b0}}, data_rdata_i[31:24]}             :
                        (lsu_size_i == `LDST_HU && data_be_o ==  4'b0011) ? {{16{1'b0}}, data_rdata_i[15:0]}              :
                        (lsu_size_i == `LDST_HU && data_be_o ==  4'b1100) ? {{16{1'b0}}, data_rdata_i[31:16]}             :
                        (lsu_size_i == `LDST_W)                           ? data_rdata_i[31:0]                            : 
                        (lsu_size_i == `LDST_B  && data_be_o ==  4'b0001) ? {{24{data_rdata_i[7]}},  data_rdata_i[7:0]}   :  
                        (lsu_size_i == `LDST_B  && data_be_o ==  4'b0010) ? {{24{data_rdata_i[15]}}, data_rdata_i[15:8]}  :
                        (lsu_size_i == `LDST_B  && data_be_o ==  4'b0100) ? {{24{data_rdata_i[23]}}, data_rdata_i[23:16]} :
                        (lsu_size_i == `LDST_B  && data_be_o ==  4'b1000) ? {{24{data_rdata_i[31]}}, data_rdata_i[31:24]} :       
                        (lsu_size_i == `LDST_H  && data_be_o ==  4'b0011) ? {{16{data_rdata_i[15]}}, data_rdata_i[15:0]}  : 
                        (lsu_size_i == `LDST_H  && data_be_o ==  4'b1100) ? {{16{data_rdata_i[31]}}, data_rdata_i[31:16]} : 32'b0;
 
 
endmodule

/* before

module instr_mem(
                    input  [31:0] A,
                    output [31:0] RD
                );

reg [31:0] RAM1 [0:63];
initial $readmemh ("instr.txt", RAM1);
assign  RD = RAM1[A/4]; //тк работали построчно по instr.txt
 
endmodule

module data_mem(    
                    input         clk,
                    input         WE,
                    input  [31:0] A,
                    input  [31:0] WD, 
                    output [31:0] RD
                );

reg [31:0] RAM [0:63];
assign RD =  RAM[A];

always@ (posedge clk)
if (WE) 
  RAM[A] <= WD; 
 
endmodule
*/
