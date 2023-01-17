module miriscv_top
#(
  parameter RAM_SIZE      = 256, // bytes
  parameter RAM_INIT_FILE = "RAM_INIT_FILE.txt"
)
(
  // clock, reset
  input clk_i,
  input rst_n_i
);

  logic  [31:0]  instr_rdata_core;
  logic  [31:0]  instr_addr_core;

  logic  [31:0]  data_rdata_core;
  logic          data_req_core;
  logic          data_we_core;
  logic  [3:0]   data_be_core;
  logic  [31:0]  data_addr_core;
  logic  [31:0]  data_wdata_core;

  logic  [31:0]  data_rdata_ram;
  logic          data_req_ram;
  logic          data_we_ram;
  logic  [3:0]   data_be_ram;
  logic  [31:0]  data_addr_ram;
  logic  [31:0]  data_wdata_ram;

  logic  data_mem_valid;
  assign data_mem_valid = (data_addr_core >= RAM_SIZE) ?  1'b0 : 1'b1;

  assign data_rdata_core  = (data_mem_valid) ? data_rdata_ram : 1'b0;
  assign data_req_ram     = (data_mem_valid) ? data_req_core : 1'b0;
  assign data_we_ram      =  data_we_core;
  assign data_be_ram      =  data_be_core;
  assign data_addr_ram    =  data_addr_core;
  assign data_wdata_ram   =  data_wdata_core;
  
wire        INT_; //cигнал о том, что произошло прерывание
wire [31:0] mcause;      //код причины прерывания   
wire        INT_RST;     //прерывание обработано
wire [5:0]  mie;
wire flag_mret;
PROCESSOR  core (
    .clk_i   ( clk_i   ),
    .arstn_i ( rst_n_i ),

    .instr_rdata_i ( instr_rdata_core ),
    .instr_addr_o  ( instr_addr_core  ),

    .data_rdata_i  ( data_rdata_core  ),
    .data_req_o    ( data_req_core    ),
    .data_we_o     ( data_we_core     ),
    .data_be_o     ( data_be_core     ),
    .data_addr_o   ( data_addr_core   ),
    .data_wdata_o  ( data_wdata_core  ),
    .INT_i         ( INT_      ),
    .mcause_i      ( mcause    ),
    .INT_RST_o     ( INT_RST   ),
    .mie_o         ( mie       ),
    .flag_mret     ( flag_mret )
  );

  miriscv_ram
  #(
    .RAM_SIZE      (RAM_SIZE),
    .RAM_INIT_FILE (RAM_INIT_FILE)
  ) ram (
    .clk_i         ( clk_i   ),
    .rst_n_i       ( rst_n_i ),

    .instr_rdata_o ( instr_rdata_core),
    .instr_addr_i  ( instr_addr_core ),

    .data_rdata_o  ( data_rdata_ram  ),
    .data_req_i    ( data_req_ram    ),
    .data_we_i     ( data_we_ram     ),
    .data_be_i     ( data_be_ram     ),
    .data_addr_i   ( data_addr_ram   ),
    .data_wdata_i  ( data_wdata_ram  )
  );
wire [5:0]  int_req_idle;
reg  [5:0]  int_req;
reg  [5:0]  int_fin = 0;

assign int_req_idle[0] = (flag_mret && int_fin[0] == 6'h1) ?  ~int_fin[0] : int_req[0];
assign int_req_idle[1] = (flag_mret && int_fin[1] == 6'h1) ?  ~int_fin[1] : int_req[1];
assign int_req_idle[2] = (flag_mret && int_fin[2] == 6'h1) ?  ~int_fin[2] : int_req[2];
assign int_req_idle[3] = (flag_mret && int_fin[3] == 6'h1) ?  ~int_fin[3] : int_req[3];
assign int_req_idle[4] = (flag_mret && int_fin[4] == 6'h1) ?  ~int_fin[4] : int_req[4];
assign int_req_idle[5] = (flag_mret && int_fin[5] == 6'h1) ?  ~int_fin[5] : int_req[5];

initial int_req = 6'b101000;
always @(posedge clk_i) 
if(flag_mret && INT_RST) int_req <= int_req_idle; //через RST
else int_req <= int_req;
              
Interrupt_Controller IC(
    .clk           ( clk_i   ),
    .mie_i         ( mie     ),
    .int_req_i     ( int_req ),
    .INT_RST_i     ( INT_RST ),
    .int_fin       ( int_fin ),
    .INT_o         ( INT_    ),
    .mcause_o      ( mcause  )
  );


endmodule
