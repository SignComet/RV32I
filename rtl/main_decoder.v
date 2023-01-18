`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

`include "define.v"

module main_decoder(    
                        input      [31:0]                fetched_instr_i, // instr
                        output reg [1:0]                 ex_op_a_sel_o,   // sel mux of first operand ALU 
                        output reg [2:0]                 ex_op_b_sel_o,
                        output reg [`ALU_OP_WIDTH-1 : 0] alu_op_o,
                        output reg                       mem_req_o,       // memory access
                        output reg                       mem_we_o,        // 0 - read 1 - write memory
                        output reg [2:0]                 mem_size_o,      // size of word 
                        output reg                       gpr_we_a_o,      // 0 - read 1 - write RF
                        output reg                       wb_src_sel_o,    // sel mux for data into rf
                        output                           illegal_instr_o, 
                        output reg                       branch_o,        // 
                        output reg                       jal_o,           // JAL rd, offset           ( The return address is also saved in rd)     
                        output reg [1:0]                 jalr_o,          // JALR rd, offset(rs1)     ( The return address is also saved in rd)        
                        output     [2:0]                 CSROop,           
                        input                            INT_,            // happened interrupt
                        output reg                       INT_RST,
                        output                           csr,
                        input                            en_int_rst,
                        input      [31:0]                mepc_pc,
                        output     [31:0]                mepc_csr,
                        output                           en_mepc,
                        output                           en_counter_lsu,
                        output  reg                      flag_mret
                 );
assign  en_counter_lsu = (fetched_instr_i[6:2] == `LOAD_OPCODE || fetched_instr_i[6:2] == `STORE_OPCODE || fetched_instr_i[6:2] == `SYSTEM_OPCODE);
assign  mepc_csr = (INT_) ? mepc_pc : 1'b0;
assign  en_mepc  =  (INT_) ? 1'b1 : 1'b0;
initial INT_RST  = 1'b1;

//R-type
wire [6:0] funct7_R    =  fetched_instr_i[31:25];
wire [2:0] funct3_RISB =  fetched_instr_i[14:12]; //for SYSTEM too

//SYSTEM
assign csr = (funct3_RISB == 3'b000 && fetched_instr_i[6:2] == `SYSTEM_OPCODE) ? 1'b0  :
             (fetched_instr_i[6:2] == `SYSTEM_OPCODE) ? 1'b1  : 1'b0;  

assign CSROop[2]   =    (funct3_RISB == 3'b000 && fetched_instr_i[6:2] == `SYSTEM_OPCODE || INT_ ) ? 1'b1 : 1'b0;
assign CSROop[1:0] =    (funct3_RISB == 3'b001 && fetched_instr_i[6:2] == `SYSTEM_OPCODE) ? 2'b01 : 
                        (funct3_RISB == 3'b010 && fetched_instr_i[6:2] == `SYSTEM_OPCODE) ? 2'b11 :
                        (funct3_RISB == 3'b011 && fetched_instr_i[6:2] == `SYSTEM_OPCODE) ? 2'b10 : 2'h0;
 
wire [`ALU_OP_WIDTH-1 : 0] ALU_operation;
wire [`ALU_OP_WIDTH-1 : 0] ALU_operation_i;
wire [`ALU_OP_WIDTH-1 : 0] ALU_operation_branch;
wire [2:0] mem_size_IS;
wire [2:0] mem_size_IS_store;

assign ALU_operation =        (funct7_R == 7'b0)  && (funct3_RISB == 3'b0) ? `ALU_ADD  :
                              (funct7_R == 7'h20) && (funct3_RISB == 3'b0) ? `ALU_SUB  : 
                              (funct7_R == 7'b0)  && (funct3_RISB == 3'h4) ? `ALU_XOR  : 
                              (funct7_R == 7'b0)  && (funct3_RISB == 3'h6) ? `ALU_OR   : 
                              (funct7_R == 7'b0)  && (funct3_RISB == 3'h7) ? `ALU_AND  : 
                              (funct7_R == 7'b0)  && (funct3_RISB == 3'h1) ? `ALU_SLL  : 
                              (funct7_R == 7'b0)  && (funct3_RISB == 3'h5) ? `ALU_SRL  :
                              (funct7_R == 7'h20) && (funct3_RISB == 3'h5) ? `ALU_SRA  : 
                              (funct7_R == 7'b0)  && (funct3_RISB == 3'h2) ? `ALU_SLTS : 
                              (funct7_R == 7'b0)  && (funct3_RISB == 3'h3) ? `ALU_SLTU : 5'b01110; //01110 not used!
                       

assign ALU_operation_i =      (funct3_RISB == 3'b0) ? `ALU_ADD                         :
                              (funct3_RISB == 3'h4) ? `ALU_XOR                         : 
                              (funct3_RISB == 3'h6) ? `ALU_OR                          : 
                              (funct3_RISB == 3'h7) ? `ALU_AND                         : 
                              (funct7_R == 7'b0)  && (funct3_RISB == 3'h1) ? `ALU_SLL  : 
                              (funct7_R == 7'b0)  && (funct3_RISB == 3'h5) ? `ALU_SRL  :
                              (funct7_R == 7'h20) && (funct3_RISB == 3'h5) ? `ALU_SRA  : 
                              (funct3_RISB == 3'h2) ? `ALU_SLTS                        : 
                              (funct3_RISB == 3'h3) ? `ALU_SLTU                        : 5'b01110; //01110 not used!

assign ALU_operation_branch = (funct3_RISB == 3'b0) ? `ALU_EQ  :
                              (funct3_RISB == 3'h1) ? `ALU_NE  : 
                              (funct3_RISB == 3'h4) ? `ALU_LTS : 
                              (funct3_RISB == 3'h5) ? `ALU_GES : 
                              (funct3_RISB == 3'h6) ? `ALU_LTU : 
                              (funct3_RISB == 3'h7) ? `ALU_GEU : 5'b01110; //01110 not used!
                              
assign mem_size_IS =          (funct3_RISB == 3'b0) ? `LDST_B  :                          
                              (funct3_RISB == 3'h1) ? `LDST_H  : 
                              (funct3_RISB == 3'h2) ? `LDST_W  : 
                              (funct3_RISB == 3'h4) ? `LDST_BU : 
                              (funct3_RISB == 3'h5) ? `LDST_HU : 3'b111; //111 not used!

assign mem_size_IS_store =    (funct3_RISB == 3'b0) ? `LDST_B  :                          
                              (funct3_RISB == 3'h1) ? `LDST_H  : 
                              (funct3_RISB == 3'h2) ? `LDST_W  : 3'b111; //111 not used!
                              

reg illegal = 1'b0;   
 
always@(*)
begin        
if (en_int_rst) INT_RST  =  1'b1;
else INT_RST  =  1'b0;

if(INT_) begin 
                      gpr_we_a_o    =  1'b1;                    
                      mem_req_o     =  1'b0;                 
                      alu_op_o      = `ALU_ADD; // nop;     //  PC += imm
                      ex_op_a_sel_o = `OP_A_CURR_PC;  
                      ex_op_b_sel_o = `OP_B_INCR;            
                      wb_src_sel_o  = `WB_EX_RESULT;       
                    
                      mem_we_o      =  1'b0;
                      mem_size_o    =  3'b0; 		// it doesn't matter
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'h3; 		// mtvec
                      INT_RST       =  1'b0;
                      flag_mret     = 1'b0;
                      
          end

else begin
if(flag_mret)INT_RST =  1'b0;
flag_mret =  1'b0;
case (fetched_instr_i[6:2])
     `OP_OPCODE:    begin           // R-type
                      gpr_we_a_o    =  1'b1;            // write to a RF
                      mem_req_o     =  1'b0;            // it doesn't matter    
                      alu_op_o      =  ALU_operation;
                      ex_op_a_sel_o = `OP_A_RS1; 
                      ex_op_b_sel_o = `OP_B_RS2;
                      wb_src_sel_o  = `WB_EX_RESULT;    // result from alu to rf
                                          
                      mem_we_o      =  1'b0;            //  it doesn't matter
                      mem_size_o    =  3'b0;            //  it doesn't matter, no memory access
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0;
                    end
                    
    `OP_IMM_OPCODE: begin           // I-type
                      gpr_we_a_o    =  1'b1;            // write to a RF 
                      mem_req_o     =  1'b0;            // it doesn't matter             
                      alu_op_o      =  ALU_operation_i;
                      ex_op_a_sel_o = `OP_A_RS1; 
                      ex_op_b_sel_o = `OP_B_IMM_I;
                      wb_src_sel_o  = `WB_EX_RESULT;    // result from alu to rf
                    
                      mem_we_o      =  1'b0;            // it doesn't matter 
                      mem_size_o    =  3'b0;            // it doesn't matter
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0;  
                    end
                    
    `LUI_OPCODE:    begin           // U-type            // lui xn const == rd == imm << 12  
                      gpr_we_a_o    =  1'b1;             // write to RF
                      mem_req_o     =  1'b0;             // it doesn't matter    
                      alu_op_o      = `ALU_ADD;          // +0
                      ex_op_a_sel_o = `OP_A_ZERO;        // 0
                      ex_op_b_sel_o = `OP_B_IMM_U;
                      wb_src_sel_o  = `WB_EX_RESULT;     // result from ALU to RF 
                    
                      mem_we_o      =  1'b0;             // it doesn't matter
                      mem_size_o    =  3'b0;             // it doesn't matter
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0; 
                    end    
                                                        
    `LOAD_OPCODE:   begin           // I-type             lw xN(from mem to rf), offset(base) 
                      gpr_we_a_o    =  1'b1;              // WRITE to RF
                      mem_req_o     =  1'b1;                  
                      alu_op_o      = `ALU_ADD;           // rs1+imm
                      ex_op_a_sel_o = `OP_A_RS1; 
                      ex_op_b_sel_o = `OP_B_IMM_I;
                      wb_src_sel_o  = `WB_LSU_DATA;       // result from ALU to RF 
                    
                      mem_we_o      =  1'b0;              // READ from men
                      mem_size_o    =  mem_size_IS;
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0;
                    end
    
    `STORE_OPCODE:  begin           // S-type              // sw xN(from to mem), offset(base)
                      gpr_we_a_o    =  1'b0;               // READ
                      mem_req_o     =  1'b1;                 
                      alu_op_o      = `ALU_ADD;            // rs1+imm
                      ex_op_a_sel_o = `OP_A_RS1; 
                      ex_op_b_sel_o = `OP_B_IMM_S;         // the constant is stored in two fields
                      wb_src_sel_o  =  1'b0;               // it doesn't matter, does not write to RF
                    
                      mem_we_o      =  1'b1;               // WRITE
                      mem_size_o    =  mem_size_IS_store;
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0; 
                    end
                    
    `BRANCH_OPCODE: begin           // B-type              
                      gpr_we_a_o    =  1'b0;                    
                      mem_req_o     =  1'b0;               // it doesn't matteríî     
                      alu_op_o      =  ALU_operation_branch;    
                      ex_op_a_sel_o = `OP_A_RS1;  
                      ex_op_b_sel_o = `OP_B_RS2; 
                      wb_src_sel_o  =  1'b0;                // it doesn't matter 
                    
                      mem_we_o      =  1'b0;                // it doesn't matter   
                      mem_size_o    =  3'b0;                // it doesn't matter   
                      branch_o      =  1'b1; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0; 
                    end   
   
    `JAL_OPCODE:    begin           // J-type                
                      gpr_we_a_o    =  1'b1;                    
                      mem_req_o     =  1'b0;                 // it doesn't matter   
                      alu_op_o      = `ALU_ADD;              // PC += imm
                      ex_op_a_sel_o = `OP_A_CURR_PC;  
                      ex_op_b_sel_o = `OP_B_INCR; 
                      wb_src_sel_o  = `WB_EX_RESULT;        
                    
                      mem_we_o      =  1'b0;                 // it doesn't matter   
                      mem_size_o    =  3'b0;                 // it doesn't matter   
                      branch_o      =  1'b0; 
                      jal_o         =  1'b1;
                      jalr_o        =  2'b0;  
                    end   
    
    `JALR_OPCODE:   begin           // I-type                
                      gpr_we_a_o    =  1'b1;                    
                      mem_req_o     =  1'b0;                 // it doesn't matter   
                      alu_op_o      = `ALU_ADD;               
                      ex_op_a_sel_o = `OP_A_CURR_PC;  
                      ex_op_b_sel_o = `OP_B_INCR;            
                      wb_src_sel_o  = `WB_EX_RESULT;       
                    
                      mem_we_o      =  1'b0;                 // it doesn't matter      
                      mem_size_o    =  3'b0;                 // it doesn't matter   
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b1; 
                    end 
    
    `AUIPC_OPCODE:  begin           // U-type                 // auipc xn label   rd == PC +(imm << 12)  
                      gpr_we_a_o    =  1'b1;                  // write to RF
                      mem_req_o     =  1'b0;                  // it doesn't matter
                      alu_op_o      = `ALU_ADD;                
                      ex_op_a_sel_o = `OP_A_CURR_PC; 
                      ex_op_b_sel_o = `OP_B_IMM_U;
                      wb_src_sel_o  = `WB_EX_RESULT;          // result from ALU to RF 
                    
                      mem_we_o      =  1'b0;                  // it doesn't matter  
                      mem_size_o    =  3'b0;                  // it doesn't matter  
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0;
                    end    
    
    
  `MISC_MEM_OPCODE: begin           // I-type  	NOP     
                      gpr_we_a_o    =  1'b0;                    
                      mem_req_o     =  1'b0;                 
                      alu_op_o      = `ALU_ADD;               //////////nop;              
                      ex_op_a_sel_o =  2'b0;  
                      ex_op_b_sel_o =  3'b0;            
                      wb_src_sel_o  =  1'b0;       
                    
                      mem_we_o      =  1'b0;
                      mem_size_o    =  3'b0; 
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0;  
                    end                               
    
    `SYSTEM_OPCODE : begin           // I-type    for CSR
    if(funct3_RISB == 3'b000)
    begin  //MRET
                      gpr_we_a_o    =  1'b1;                    
                      mem_req_o     =  1'b0;                 // it doesn't matter 
                      alu_op_o      = `ALU_ADD;              //////////nop;  
                      ex_op_a_sel_o = `OP_A_CURR_PC;  
                      ex_op_b_sel_o = `OP_B_INCR;            
                      wb_src_sel_o  = `WB_EX_RESULT;       
                    
                      mem_we_o      =  1'b0;                 // it doesn't matter  
                      mem_size_o    =  3'b0;                 // it doesn't matter 
                      branch_o      =  1'b0;  
                      jal_o         =  1'b0;                
                      jalr_o        =  2'h2;                 // pc = mepc
                      INT_RST       =  1'b1;
                      flag_mret     =  1'b1;
    end
    else if(funct3_RISB == 3'b001 || funct3_RISB == 3'b010 || funct3_RISB == 3'b011)
    begin  //CSRRW //CSRRS //CSRRC     
                      gpr_we_a_o    =  1'b1;                 // rd = csr  // WRITE to RF
                      mem_req_o     =  1'b1;                  
                      alu_op_o      = `ALU_ADD;              // rs1+imm
                      ex_op_a_sel_o = `OP_A_RS1; 
                      ex_op_b_sel_o = `OP_B_IMM_I;
                      wb_src_sel_o  = `WB_LSU_DATA;         
                    
                      mem_we_o      =  1'b0;                 // READ
                      mem_size_o    =  mem_size_IS;
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0; 
                      INT_RST       =  1'b0;
                      flag_mret     =  1'b0;
     
     end 
                     end                
 default: begin
                      illegal       = 1'b1;  
                               //nop
                      gpr_we_a_o    =  1'b0;                    
                      mem_req_o     =  1'b0;                 
                      alu_op_o      = `ALU_ADD;               // nop;              
                      ex_op_a_sel_o =  2'b0;  
                      ex_op_b_sel_o =  3'b0;            
                      wb_src_sel_o  =  1'b0;       
                                
                      mem_we_o      =  1'b0;
                      mem_size_o    =  3'b0; 
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0; 
                      INT_RST       =  1'b1;
          end       
endcase
end
end

always@(*)
begin
if   (fetched_instr_i[1:0] != 2'b11 
     || (mem_size_IS == 3'b111 && (fetched_instr_i[6:2]            == `LOAD_OPCODE || fetched_instr_i[6:2] == `STORE_OPCODE) 
     || (ALU_operation_i == 5'b01110 && fetched_instr_i[6:2]       == `OP_IMM_OPCODE) 
     || (ALU_operation == 5'b01110 && fetched_instr_i[6:2]         == `OP_OPCODE)
     || (ALU_operation_branch == 5'b01110 && (fetched_instr_i[6:2] == `BRANCH_OPCODE))
     || (mem_size_IS_store == 3'b111 && (fetched_instr_i[6:2]      == `STORE_OPCODE)) 
     || (funct3_RISB != 3'b0 && fetched_instr_i[6:2]                == `JALR_OPCODE))) illegal = 1'b1;
else illegal = 1'b0;
end

assign illegal_instr_o = illegal;
 
endmodule
