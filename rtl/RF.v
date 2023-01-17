`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module RF(
            input             clk,
            input      [4:0]  A1,
            input      [4:0]  A2,
            input      [4:0]  A3,
            input             WE3,      //write enable
            input      [31:0] WD3,      //write data
            output     [31:0] RD1,
            output     [31:0] RD2 
         );
        
reg [31:0] RF_ [0:31];                  //32 регистра 32-битных 
assign RD1 = (A1 != 0) ?  RF_[A1]: 0;
assign RD2 = (A2 != 0) ?  RF_[A2]: 0;

always@(posedge clk) begin 
RF_[0] = 32'b0;
if (WE3 && A3 != 0) 
  RF_[A3] <= WD3;
else RF_[A3] <= RF_[A3]; 
end

endmodule
    