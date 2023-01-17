`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Interrupt_Controller(    // контроллера прерывания с циклическим опросом
                                input             clk,
                                input      [5:0]  mie_i,      // mask
                                input      [5:0]  int_req_i,  // from a peripheral device
                                input             INT_RST_i,  
                                output     [5:0]  int_fin,    // interrupt processed     
                                output            INT_o,      // interrupt happened 
                                output reg [31:0] mcause_o                              
                            );
reg  [2:0] counter = 0;
wire [5:0] dec;  // total of 5 devices

reg  register;
wire orr;

assign dec =   (counter == 3'h0) ? 6'b000001 : 
               (counter == 3'h1) ? 6'b000010 :      
               (counter == 3'h2) ? 6'b000100 :
               (counter == 3'h3) ? 6'b001000 : 
               (counter == 3'h4) ? 6'b010000 :
               (counter == 3'h5) ? 6'b100000 : 6'b0; 

assign orr =   ((dec[0] && int_req_i[0] && mie_i[0]) ||
               (dec[1]  && int_req_i[1] && mie_i[1])  ||
               (dec[2]  && int_req_i[2] && mie_i[2])  ||
               (dec[3]  && int_req_i[3] && mie_i[3])  ||
               (dec[4]  && int_req_i[4] && mie_i[4])  ||
               (dec[5]  && int_req_i[5] && mie_i[5]));
               
assign int_fin[0] = (INT_RST_i && dec[0] && int_req_i[0] && mie_i[0]);       
assign int_fin[1] = (INT_RST_i && dec[1] && int_req_i[1] && mie_i[1]);   
assign int_fin[2] = (INT_RST_i && dec[2] && int_req_i[2] && mie_i[2]);   
assign int_fin[3] = (INT_RST_i && dec[3] && int_req_i[3] && mie_i[3]);   
assign int_fin[4] = (INT_RST_i && dec[4] && int_req_i[4] && mie_i[4]);   
assign int_fin[5] = (INT_RST_i && dec[5] && int_req_i[5] && mie_i[5]);   

reg flag = 0;              
always@(posedge clk)  begin   
  if(INT_RST_i) begin
    counter  <= 0;
    register <= 0;
    flag <= 0;
  end
  else begin if(!flag) begin
    counter <= counter + 1;
    register <= orr;
  end
  if (orr) begin
  register <= orr;
  counter  <= counter;
  mcause_o <= counter; 
  flag <= 1; 
  end
  end
 register <= orr; 
end

assign INT_o =  orr == 1 && register == 0;

endmodule


