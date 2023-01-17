`timescale 1ns / 1ps

module tb_miriscv_top();

  parameter     HF_CYCLE = 2.5;       // 200 MHz clock
  parameter     RST_WAIT = 10;        // 10 ns reset
  parameter     RAM_SIZE = 512;       // in 32-bit words

  // clock, reset
  reg clk;
  reg rst_n;

  miriscv_top #(
    .RAM_SIZE       ( RAM_SIZE           ),
<<<<<<< HEAD
    .RAM_INIT_FILE  ("Example_3_Interrupt.txt") // Example_3_Interrupt.txt Example_2_LSU.txt Example_1_square.txt
=======
    .RAM_INIT_FILE  ("Example_3_Interrupt.txt") // Example_1_square.txt Example_2_LSU.txt Example_3_Interrupt.txt 
>>>>>>> 6480abcb7069ac6bc1d0ed515819a4dcca2c33d8
  ) dut (
    .clk_i    ( clk   ),
    .rst_n_i  ( rst_n )
  );

  initial begin
    clk   = 1'b0;
    rst_n = 1'b0;
    #RST_WAIT;
    rst_n = 1'b1;
  end

  always begin
    #HF_CYCLE;
    clk = ~clk;
  end

endmodule
