`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


    module CSR( //Control  and  Status  Registers
                input                clk,
                input         [2:0]  OP,     //CSRop � ��������. J��������� ��������, ������� ����� ������������� ��� ���������� CSR �� ������ A  
                input         [31:0] mcause, //from IC
                input         [31:0] pc,
                input         [11:0] A,      //��� �������� ������ �������� CSR, � �������� ����� ����������� ���������. ��������� � ������� 12 ����� ����������, � imm. ���������� ���� I 
                input         [31:0] WD,     //rd1 � RF
                output  reg   [5:0]  mie,    //to IC 
                
                
                output  reg   [31:0] mtvec,  //����� ������� ����������
                output  reg   [31:0] mepc,
                output  reg   [31:0] rd,
                output               en_int_rst,
                input                en_mepc,
                input         [31:0] mepc_csr
          );

/*���  ������  �  ����������  CSR  ������������  �����������  ���������� !!!!!!SYSTEM (1110011) I-����,
 �������� � 12-������ ���� imm ����� ��������, � �������� ����� ����������� ������ 
� ������ � ����������� ����� �� ���� ��-��� ������ ��� ���� ����� ������� ���� �� ��������� CSR.*/

/*  �������  4  ����  ������  CSR  ������������  ���  ����������� ����������� CSR ��� ������ � ������ � ������������ � ������� ����������: 
��� ������� ���� imm[11:10] ���������, �������� �� ������� ��� ������/��-���� ��� ������ ��� ������, 
��������� ��� ���� imm[9:8] �������� ����� ���-��� ������� ����������, ������� ����� �������� ������ � CSR. */

reg en_mie = 0;
reg en_mtvec = 0;
reg en_mscratch = 0;
//reg en_mepc = 0;
reg en_cause = 0;

wire mux_en_pc;
wire mux_en_cause;
assign mux_en_pc    = (OP[2] || OP[1] || OP[0]);
assign mux_en_cause = (OP[2] || OP[1] || OP[0]);

//��������������� ����������� ����� � ���������� ������ ���������� �� ������ enable (EN) �� ��� �� �������.
always  @(*) //���� ��������� ��������

case(A)
  12'h304: en_mie      <= OP[1] || OP[0];    //machine interrapt enable register.  �������, ����������� ����������� ����������. ��������, ���� �� 5-�� ����� ������� ���������� ������������ ����������, �� ��������� ����������� �� ���� ������ � ��� ������, ���� 5-�� ��� �������� mie ����� ����� 1. 
  12'h305: en_mtvec    <= OP[1] || OP[0]; //...trap-handler(����������) base address 
  12'h340: en_mscratch <= OP[1] || OP[0]; //��������� �� �������� �����. ���� ��� ���������� ��������� �� ��� ��, ��� ����������� ����, � ����� ������ ����� ����� ���-����� � �������� mscratch
 // 12'h041: en_mepc     <= mux_en_pc;     //...exception pc. ��������� ����� ����������, �� ����� ������� ��������� ���������� ��� ����������. �������
  12'h342: en_cause    <= mux_en_cause;  
  default: begin
             en_mie      = 0;
             en_mtvec    = 0;
             en_mscratch = 0;
      //       en_mepc     = 0;
             en_cause    = 0;
           end  
endcase   

//���� �� ����������
//��� ������ ����� �������� � ������� CSR
wire [31:0] mux;
assign mux = (OP[1:0] == 2'b00) ? 32'b0 : //��� �������
             (OP[1:0] == 2'b01) ? WD :    //�������� � RF
             (OP[1:0] == 2'b10) ? (rd && ~WD) : (rd || WD);  //����� ��������� �� CSR � ��������� �� ������������ �����

reg [31:0] cause;
//�����,  �����  ���  �������������  �������  ����������  �����  ��  ��������� �������� �������� ���� ��������� ��������� PC, �� ������� ��������� ���-������� � ����� ������� ������������� ������ ����������. 
wire [31:0] mux_mepc;
wire [31:0] mux_cause;
//assign mux_mepc    = (OP[2]) ? pc - 32'h4 : mux; 
//assign mux_cause   = (OP[2]) ? mcause : mux;

reg [31:0] mscratch; //����� ������� ����� ����������
assign en_int_rst = (mie === 6'bx || mtvec === 32'bx || mscratch === 32'bx); //� ����� RF �� ��� � �

always @(posedge clk) begin
if(en_mepc)     
      mepc <= mepc_csr;
else  mepc <= mepc;
if(en_cause)    
      cause    <= mcause;
else  cause <= cause;
if(en_mie)      
      mie      <= mux;
else  mie  <= mie;
if(en_mtvec)    
      mtvec    <= mux;
else  mtvec <= mtvec;
if(en_mscratch) 
      mscratch <= mux;
else  mscratch <= mscratch;
end 


//�������������, �������������� ���������� ������ � ������ �� ����� RD �������� ���������������� ��������   
always @(*) //������ ������ ������� �� �����
case(A)
  12'h304: rd <= mie;   //machine interrapt enable register.  �������, ����������� ����������� ����������. ��������, ���� �� 5-�� ����� ������� ���������� ������������ ����������, �� ��������� ����������� �� ���� ������ � ��� ������, ���� 5-�� ��� �������� mie ����� ����� 1. 
  12'h305: rd <= mtvec; //...trap-handler(����������) base address 
  12'h340: rd <= mscratch; //��������� �� �������� �����. ���� ��� ���������� ��������� �� ��� ��, ��� ����������� ����, � ����� ������ ����� ����� ���-����� � �������� mscratch
  12'h041: rd <= mepc;     //...exception pc. ��������� ����� ����������, �� ����� ������� ��������� ���������� ��� ����������. �������
  12'h342: rd <= cause;  
  default: rd <= 32'd0; 
endcase
      
endmodule
