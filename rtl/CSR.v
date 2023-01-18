`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module CSR( //Control  and  Status  Registers
                input                clk,
                input         [2:0]  OP,     // CSRop from main_decoder. Type of operation
                input         [31:0] mcause, // from IC
                input         [31:0] pc,
                input         [11:0] A,      // addr of CSR, which will be used
                input         [31:0] WD,     // rd1 ñ RF
                output  reg   [5:0]  mie,    // to IC            
                output  reg   [31:0] mtvec,  // address of the interrupt vector
                output  reg   [31:0] mepc,
                output  reg   [31:0] rd,
                output               en_int_rst,
                input                en_mepc,
                input         [31:0] mepc_csr
          );

reg en_mie = 1'b0;
reg en_mtvec = 1'b0;
reg en_mscratch = 1'b0;
//reg en_mepc = 1'b0;
reg en_cause = 1'b0;

wire mux_en_pc;
wire mux_en_cause;
assign mux_en_pc    = (OP[2] || OP[1] || OP[0]);
assign mux_en_cause = (OP[2] || OP[1] || OP[0]);

always  @(*)
case(A)
  12'h304: en_mie      = OP[1] || OP[0];  // machine interrapt enable register.  mask
  12'h305: en_mtvec    = OP[1] || OP[0];  // machine trap-handler base address 
  12'h340: en_mscratch = OP[1] || OP[0];  // pointer to the top of the interrupt stack
 // 12'h041: en_mepc   = mux_en_pc;       // machine exception pc. addr of the instrduring which the interrupt occurred. For return
  12'h342: en_cause    = mux_en_cause;  
  default: begin
             en_mie      = 0;
             en_mtvec    = 0;
             en_mscratch = 0;
      //     en_mepc     = 0;
             en_cause    = 0;
           end  
endcase   

//What exactly will be written to the CSR register
wire [31:0] mux;
assign mux = (OP[1:0] == 2'b00) ? 32'b0       :    
             (OP[1:0] == 2'b01) ? WD          :    // from RF
             (OP[1:0] == 2'b10) ? (rd && ~WD) : (rd || WD);  

reg [31:0] cause;
reg [31:0] mscratch; 
assign en_int_rst = (mie === 6'bx || mtvec === 32'bx || mscratch === 32'bx); // to get the data in time

always @(posedge clk) begin
if(en_mepc)     
      mepc <= mepc_csr;
else  mepc <= mepc;
if(en_cause)    
      cause <= mcause;
else  cause <= cause;
if(en_mie)      
      mie <= mux;
else  mie <= mie;
if(en_mtvec)    
      mtvec <= mux;
else  mtvec <= mtvec;
if(en_mscratch) 
      mscratch <= mux;
else  mscratch <= mscratch;
end 

always @(*) //necessary register for output
case(A)
  12'h304: rd = mie;   
  12'h305: rd = mtvec; 
  12'h340: rd = mscratch;
  12'h041: rd = mepc;     
  12'h342: rd = cause;  
  default: rd = 32'b0; 
endcase
      
endmodule
