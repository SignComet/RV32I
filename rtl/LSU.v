`timescale 1ns / 1ps

module LSU(
              input                 clk_i,
              input                 arstn_i,          // сброс внутренних регистров

              //core protocol  load в core
              input         [31:0]  lsu_addr_i,       //  от процессора поступает адрес ячейки памяти, к которой будет произведено обращение
              input                 lsu_we_i, 
              input         [2:0]   lsu_size_i,       // размер обрабатываемых данных
              input         [31:0]  lsu_data_i,       // данные для записи в память
              input                 lsu_req_i,        // 1 - обратиться к памяти
              output                lsu_stall_req_o,  // используется как !enable pc. приостанавливаем счётчик
              output        [31:0]  lsu_data_o,       // данные считанные из памяти
              
              //memory protocol  запрошенные данные в rf
              input         [31:0]  data_rdata_i,     // запрошенные данные
              output                data_req_o,       // 1 - обратиться к памяти
              output                data_we_o,        // 1 - это запрос на запись
              output        [3:0]   data_be_o,        // к каким байтам слова идет обращение
              output        [31:0]  data_addr_o,      // адрес, по которому идет обращение
              output        [31:0]  data_wdata_o,     // данные, которые требуется записать
              input                 en_counter
          );

/*для операций типа STORE формат представления чисел не важен, 
*/
/*Позиции битов 4-битного сигнала соответствуют позициям байтов в слове. 
Если конкретный бит data_be_o равен 1,
то соответствующий ему байт будет записан в память.*/

reg [1:0] count = 0;
always@(posedge clk_i) begin //для поднятия сигналов только на один такт, хотя инстр идёт два такта
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
                    
assign data_be_o =  ((lsu_size_i  == `LDST_H  && (lsu_addr_i%4 == 0 || lsu_addr_i == 0)))               ? 4'b0011 :           // к каким байтам слова идет обращение
                    ((lsu_size_i  == `LDST_H  && !(lsu_addr_i%4 == 0)))                                 ? 4'b1100 :
                    ((lsu_size_i  == `LDST_HU && (lsu_addr_i%4 == 0 || lsu_addr_i == 0)))               ? 4'b0011 : 
                    ((lsu_size_i  == `LDST_HU && !(lsu_addr_i%4 == 0)))                                 ? 4'b1100 : 
                    ((lsu_size_i  == `LDST_B  && (lsu_addr_i%4 == 0|| lsu_addr_i == 0)))                ? 4'b0001 :
                    ((lsu_size_i  == `LDST_B  && ((lsu_addr_i - 32'd1)%4 == 0 || lsu_addr_i == 32'h1))) ? 4'b0010 :
                    ((lsu_size_i  == `LDST_B  && ((lsu_addr_i - 32'd2)%4 == 0 || lsu_addr_i == 32'h2))) ? 4'b0100 :
                    ((lsu_size_i  == `LDST_B  && ((lsu_addr_i - 32'd3)%4 == 0 || lsu_addr_i == 32'h3))) ? 4'b1000 :
                    ((lsu_size_i  == `LDST_BU && (lsu_addr_i%4 == 0 || lsu_addr_i == 0))  )             ? 4'b0001 :
                    ((lsu_size_i  == `LDST_BU && ((lsu_addr_i - 32'd1)%4 == 0 || lsu_addr_i == 32'h1))) ? 4'b0010 :
                    ((lsu_size_i  == `LDST_BU && ((lsu_addr_i - 32'd2)%4 == 0 || lsu_addr_i == 32'h2))) ? 4'b0100 :
                    ((lsu_size_i  == `LDST_BU && ((lsu_addr_i - 32'd3)%4 == 0 || lsu_addr_i == 32'h3))) ? 4'b1000 :
                    (lsu_size_i   == `LDST_W)                                                           ? 4'b1111 : 4'b0000;  // 0000 - нет такого

assign data_addr_o =  ((lsu_size_i  == `LDST_H || lsu_size_i == `LDST_HU) && data_be_o ==  4'b0011)     ? lsu_addr_i :
                       (lsu_size_i  == `LDST_W && data_be_o ==  4'b1111)                                ? lsu_addr_i :
                       ((lsu_size_i == `LDST_B || lsu_size_i == `LDST_BU) && data_be_o ==  4'b0001)     ? lsu_addr_i :
                       ((lsu_size_i == `LDST_H || lsu_size_i == `LDST_HU) && data_be_o ==  4'b1100)     ? (lsu_addr_i - 32'd2) : 
                       ((lsu_size_i == `LDST_B || lsu_size_i == `LDST_BU) && data_be_o ==  4'b0010)     ? (lsu_addr_i - 32'd1) :
                       ((lsu_size_i == `LDST_B || lsu_size_i == `LDST_BU) && data_be_o ==  4'b0100)     ? (lsu_addr_i - 32'd2) : 
                       ((lsu_size_i == `LDST_B || lsu_size_i == `LDST_BU) && data_be_o ==  4'b1000)     ? (lsu_addr_i - 32'd3) : 32'b0; 
                              
//  //АДРЕС СЛОВА!!!!!! ADDR_I АДРЕС СО СДВИГОМ внутри слова
                         
//STORE
assign data_wdata_o =   (data_be_o == 4'b0001 || data_be_o == 4'b0010 || data_be_o == 4'b0100 || data_be_o == 4'b1000 ) ? {4{lsu_data_i[7:0]}}  :
                        (data_be_o == 4'b0011 || data_be_o == 4'b1100)                                                  ? {2{lsu_data_i[15:0]}} :
                        (data_be_o == 4'b1111)                                                                          ? lsu_data_i[31:0]      : 32'b0;

//LOAD                        
assign lsu_data_o  =    (lsu_size_i == `LDST_BU && data_be_o ==  4'b0001) ? {{24{1'b0}}, data_rdata_i[7:0]}               :   // читает процессор 
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

/* Было две памяти - инструкций и данных, теперь она объединена в одном модуле ram
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
