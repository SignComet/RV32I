`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module PC(
            input             clk,
            input             rst,
            input             en,
            input      [1:0]  jalr,
            output     [31:0] number_instr,
            output reg [31:0] pc
         );
initial pc = 32'b0;

always@(posedge clk) begin
if (!rst) pc <= 32'b0;
else if (en) begin
       if (jalr != 2'b00)
         pc <= number_instr; //signed, down-up movement
       else 
         pc <= pc + number_instr;
       end  
     else pc <= pc;
end
endmodule
