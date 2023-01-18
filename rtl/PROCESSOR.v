`timescale 1ns / 1ps

module PROCESSOR(
                    input                 clk_i,
                    input                 arstn_i,
        
                    input         [31:0]  instr_rdata_i, //  instr
                    output        [31:0]  instr_addr_o,  //  pc
                    
                    input         [31:0]  data_rdata_i,  // data from memory
                    output                data_req_o,
                    output                data_we_o, 
                    output        [3:0]   data_be_o,
                    output        [31:0]  data_addr_o,
                    output        [31:0]  data_wdata_o,
                    input                 INT_i,         // happened interrupt
                    input         [31:0]  mcause_i,      
                    output                INT_RST_o,     // interrupt processed
                    output        [5:0]   mie_o,         // mask
                    input                 flag_mret
                );
wire en_int_rst;
reg en_pc;

wire [31:0] pc;       
wire [31:0] instr;
wire [31:0] instr_new;      
wire        lsu_stall_req_o;                             // pause counter                                 
wire [1:0]  srcA;
wire [2:0]  srcB;
wire [4:0]  aop; 
wire        mem_req_o;
wire        mwe;
wire [2:0]  mem_size_o; 
wire        rfwe;  
wire        ws;
wire        illegal_instr; 
wire        branch;
wire        jal;
wire [1:0]  jalr;
wire        csr;
wire [2:0]  CSRop;

always@* begin
if(instr_rdata_i === 32'hx) 
  en_pc = 1'b0;
else if (mem_req_o)
  en_pc = !lsu_stall_req_o;
else en_pc = 1'b1;
end

//assign en_pc = (instr_rdata_i === 32'x) ? 1'b0 :  ((mem_req_o) ? !lsu_stall_req_o : 1;       // pause counter

//program counter
PC pcc (clk_i, arstn_i, en_pc, jalr, instr_new, pc);
assign instr_addr_o = pc;

//decoder
wire [31:0]  mepc_csr;
wire en_mepc;
wire en_counter_lsu;
main_decoder decoder (instr_rdata_i, srcA, srcB, aop, mem_req_o, mwe, mem_size_o, rfwe, ws, illegal_instr, branch, jal, jalr, CSRop, INT_i, INT_RST_o, csr, en_int_rst, pc, mepc_csr,en_mepc, en_counter_lsu, flag_mret);            
    
wire [31:0] rd1;
wire [31:0] rd2;
wire [31:0] mux_ws;
wire [31:0] mux_wd3;
//register file
RF           rf (clk_i, instr_rdata_i[19:15], instr_rdata_i[24:20], instr_rdata_i[11:7], rfwe, mux_wd3, rd1, rd2);


wire [31:0] mtvec;
wire [31:0] mepc;
wire [31:0] rd_csr;  
//control and status registers
CSR          csr_ (clk_i, CSRop, mcause_i, pc, instr_rdata_i[31:20], rd1, mie_o, mtvec, mepc, rd_csr, en_int_rst, en_mepc, mepc_csr);

wire [31:0] mux_srcA;
wire [31:0] mux_srcB;
//the first operand ALU
assign mux_srcA = (srcA == 2'b00)  ? rd1     :
                  (srcA == 2'b01)  ? pc      :
                  (srcA == 2'b10)  ? 32'h0   : 32'h0;
                  
wire [31:0] imm_I = {{20{instr_rdata_i[31]}}, instr_rdata_i[31:20]};  
wire [31:0] imm_S = {{20{instr_rdata_i[31]}}, instr_rdata_i[31:25], instr_rdata_i[11:7]};  
wire [31:0] imm_J = {{11{instr_rdata_i[31]}}, instr_rdata_i[31], instr_rdata_i[19:12], instr_rdata_i[20], instr_rdata_i[30:21], 1'b0};  
wire [31:0] imm_B = {{19{instr_rdata_i[31]}}, instr_rdata_i[31], instr_rdata_i[7], instr_rdata_i[30:25], instr_rdata_i[11:8], 1'b0};                                   

//the second operand ALU
assign mux_srcB = (srcB == 3'b000) ? rd2                               :
                  (srcB == 3'b001) ? imm_I                             :
                  (srcB == 3'b010) ? {instr_rdata_i[31:12],{12{1'b0}}} :
                  (srcB == 3'b011) ? imm_S                             :
                  (srcB == 3'b100) ? 32'h4                             : 32'h0;
                  
wire [31:0] alu_res;
wire        comp;
//ALU
ALU         alu (mux_srcA, mux_srcB, aop, alu_res, comp);

wire [31:0] rd;
LSU lsu (clk_i, arstn_i, alu_res, mwe, mem_size_o, rd2, mem_req_o, lsu_stall_req_o, rd, data_rdata_i,  data_req_o, data_we_o, data_be_o, data_addr_o, data_wdata_o, en_counter_lsu );

//WD3 â RF
assign mux_ws = (ws) ? rd : alu_res;

assign mux_wd3 = (csr) ? rd_csr : mux_ws;

//for pc
wire [31:0] sum;
wire [31:0] mux_branch;
wire [31:0] mux_jal;
assign mux_branch = (branch) ? imm_B : imm_J; 
assign mux_jal = (jal || (comp && branch)) ? mux_branch : 32'h4; 
assign instr_new = (jalr == 2'b00) ? mux_jal     :
                   (jalr == 2'b01) ? rd1 + imm_I :  
                   (jalr == 2'b10) ? mepc        :
                   (jalr == 2'b11) ? mtvec       : 32'b0; 
 
endmodule
