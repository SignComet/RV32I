`timescale 1ns / 1ps
// 
//////////////////////////////////////////////////////////////////////////////////

module fulladder (
                    input  [31:0]  A,
                    input  [31:0]  B,
                    input          P_in,
                    output [31:0]  S,
                    output         P_out
                 );
    
wire [30:0] P;

adder adder0(
       .a(A[0]),
       .b(B[0]),
       .P_in(P_in),
       .S(S[0]),
       .P_out(P[0])
    );
  
genvar i;
generate 
   for(i = 1'b1; i < 31; i = i + 1'b1) begin 
    adder adder(
       .a(A[i]),
       .b(B[i]),
       .P_in(P[i-1]),
       .S(S[i]),
       .P_out(P[i])
    );
end
endgenerate
  
    adder adder31(
       .a(A[31]),
       .b(B[31]),
       .P_in(P[30]),
       .S(S[31]),
       .P_out(P_out)
    );    

endmodule
