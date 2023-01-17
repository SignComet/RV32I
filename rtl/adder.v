`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.08.2022 17:41:14
// Design Name: 
// Module Name: fulladder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adder(
                input  a,
                input  b,
                input  P_in,  //перенос из предыдущей операции
                output S,     //результат сложения 1+1=0 один бит (фактически 10)
                output P_out  //бит переноса
            );
assign S = a ^ b ^ P_in;    //результат
assign P_out = (a & b) | (a & P_in) | (b & P_in); //хотя бы две 1 в сложении, то перенос

endmodule
