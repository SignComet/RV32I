`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

`include "define.v"

module main_decoder(    // устройство управления
                        input      [31:0]                fetched_instr_i, // считанная из памяти инструкциz 
                        output reg [1:0]                 ex_op_a_sel_o,   // Управляющий сигнал мультиплексора для выбора первого операнда АЛУ
                        output reg [2:0]                 ex_op_b_sel_o,
                        output reg [`ALU_OP_WIDTH-1 : 0] alu_op_o,
                        output reg                       mem_req_o,       // Запрос на доступ к памяти (часть интерфейса памяти)
                        output reg                       mem_we_o,        // при равенстве нулю происходит чтение
                        output reg [2:0]                 mem_size_o,      // Управляющий сигнал для выбора размера слова при чтении-записи в память (часть интерфейса памяти) 
                        output reg                       gpr_we_a_o,      // Сигнал разрешения записи в регистровый файл
                        output reg                       wb_src_sel_o,    // Управляющий сигнал мультиплексора для выбора данных, записываемых в регистровый файл 
                        output                           illegal_instr_o, // Сигнал о некорректной инструкции (на схеме не отмечен)
                        output reg                       branch_o,        // Сигнал об инструкции условного перехода
                        output reg                       jal_o,           // Сигнал об инструкции безусловного перехода jal   смещение относительно pc        JAL rd, offset          # rd ? PC + 4, PC ? PC + offset  ( Адрес возврата также сохраняется в rd)     
                        output reg [1:0]                 jalr_o,          // Сигнал об инструкции безусловного перехода jarl  смещение относительно регистра  JALR rd, offset(rs1)    # rd ? PC + 4, PC ? rs1 + offset ( Адрес возврата также сохраняется в rd)        
                        output     [2:0]                 CSROop,           
                        input                            INT_,             // сигнал о том, что произо-шло прерывание
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
wire [2:0] funct3_RISB =  fetched_instr_i[14:12]; //для SYSTEM тоже

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
                              (funct7_R == 7'b0)  && (funct3_RISB == 3'h3) ? `ALU_SLTU : 5'b01110; //01110 не используется!
                       

assign ALU_operation_i =      (funct3_RISB == 3'b0) ? `ALU_ADD                         :
                              (funct3_RISB == 3'h4) ? `ALU_XOR                         : 
                              (funct3_RISB == 3'h6) ? `ALU_OR                          : 
                              (funct3_RISB == 3'h7) ? `ALU_AND                         : 
                              (funct7_R == 7'b0)  && (funct3_RISB == 3'h1) ? `ALU_SLL  : 
                              (funct7_R == 7'b0)  && (funct3_RISB == 3'h5) ? `ALU_SRL  :
                              (funct7_R == 7'h20) && (funct3_RISB == 3'h5) ? `ALU_SRA  : 
                              (funct3_RISB == 3'h2) ? `ALU_SLTS                        : 
                              (funct3_RISB == 3'h3) ? `ALU_SLTU                        : 5'b01110; //01110 не используется!

assign ALU_operation_branch = (funct3_RISB == 3'b0) ? `ALU_EQ  :
                              (funct3_RISB == 3'h1) ? `ALU_NE  : 
                              (funct3_RISB == 3'h4) ? `ALU_LTS : 
                              (funct3_RISB == 3'h5) ? `ALU_GES : 
                              (funct3_RISB == 3'h6) ? `ALU_LTU : 
                              (funct3_RISB == 3'h7) ? `ALU_GEU : 5'b01110; //01110 не используется!
                              
assign mem_size_IS =          (funct3_RISB == 3'b0) ? `LDST_B  :                          
                              (funct3_RISB == 3'h1) ? `LDST_H  : 
                              (funct3_RISB == 3'h2) ? `LDST_W  : 
                              (funct3_RISB == 3'h4) ? `LDST_BU : 
                              (funct3_RISB == 3'h5) ? `LDST_HU : 3'b111; //111 не используется!

assign mem_size_IS_store =    (funct3_RISB == 3'b0) ? `LDST_B  :                          
                              (funct3_RISB == 3'h1) ? `LDST_H  : 
                              (funct3_RISB == 3'h2) ? `LDST_W  : 3'b111; //111 не используется!
                              

reg illegal = 0;    
always@(*)
begin        
if (en_int_rst) INT_RST  =  1'b1;
else INT_RST  =  1'b0;

if(INT_) begin 
                      gpr_we_a_o    =  1'b1;                    
                      mem_req_o     =  1'b0;                 
                      alu_op_o      = `ALU_ADD; //////////nop;               //  PC += imm
                      ex_op_a_sel_o = `OP_A_CURR_PC;  
                      ex_op_b_sel_o = `OP_B_INCR;            ////////////////////
                      wb_src_sel_o  = `WB_EX_RESULT;       
                    
                      mem_we_o      =  1'b0;
                      mem_size_o    =  3'b0; //////////nop
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'h3; //mtvec
                      INT_RST       =  1'b0;
                      flag_mret = 0;
                      
          end

else begin
if(flag_mret)INT_RST =  1'b0;
flag_mret     =  0;
case (fetched_instr_i[6:2])
     `OP_OPCODE:    begin           // R-type
                      gpr_we_a_o    =  1'b1;             // запись в RF
                      mem_req_o     =  1'b0;             // неважно    
                      alu_op_o      =  ALU_operation;
                      ex_op_a_sel_o = `OP_A_RS1; 
                      ex_op_b_sel_o = `OP_B_RS2;
                      wb_src_sel_o  = `WB_EX_RESULT;     // результат с АЛУ запис в Рег файл
                    
                      mem_we_o      =  1'b0;             // неважно
                      mem_size_o    =  3'b0;             // неважно, нет обращения к памяти
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0;
                    end
                    
    `OP_IMM_OPCODE: begin           // I-type
                      gpr_we_a_o    =  1'b1;             // запись в RF
                      mem_req_o     =  1'b0;             // неважно             
                      alu_op_o      =  ALU_operation_i;
                      ex_op_a_sel_o = `OP_A_RS1; 
                      ex_op_b_sel_o = `OP_B_IMM_I;
                      wb_src_sel_o  = `WB_EX_RESULT;    // результат с АЛУ запис в Рег файл
                    
                      mem_we_o      =  1'b0;            // неважно 
                      mem_size_o    =  3'b0;            // неважно
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0;  
                    end
                    
    `LUI_OPCODE:    begin           // U-type            // lui xn const == rd == imm << 12  
                      gpr_we_a_o    =  1'b1;             // запись в RF
                      mem_req_o     =  1'b0;             // неважно    
                      alu_op_o      = `ALU_ADD;          // без разницы тк с +0
                      ex_op_a_sel_o = `OP_A_ZERO;        // подаётся 0
                      ex_op_b_sel_o = `OP_B_IMM_U;
                      wb_src_sel_o  = `WB_EX_RESULT;     // результат с АЛУ запис в Рег файл
                    
                      mem_we_o      =  1'b0;             // неважно
                      mem_size_o    =  3'b0;             // неважно
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0; 
                    end    
                                                        
    `LOAD_OPCODE:   begin           // I-type             // загрузка/выгрузка слов ИЗ памяти lw xN(из) offset(base(rs1)) = rd = M[rs1+imm][0:31]
                      gpr_we_a_o    =  1'b1;              // ЗАПИСЬ в RF
                      mem_req_o     =  1'b1;                  
                      alu_op_o      = `ALU_ADD;           // rs1+imm
                      ex_op_a_sel_o = `OP_A_RS1; 
                      ex_op_b_sel_o = `OP_B_IMM_I;
                      wb_src_sel_o  = `WB_LSU_DATA;       // результат с АЛУ запис в Рег файл
                    
                      mem_we_o      =  1'b0;              // не пишем, ЧИТАЕМ из памяти, ЗАГРУЖАЕМ в рег файл
                      mem_size_o    =  mem_size_IS;
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0;
                    end
    
    `STORE_OPCODE:  begin           // S-type              // загрузка/выгрузка слов В память  sw xN(из) offset(base)   M[rs1+imm][0:31] = rs2[0:31]
                      gpr_we_a_o    =  1'b0;               // ЧИТАЕМ
                      mem_req_o     =  1'b1;                 
                      alu_op_o      = `ALU_ADD;            // rs1+imm
                      ex_op_a_sel_o = `OP_A_RS1; 
                      ex_op_b_sel_o = `OP_B_IMM_S;         // константа хранится в двух полях
                      wb_src_sel_o  =  1'b0;               // без разницы тк НЕ запис в RF
                    
                      mem_we_o      =  1'b1;               // ЗАПИСЫВАЕМ
                      mem_size_o    =  mem_size_IS_store;
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0; 
                    end
                    
    `BRANCH_OPCODE: begin           // B-type              // условный переход, ничего не запис, работаем с PC 
                      gpr_we_a_o    =  1'b0;                    
                      mem_req_o     =  1'b0;               // неважно     
                      alu_op_o      =  ALU_operation_branch;    
                      ex_op_a_sel_o = `OP_A_RS1;  
                      ex_op_b_sel_o = `OP_B_RS2; 
                      wb_src_sel_o  =  1'b0;                // без разницы. Только переход
                    
                      mem_we_o      =  1'b0;                // неважно   
                      mem_size_o    =  3'b0;                // неважно   
                      branch_o      =  1'b1; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0; 
                    end   
   
    `JAL_OPCODE:    begin           // J-type                // безусловный переход, ничего не запис, работаем с PC jal xN, label  rd = PC + 4 PC += imm
                      gpr_we_a_o    =  1'b1;                    
                      mem_req_o     =  1'b0;                 // неважно   
                      alu_op_o      = `ALU_ADD;              // PC += imm
                      ex_op_a_sel_o = `OP_A_CURR_PC;  
                      ex_op_b_sel_o = `OP_B_INCR; 
                      wb_src_sel_o  = `WB_EX_RESULT;        
                    
                      mem_we_o      =  1'b0;                 // неважно   
                      mem_size_o    =  3'b0;                 // неважно   
                      branch_o      =  1'b0; 
                      jal_o         =  1'b1;
                      jalr_o        =  2'b0;  
                    end   
    
    `JALR_OPCODE:   begin           // I-type                // безусловный переход, ничего не запис, работаем с PC jal xN, label  rd = PC + 4 PC += rs1 + imm
                      gpr_we_a_o    =  1'b1;                    
                      mem_req_o     =  1'b0;                 // неважно   
                      alu_op_o      = `ALU_ADD;               
                      ex_op_a_sel_o = `OP_A_CURR_PC;  
                      ex_op_b_sel_o = `OP_B_INCR;            
                      wb_src_sel_o  = `WB_EX_RESULT;       
                    
                      mem_we_o      =  1'b0;                 // неважно      
                      mem_size_o    =  3'b0;                 // неважно   
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b1; 
                    end 
    
    `AUIPC_OPCODE:  begin           // U-type                 // auipc xn label   rd == PC +(imm << 12)  Add Upper Immediate to PC (добавить константу к старшим битам РС).
                      gpr_we_a_o    =  1'b1;                  // запись в RF
                      mem_req_o     =  1'b0;                  // неважно
                      alu_op_o      = `ALU_ADD;                
                      ex_op_a_sel_o = `OP_A_CURR_PC; 
                      ex_op_b_sel_o = `OP_B_IMM_U;
                      wb_src_sel_o  = `WB_EX_RESULT;          // результат с АЛУ запис в Рег файл
                    
                      mem_we_o      =  1'b0;                  // неважно  
                      mem_size_o    =  3'b0;                  // неважно  
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;
                      jalr_o        =  2'b0;
                    end    
    
    
  `MISC_MEM_OPCODE: begin           // I-type  	Не производить операцию    NOP     
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
    
    `SYSTEM_OPCODE : begin           // I-type    ДЛЯ РАБОТЫ С CSR
    if(funct3_RISB == 3'b000)
    begin  //MRET
                      gpr_we_a_o    =  1'b1;                    
                      mem_req_o     =  1'b0;                 // неважно 
                      alu_op_o      = `ALU_ADD;              //////////nop;  
                      ex_op_a_sel_o = `OP_A_CURR_PC;  
                      ex_op_b_sel_o = `OP_B_INCR;            
                      wb_src_sel_o  = `WB_EX_RESULT;       
                    
                      mem_we_o      =  1'b0;                // неважно  
                      mem_size_o    =  3'b0;                // неважно 
                      branch_o      =  1'b0; 
                      jal_o         =  1'b0;                
                      jalr_o        =  2'h2;                // pc = mepc
                      INT_RST       =  1'b1;
                      flag_mret     =  1'b1;
    end
    else if(funct3_RISB == 3'b001 || funct3_RISB == 3'b010 || funct3_RISB == 3'b011)
    begin  //CSRRW //CSRRS //CSRRC     
                      gpr_we_a_o    =  1'b1;                //  rd = csr  // ЗАПИСЬ в RF
                      mem_req_o     =  1'b1;                  
                      alu_op_o      = `ALU_ADD;             // rs1+imm
                      ex_op_a_sel_o = `OP_A_RS1; 
                      ex_op_b_sel_o = `OP_B_IMM_I;
                      wb_src_sel_o  = `WB_LSU_DATA;         
                    
                      mem_we_o      =  1'b0;                // не пишем, ЧИТАЕМ
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
                      alu_op_o      = `ALU_ADD;               //////////nop;              
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
     || (mem_size_IS === 3'bzzz && (fetched_instr_i[6:2]            == `LOAD_OPCODE || fetched_instr_i[6:2] == `STORE_OPCODE) 
     || (ALU_operation_i === 5'bzzzzz && fetched_instr_i[6:2]       == `OP_IMM_OPCODE) 
     || (ALU_operation === 5'bzzzzz && fetched_instr_i[6:2]         == `OP_OPCODE)
     || (ALU_operation_branch === 5'bzzzzz && (fetched_instr_i[6:2] == `BRANCH_OPCODE))
     || (mem_size_IS_store === 3'bzzz && (fetched_instr_i[6:2]      == `STORE_OPCODE)) 
     || (funct3_RISB != 3'b0 && fetched_instr_i[6:2]                == `JALR_OPCODE))) illegal = 1'b1;
else illegal = 1'b0;
end

assign illegal_instr_o = illegal;
 
endmodule
