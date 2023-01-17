`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

`include "define.v"
module ALU
            #(
                parameter bit_wight = 31
            )
            (
                input      [bit_wight:0]       A,
                input      [bit_wight:0]       B,
                input      [`ALU_OP_WIDTH-1:0] ALUOp,
                output reg [bit_wight:0]       res,   //операци€
                output reg                     flag
            );
    
initial begin
res  = 32'b0;
flag = 32'b0;
end

wire [31:0] res_add;
wire P_in = 0;
wire P_out = 0;
fulladder inst(A, B, P_in, res_add, P_out ); //добавила свой блок полного сумматора с послед переносом

always@ * //в SV заменитс€ на always_comb
begin
  case(ALUOp)
    `ALU_ADD:  begin
                 res  =  res_add; 
                 flag = 0;
               end    
    `ALU_SUB:  begin 
                 res =  A - B; 
                 flag = 0;
               end 
     //—двиг 32-битного числа более, чем на 31 не имеет смысла. “ребуетс€ всего 5 бит             
    `ALU_SLL:  begin 
                 res =  A << B[4:0]; 
                 flag = 0;
               end    
    `ALU_SLTS: begin 
                 res = ($signed(A) < $signed(B)); 
                 flag = 0;
               end    
    `ALU_SLTU: begin //Set_less_then_unsigned
                 res = (A < B); 
                 flag = 0;
               end                   
    `ALU_XOR:  begin 
                 res =  A ^ B; 
                 flag = 0;
               end    
    `ALU_SRL:  begin 
                 res =  A >> B[4:0]; 
                 flag = 0;
               end    
    `ALU_SRA:  begin 
                 res =  $signed(A) >>> B[4:0];  
                 flag = 0;
               end    
    `ALU_OR:   begin 
                 res =  A | B; 
                 flag = 0;
               end    
    `ALU_AND:  begin 
                 res =  A & B;  
                 flag = 0;
               end  
            
    `ALU_EQ:   begin  // branch equal
                 flag = (A == B);
                 res = 0;
               end
    `ALU_NE:   begin
                 flag = (A != B);
                 res = 0;
               end   
    `ALU_LTS:  begin
                 flag = ($signed(A) < $signed(B));
                 res = 0;
               end
    `ALU_GES:  begin
                 flag = ($signed(A) >= $signed(B));
                 res = 0;
               end
    `ALU_LTU:  begin
                 flag = (A < B);
                 res = 0;
               end
    `ALU_GEU:  begin
                 flag = (A > B);
                 res = 0;
               end    
     default: begin
                flag = 0;
                res = 0;
              end                                                                                                                        
  endcase
end
endmodule
