`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module adder(
                input  a,
                input  b,
                input  P_in,  // transfer from a previous operation
                output S,     // result  1+1=0 (fact 10)
                output P_out  // carry
            );
assign S = a ^ b ^ P_in;      // result
assign P_out = (a & b) | (a & P_in) | (b & P_in); //at least two 1 

endmodule
