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
                input  P_in,  //������� �� ���������� ��������
                output S,     //��������� �������� 1+1=0 ���� ��� (���������� 10)
                output P_out  //��� ��������
            );
assign S = a ^ b ^ P_in;    //���������
assign P_out = (a & b) | (a & P_in) | (b & P_in); //���� �� ��� 1 � ��������, �� �������

endmodule
