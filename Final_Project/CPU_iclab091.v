//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/



// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf; 
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11 ;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15 ;


//###########################################
//
// Wrtie down your design below
//
//###########################################

//####################################################
//               reg & wire
//####################################################
reg          [8:0]   current_state ;
reg          [8:0]   next_state ;
reg          [15:0]  counter ;
wire         [2:0]   opcode ;
wire         [3:0]   rs ;
wire         [3:0]   rt ;
wire         [3:0]   rd ;
wire         [4:0]   coeff_a ;
wire signed  [9:0]   coeff_b ;
wire                 func ;
reg  signed  [100:0] temp ; 
wire signed  [4:0]   imm ;
wire signed  [15:0]  det3_r0, det3_r1, det3_r2 ; 
wire signed  [15:0]  det3_r3, det3_r4, det3_r5 ; 
wire signed  [15:0]  det3_r6, det3_r7, det3_r8 ; 
reg  signed  [15:0]  rs_reg, rt_reg;
reg          [15:0]  instruction ;
reg          [15:0]  DO_cache ;
reg          [15:0]  DI_cache ;
reg                  WEB_Cache ;
reg          [6:0]   Addr_cache ;
reg  signed  [15:0]  current_pc ;
reg  signed  [15:0]  next_pc ;
reg  signed  [15:0]  cache_counter ;
reg          [31:0]  araddr_ins ;
reg          [31:0]  araddr_data ;
reg                  arvalid_ins ;
reg                  arvalid_data ;
reg                  rready_ins ;
reg                  rready_data ;
wire         [11:0]  addr_target ;
assign               addr_target = (rs_reg + imm) <<< 1 ;

parameter  IDLE                      =  0 ;
parameter  FETCH_AXI                 =  1 ;
parameter  LOAD_INS                  =  2 ;
parameter  INSTRUCTION_FETCH_DELAY1  =  3 ;
parameter  INSTRUCTION_FETCH_DELAY2  =  4 ;
parameter  INSTRUCTION_FETCH         =  5 ;
parameter  INSTRUCTION_DECODE        =  6 ;
parameter  ADD                       =  7 ;
parameter  SUB                       =  8 ;
parameter  SET_LESS_THAN             =  9 ;
parameter  MULT                      = 10 ;
parameter  LOAD                      = 11 ;
parameter  STORE                     = 12 ;
parameter  BEQ                       = 13 ;
parameter  DET                       = 14 ;
parameter  OUTPUT                    = 15 ;
parameter  INSTRUCTION_DECODE_DELAY1 = 16 ;

reg signed [50:0]  mult3_in0 ;
reg signed [15:0]  mult3_in1 ;
reg signed [15:0]  mult3_in2 ;
reg signed [66:0]  mult3_out ;
reg signed [66:0]  add2_in0 ;
reg signed [66:0]  add2_in1 ;
reg signed [68:0]  add2_out ;
reg signed [66:0]  sub2_in0 ; 
reg signed [66:0]  sub2_in1 ;
reg signed [68:0]  sub2_out ;

Mult3 Mult3 (
    .mult3_in0(mult3_in0), 
    .mult3_in1(mult3_in1), 
    .mult3_in2(mult3_in2), 
    .mult3_out(mult3_out)
    ) ;

Add2 Add2 (
    .add2_in0(add2_in0), 
    .add2_in1(add2_in1), 
    .add2_out(add2_out)
    ) ;

Sub2 Sub2 (
    .sub2_in0(sub2_in0), 
    .sub2_in1(sub2_in1), 
    .sub2_out(sub2_out)
    ) ;
//####################################################
//                  FSM
//####################################################
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE ;
    else current_state <= next_state ;
end

always@(*) begin
	if(!rst_n) next_state = IDLE ;
	else begin
		case(current_state)
			IDLE : begin
				next_state = FETCH_AXI ;
			end
      FETCH_AXI : begin
        if(rvalid_m_inf) next_state = LOAD_INS ;
				else next_state = current_state ;
			end
      LOAD_INS : begin
				if(rlast_m_inf[1]) next_state = INSTRUCTION_FETCH_DELAY1 ;
				else next_state = current_state ;
			end
      INSTRUCTION_FETCH_DELAY1 : begin
        next_state = INSTRUCTION_FETCH_DELAY2 ;
			end
      INSTRUCTION_FETCH_DELAY2 : begin
        next_state = INSTRUCTION_FETCH ;
			end
      INSTRUCTION_FETCH : begin
        next_state = INSTRUCTION_DECODE_DELAY1 ;
			end
      INSTRUCTION_DECODE_DELAY1 : begin
        next_state = INSTRUCTION_DECODE ;
			end
      INSTRUCTION_DECODE : begin
        if(opcode == 3'b000 && func == 0) next_state = ADD ;
        else if(opcode == 3'b000 && func == 1) next_state = SUB ;
        else if(opcode == 3'b001 && func == 0) next_state = SET_LESS_THAN ;
        else if(opcode == 3'b001 && func == 1) next_state = MULT ;
        else if(opcode == 3'b010) next_state = LOAD ;
        else if(opcode == 3'b011) next_state = STORE ;
        else if(opcode == 3'b100) next_state = BEQ ;
        else if(opcode == 3'b111) next_state = DET ;
        else next_state = current_state ;
			end
      MULT : begin
        if(counter == 1) next_state = OUTPUT ;
				else next_state = current_state ;
			end
      LOAD : begin
        if(rlast_m_inf[0]) next_state = OUTPUT ;
				else next_state = current_state ;
			end
      ADD : begin
        if(counter == 1) next_state = OUTPUT ;
				else next_state = current_state ;
			end
      SUB : begin
        if(counter == 1) next_state = OUTPUT ;
				else next_state = current_state ;
			end
      SET_LESS_THAN : begin
        next_state = OUTPUT ;
			end
      STORE : begin
        if(wready_m_inf == 1) next_state = OUTPUT ;
				else next_state = current_state ;
			end
      BEQ : begin
        next_state = OUTPUT ;
			end
      DET : begin
        if(counter == 35) next_state = OUTPUT ;
				else next_state = current_state ;
			end
      OUTPUT : begin
        if(cache_counter != 128 && !(opcode == 4 && (cache_counter > 127 || cache_counter < 0))) next_state = INSTRUCTION_FETCH_DELAY1 ;
        else if(cache_counter == 128 || (opcode == 4 && (cache_counter > 127 || cache_counter < 0))) next_state = IDLE ;
				else next_state = current_state ;
			end
			default : next_state = current_state ;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter <= 0 ;
    else if(current_state == DET && counter < 35) counter <= counter + 1 ;
    else if(current_state == DET && counter == 35) counter <= 0 ;
    else if((current_state == SUB || current_state == ADD || current_state == MULT) && counter < 1) counter <= counter + 1 ;
    else if((current_state == SUB || current_state == ADD || current_state == MULT) && counter == 1) counter <= 0 ;
    else counter <= 0 ;
end
//####################################################
//                      DET
//####################################################
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) temp <= 0 ;
    else if(current_state == DET && (counter == 9 || counter == 25)) begin
      temp <= add2_out ;
	  end
    else if(current_state == DET && (counter == 17 || counter == 33)) begin
      temp <= sub2_out ;
	  end
    else temp <= temp ;
end

//####################################################
//                      ALU
//####################################################
assign det3_r0 = (counter < 8) ? core_r5  : 
                 (counter < 16) ? core_r4 : 
                 (counter < 24) ? core_r4 : core_r4;

assign det3_r1 = (counter < 8) ? core_r6  : 
                 (counter < 16) ? core_r6 : 
                 (counter < 24) ? core_r5 : core_r5;

assign det3_r2 = (counter < 8) ? core_r7  : 
                 (counter < 16) ? core_r7 : 
                 (counter < 24) ? core_r7 : core_r6;

assign det3_r3 = (counter < 8) ? core_r9  : 
                 (counter < 16) ? core_r8 : 
                 (counter < 24) ? core_r8 : core_r8;

assign det3_r4 = (counter < 8) ? core_r10 : 
                 (counter < 16) ? core_r10 : 
                 (counter < 24) ? core_r9  : core_r9;

assign det3_r5 = (counter < 8) ? core_r11 : 
                 (counter < 16) ? core_r11 : 
                 (counter < 24) ? core_r11 : core_r10;

assign det3_r6 = (counter < 8) ? core_r13 : 
                 (counter < 16) ? core_r12 : 
                 (counter < 24) ? core_r12 : core_r12;

assign det3_r7 = (counter < 8) ? core_r14 : 
                 (counter < 16) ? core_r14 : 
                 (counter < 24) ? core_r13 : core_r13;

assign det3_r8 = (counter < 8) ? core_r15 : 
                 (counter < 16) ? core_r15 : 
                 (counter < 24) ? core_r15 : core_r14;


always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		mult3_in0 <= 0 ;
    mult3_in1 <= 0 ;
    mult3_in2 <= 0 ;
	end 
  else if(current_state == MULT && counter == 0) begin
		mult3_in0 <= rs_reg ;
    mult3_in1 <= rt_reg ;
    mult3_in2 <= 1 ;
	end
  else if(current_state == DET && (counter == 0 || counter == 8 || counter == 16 || counter == 24)) begin
		mult3_in0 <= det3_r0 ;
    mult3_in1 <= det3_r4 ;
    mult3_in2 <= det3_r8 ;
	end
  else if(current_state == DET && (counter == 1 || counter == 9 || counter == 17 || counter == 25)) begin
		mult3_in0 <= det3_r1 ;
    mult3_in1 <= det3_r5 ;
    mult3_in2 <= det3_r6 ;
	end
  else if(current_state == DET && (counter == 2 || counter == 10 || counter == 18 || counter == 26)) begin
		mult3_in0 <= det3_r2 ;
    mult3_in1 <= det3_r3 ;
    mult3_in2 <= det3_r7 ;
	end
  else if(current_state == DET && (counter == 3 || counter == 11 || counter == 19 || counter == 27)) begin
		mult3_in0 <= det3_r2 ;
    mult3_in1 <= det3_r4 ;
    mult3_in2 <= det3_r6 ;
	end
  else if(current_state == DET && (counter == 4 || counter == 12 || counter == 20 || counter == 28)) begin
		mult3_in0 <= det3_r1 ;
    mult3_in1 <= det3_r3 ;
    mult3_in2 <= det3_r8 ;
	end
  else if(current_state == DET && (counter == 5 || counter == 13 || counter == 21 || counter == 29)) begin
		mult3_in0 <= det3_r0 ;
    mult3_in1 <= det3_r5 ;
    mult3_in2 <= det3_r7 ;
	end
  else if(current_state == DET && counter == 7) begin
		mult3_in0 <= sub2_out ;
    mult3_in1 <= core_r0 ;
    mult3_in2 <= 1 ;
	end
  else if(current_state == DET && counter == 15) begin
		mult3_in0 <= sub2_out ;
    mult3_in1 <= core_r1 ;
    mult3_in2 <= 1 ;
	end
  else if(current_state == DET && counter == 23) begin
		mult3_in0 <= sub2_out ;
    mult3_in1 <= core_r2 ;
    mult3_in2 <= 1 ;
	end
  else if(current_state == DET && counter == 31) begin
		mult3_in0 <= sub2_out ;
    mult3_in1 <= core_r3 ;
    mult3_in2 <= 1 ;
	end
	else begin 
		mult3_in0 <= mult3_in0 ;
    mult3_in1 <= mult3_in1 ;
    mult3_in2 <= mult3_in2 ;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		add2_in0 <= 0 ;
    add2_in1 <= 0 ;
	end 
  else if(current_state == ADD && counter == 0) begin
		add2_in0 <= rs_reg ;
    add2_in1 <= rt_reg ;
  end
  else if(current_state == DET && (counter == 1 || counter == 9 || counter == 17 || counter == 25)) begin
		add2_in0 <= mult3_out ;
    add2_in1 <= 0 ;
  end
  else if(current_state == DET && (counter == 2 || counter == 10 || counter == 18 || counter == 26)) begin
		add2_in0 <= add2_in0 ;
    add2_in1 <= mult3_out ;
  end
  else if(current_state == DET && (counter == 3 || counter == 11 || counter == 19 || counter == 27)) begin
		add2_in0 <= add2_out ;
    add2_in1 <= mult3_out ;
  end
  else if(current_state == DET && counter == 8) begin
		add2_in0 <= mult3_out ;
    add2_in1 <= 0 ;
  end
  else if(current_state == DET && counter == 24) begin
		add2_in0 <= mult3_out ;
    add2_in1 <= temp ;
  end
  else if(current_state == DET && counter == 34) begin
		add2_in0 <= temp >>> (coeff_a << 1) ;
    add2_in1 <= coeff_b ;
  end
	else begin 
		add2_in0 <= add2_in0 ;
    add2_in1 <= add2_in1 ;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sub2_in0 <= 0 ;
    sub2_in1 <= 0 ;
	end 
  else if(current_state == SUB) begin
		sub2_in0 <= rs_reg ;
    sub2_in1 <= rt_reg ;
  end
  else if(current_state == DET && (counter == 4 || counter == 12 || counter == 20 || counter == 28)) begin
		sub2_in0 <= add2_out ;
    sub2_in1 <= mult3_out ;
  end
  else if(current_state == DET && (counter == 5 || counter == 13 || counter == 21 || counter == 29)) begin
		sub2_in0 <= sub2_out ;
    sub2_in1 <= mult3_out ;
  end
  else if(current_state == DET && (counter == 6 || counter == 14 || counter == 22 || counter == 30)) begin
		sub2_in0 <= sub2_out ;
    sub2_in1 <= mult3_out ;
  end
  else if(current_state == DET && counter == 16) begin
		sub2_in0 <= temp ;
    sub2_in1 <= mult3_out ;
  end
  else if(current_state == DET && counter == 32) begin
		sub2_in0 <= temp ;
    sub2_in1 <= mult3_out ;
  end
	else begin 
		sub2_in0 <= sub2_in0 ;
    sub2_in1 <= sub2_in1 ;
	end
end


//####################################################
//                  AXI Protocal
//####################################################
//1.Write Address
assign awid_m_inf    = 0 ;
assign awsize_m_inf  = 6'b001001 ;
assign awburst_m_inf = 4'b0101 ;
assign awlen_m_inf   = 0 ;
reg    aw_flag;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aw_flag <= 0 ;
    end 
    else if (current_state == INSTRUCTION_FETCH) begin
      aw_flag <= 0 ;
    end 
    else if (current_state == STORE && awvalid_m_inf) begin
      aw_flag <= 1 ;
    end 
    else begin
      aw_flag <= aw_flag ;
    end
end

reg [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf_s;
assign awaddr_m_inf = awaddr_m_inf_s ;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        awaddr_m_inf_s <= 0 ;
    end 
    else if (current_state == STORE) begin
        awaddr_m_inf_s <= {16'b0, (addr_target + 4096)} ;
    end
    else begin
        awaddr_m_inf_s <= 0 ; 
    end
end
reg [WRIT_NUMBER-1:0]                awvalid_m_inf_s;
assign awvalid_m_inf = awvalid_m_inf_s ;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        awvalid_m_inf_s <= 0 ;
    end
    else if (current_state == STORE && !aw_flag && !awready_m_inf) begin
        awvalid_m_inf_s <= 1 ;
    end
    else begin
        awvalid_m_inf_s <= 0 ; 
    end
end


//2.write data
reg    w_flag;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      w_flag <= 0 ;
    end 
    else if (current_state == STORE && wready_m_inf) begin
      w_flag <= 1 ;
    end  
    else if (current_state == INSTRUCTION_FETCH) begin
      w_flag <= 0 ;
    end 
    else begin
      w_flag <= w_flag ;
    end
end
assign wdata_m_inf = (opcode == 3'b011) ? rt_reg : 0 ;
assign wlast_m_inf = (wvalid_m_inf) ? 1 : 0 ;

reg [WRIT_NUMBER-1:0]                 wvalid_m_inf_s;
assign wvalid_m_inf = wvalid_m_inf_s ;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wvalid_m_inf_s <= 0;
    end
    else if (wready_m_inf == 0 && w_flag == 1) begin
        wvalid_m_inf_s <= 0;
    end
    else if (awready_m_inf == 1) begin
        wvalid_m_inf_s <= 1;
    end
    else begin
        wvalid_m_inf_s <= wvalid_m_inf_s ;
    end
end

// assign wvalid_m_inf = (!rst_n) ? 0 :
//                       (wready_m_inf == 0 && w_flag == 1) ? 0 :
//                       (awready_m_inf == 1) ? 1 :
//                       wvalid_m_inf;

//3.write response
reg [WRIT_NUMBER-1:0]                 bready_m_inf_s;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bready_m_inf_s <= 1;
    end
    else if (current_state == OUTPUT && wready_m_inf == 0 && w_flag == 1) begin
        bready_m_inf_s <= 0;
    end
    else begin
        bready_m_inf_s <= 1;
    end
end

// assign bready_m_inf = (current_state == OUTPUT && wready_m_inf == 0 && w_flag == 1) ? 0 : 1;


//4.read address
reg    ar_flag;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ar_flag <= 0 ;
    end 
    else if (current_state == FETCH_AXI && arvalid_ins) begin
      ar_flag <= 1 ;
    end 
    else if (current_state == INSTRUCTION_FETCH || current_state == OUTPUT) begin
      ar_flag <= 0 ;
    end 
    else if (current_state == LOAD && arvalid_data) begin
      ar_flag <= 1 ;
    end 
    else begin
      ar_flag <= ar_flag ;
    end
end
assign arid_m_inf    = 0 ;
assign arlen_m_inf   = 14'b11_1111_1000_0000 ;
assign arsize_m_inf  = 6'b001001 ;
assign arburst_m_inf = 4'b0101 ;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      araddr_ins <= 0 ;
    end 
    else if (current_state == FETCH_AXI && !ar_flag && !arready_m_inf[1]) begin
      if(current_pc <= 'h1f00) araddr_ins <= {16'b0, current_pc} ;
      else araddr_ins <= {16'b0, 16'b0001111100000000} ;
    end 
    else begin
      araddr_ins <= 0 ;
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        araddr_data <= 0 ;
    end 
    else if (current_state == LOAD) begin
        araddr_data <= {16'b0, (addr_target + 4096)} ;
    end
    else begin
        araddr_data <= 0 ; 
    end
end
assign araddr_m_inf  = {araddr_ins, araddr_data} ;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      arvalid_ins <= 0 ;
    end 
    else if (current_state == FETCH_AXI && !ar_flag && !arready_m_inf[1]) begin
      arvalid_ins <= 1 ;
    end 
    else begin
      arvalid_ins <= 0 ;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        arvalid_data <= 0 ;
    end
    else if (current_state == LOAD && !ar_flag && !arready_m_inf[0]) begin
        arvalid_data <= 1 ;
    end
    else begin
        arvalid_data <= 0 ; 
    end
end
assign arvalid_m_inf = {arvalid_ins, arvalid_data} ;


//5.read data
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rready_ins <= 0 ;
    end 
    else if (rlast_m_inf[1] == 1) begin
        rready_ins <= 0 ;
    end
    else if (arready_m_inf[1] == 1) begin
        rready_ins <= 1 ;
    end
    else begin
        rready_ins <= rready_ins ; 
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rready_data <= 0 ;
    end 
    else if (rlast_m_inf[0] == 1) begin
        rready_data <= 0 ;
    end
    else if (arready_m_inf[0] == 1) begin
        rready_data <= 1 ;
    end
    else begin
        rready_data <= rready_data ; 
    end
end
assign rready_m_inf  = {rready_ins, rready_data} ;


//####################################################
//                      SRAM
//####################################################
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        DI_cache <= 0;
    end 
    else if (current_state == LOAD_INS || rvalid_m_inf[1]) begin
        DI_cache <= rdata_m_inf[31:16];
    end 
    else begin
        DI_cache <= rdata_m_inf[15:0]; //maybe_wrong
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        WEB_Cache <= 1;
    end 
    else if (current_state == LOAD_INS || next_state == LOAD_INS) begin
        WEB_Cache <= 0;
    end 
    else begin
        WEB_Cache <= 1;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) Addr_cache <= 0 ;
    else if(current_state == IDLE) Addr_cache <= 0 ;
    else if(current_state == LOAD_INS) Addr_cache <= Addr_cache + 1 ;
    else if(current_state == INSTRUCTION_FETCH_DELAY1) Addr_cache <= cache_counter ;
    else Addr_cache <= Addr_cache ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) cache_counter <= 0 ;
    else if(current_state == FETCH_AXI && current_pc <= 'h1f00) cache_counter <= 0 ;
    else if(current_state == FETCH_AXI && current_pc > 'h1f00) cache_counter <= ('d127 - (('h1fff - current_pc) >> 1)) ;
    else if(current_state == INSTRUCTION_DECODE_DELAY1) begin
      if(opcode == 4 && counter == 0 && rs_reg == rt_reg) cache_counter <= cache_counter + 1 + imm ;
      else cache_counter <= cache_counter + 1 ;
    end
    else cache_counter <= cache_counter ;
end


//####################################################
//                   Instruction
//####################################################
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) current_pc <= 16'h1000 ;
    else if(current_state == INSTRUCTION_DECODE_DELAY1) current_pc <= next_pc ;
end

// always@(*) begin
// 	if(!rst_n) next_pc = 16'h1000 ;
// 	else if(current_state == INSTRUCTION_DECODE)begin
//     if(opcode == 3'b100)begin
//         if(rs_reg == rt_reg) next_pc = current_pc + 2 + imm * 2 ;
//         else next_pc = current_pc + 2 ;
// 		end
// 		else next_pc = current_pc + 2 ;
// 	end
// end

always @(*) begin
	case(opcode)
		3'b100 : begin
			if(rs_reg == rt_reg) begin
				next_pc = current_pc + 2 + imm*2;
			end
			else begin
				next_pc = current_pc + 2;
			end
		end
		default : next_pc = current_pc + 2;
	endcase
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r0 <= 0 ;
    else if(rt == 0 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r0 <= rdata_m_inf[15:0] ;
    else if(rd == 0 && current_state ==  ADD && counter == 1) core_r0 <= add2_out[15:0] ;
    else if(rd == 0 && current_state == MULT && counter == 1) core_r0 <= mult3_out[15:0] ;
    else if(rd == 0 && current_state ==  SUB && counter == 1) core_r0 <= sub2_out[15:0] ;
    else if(rd == 0 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r0 <= 1 ;
    else if(rd == 0 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r0 <= 0 ;
    else if(current_state == DET && counter == 35) begin
      if(add2_out > 32767) begin
        core_r0 <= 16'b0111_1111_1111_1111 ;
      end
      else if(add2_out < (-32768)) begin
        core_r0 <= 16'b1000_0000_0000_0000 ;
      end
      else core_r0 <= add2_out ;
	  end
    else core_r0 <= core_r0 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r1 <= 0 ;
    else if(rt == 1 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r1 <= rdata_m_inf[15:0] ;
    else if(rd == 1 && current_state ==  ADD && counter == 1) core_r1 <= add2_out[15:0] ;
    else if(rd == 1 && current_state == MULT && counter == 1) core_r1 <= mult3_out[15:0] ;
    else if(rd == 1 && current_state ==  SUB && counter == 1) core_r1 <= sub2_out[15:0] ;
    else if(rd == 1 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r1 <= 1 ;
    else if(rd == 1 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r1 <= 0 ;
    else core_r1 <= core_r1 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r2 <= 0 ;
    else if(rt == 2 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r2 <= rdata_m_inf[15:0] ;
    else if(rd == 2 && current_state ==  ADD && counter == 1) core_r2 <= add2_out[15:0] ;
    else if(rd == 2 && current_state == MULT && counter == 1) core_r2 <= mult3_out[15:0] ;
    else if(rd == 2 && current_state ==  SUB && counter == 1) core_r2 <= sub2_out[15:0] ;
    else if(rd == 2 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r2 <= 1 ;
    else if(rd == 2 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r2 <= 0 ;
    else core_r2 <= core_r2 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r3 <= 0 ;
    else if(rt == 3 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r3 <= rdata_m_inf[15:0] ;
    else if(rd == 3 && current_state ==  ADD && counter == 1) core_r3 <= add2_out[15:0] ;
    else if(rd == 3 && current_state == MULT && counter == 1) core_r3 <= mult3_out[15:0] ;
    else if(rd == 3 && current_state ==  SUB && counter == 1) core_r3 <= sub2_out[15:0] ;
    else if(rd == 3 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r3 <= 1 ;
    else if(rd == 3 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r3 <= 0 ;
    else core_r3 <= core_r3 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r4 <= 0 ;
    else if(rt == 4 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r4 <= rdata_m_inf[15:0] ;
    else if(rd == 4 && current_state ==  ADD && counter == 1) core_r4 <= add2_out[15:0] ;
    else if(rd == 4 && current_state == MULT && counter == 1) core_r4 <= mult3_out[15:0] ;
    else if(rd == 4 && current_state ==  SUB && counter == 1) core_r4 <= sub2_out[15:0] ;
    else if(rd == 4 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r4 <= 1 ;
    else if(rd == 4 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r4 <= 0 ;
    else core_r4 <= core_r4 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r5 <= 0 ;
    else if(rt == 5 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r5 <= rdata_m_inf[15:0] ;
    else if(rd == 5 && current_state ==  ADD && counter == 1) core_r5 <= add2_out[15:0] ;
    else if(rd == 5 && current_state == MULT && counter == 1) core_r5 <= mult3_out[15:0] ;
    else if(rd == 5 && current_state ==  SUB && counter == 1) core_r5 <= sub2_out[15:0] ;
    else if(rd == 5 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r5 <= 1 ;
    else if(rd == 5 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r5 <= 0 ;
    else core_r5 <= core_r5 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r6 <= 0 ;
    else if(rt == 6 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r6 <= rdata_m_inf[15:0] ;
    else if(rd == 6 && current_state ==  ADD && counter == 1) core_r6 <= add2_out[15:0] ;
    else if(rd == 6 && current_state == MULT && counter == 1) core_r6 <= mult3_out[15:0] ;
    else if(rd == 6 && current_state ==  SUB && counter == 1) core_r6 <= sub2_out[15:0] ;
    else if(rd == 6 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r6 <= 1 ;
    else if(rd == 6 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r6 <= 0 ;
    else core_r6 <= core_r6 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r7 <= 0 ;
    else if(rt == 7 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r7 <= rdata_m_inf[15:0] ;
    else if(rd == 7 && current_state ==  ADD && counter == 1) core_r7 <= add2_out[15:0] ;
    else if(rd == 7 && current_state == MULT && counter == 1) core_r7 <= mult3_out[15:0] ;
    else if(rd == 7 && current_state ==  SUB && counter == 1) core_r7 <= sub2_out[15:0] ;
    else if(rd == 7 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r7 <= 1 ;
    else if(rd == 7 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r7 <= 0 ;
    else core_r7 <= core_r7 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r8 <= 0 ;
    else if(rt == 8 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r8 <= rdata_m_inf[15:0] ;
    else if(rd == 8 && current_state ==  ADD && counter == 1) core_r8 <= add2_out[15:0] ;
    else if(rd == 8 && current_state == MULT && counter == 1) core_r8 <= mult3_out[15:0] ;
    else if(rd == 8 && current_state ==  SUB && counter == 1) core_r8 <= sub2_out[15:0] ;
    else if(rd == 8 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r8 <= 1 ;
    else if(rd == 8 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r8 <= 0 ;
    else core_r8 <= core_r8 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r9 <= 0 ;
    else if(rt == 9 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r9 <= rdata_m_inf[15:0] ;
    else if(rd == 9 && current_state ==  ADD && counter == 1) core_r9 <= add2_out[15:0] ;
    else if(rd == 9 && current_state == MULT && counter == 1) core_r9 <= mult3_out[15:0] ;
    else if(rd == 9 && current_state ==  SUB && counter == 1) core_r9 <= sub2_out[15:0] ;
    else if(rd == 9 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r9 <= 1 ;
    else if(rd == 9 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r9 <= 0 ;
    else core_r9 <= core_r9 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r10 <= 0 ;
    else if(rt == 10 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r10 <= rdata_m_inf[15:0] ;
    else if(rd == 10 && current_state ==  ADD && counter == 1) core_r10 <= add2_out[15:0] ;
    else if(rd == 10 && current_state == MULT && counter == 1) core_r10 <= mult3_out[15:0] ;
    else if(rd == 10 && current_state ==  SUB && counter == 1) core_r10 <= sub2_out[15:0] ;
    else if(rd == 10 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r10 <= 1 ;
    else if(rd == 10 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r10 <= 0 ;
    else core_r10 <= core_r10 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r11 <= 0 ;
    else if(rt == 11 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r11 <= rdata_m_inf[15:0] ;
    else if(rd == 11 && current_state ==  ADD && counter == 1) core_r11 <= add2_out[15:0] ;
    else if(rd == 11 && current_state == MULT && counter == 1) core_r11 <= mult3_out[15:0] ;
    else if(rd == 11 && current_state ==  SUB && counter == 1) core_r11 <= sub2_out[15:0] ;
    else if(rd == 11 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r11 <= 1 ;
    else if(rd == 11 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r11 <= 0 ;
    else core_r11 <= core_r11 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r12 <= 0 ;
    else if(rt == 12 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r12 <= rdata_m_inf[15:0] ;
    else if(rd == 12 && current_state ==  ADD && counter == 1) core_r12 <= add2_out[15:0] ;
    else if(rd == 12 && current_state == MULT && counter == 1) core_r12 <= mult3_out[15:0] ;
    else if(rd == 12 && current_state ==  SUB && counter == 1) core_r12 <= sub2_out[15:0] ;
    else if(rd == 12 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r12 <= 1 ;
    else if(rd == 12 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r12 <= 0 ;
    else core_r12 <= core_r12 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r13 <= 0 ;
    else if(rt == 13 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r13 <= rdata_m_inf[15:0] ;
    else if(rd == 13 && current_state ==  ADD && counter == 1) core_r13 <= add2_out[15:0] ;
    else if(rd == 13 && current_state == MULT && counter == 1) core_r13 <= mult3_out[15:0] ;
    else if(rd == 13 && current_state ==  SUB && counter == 1) core_r13 <= sub2_out[15:0] ;
    else if(rd == 13 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r13 <= 1 ;
    else if(rd == 13 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r13 <= 0 ;
    else core_r13 <= core_r13 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r14 <= 0 ;
    else if(rt == 14 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r14 <= rdata_m_inf[15:0] ;
    else if(rd == 14 && current_state ==  ADD && counter == 1) core_r14 <= add2_out[15:0] ;
    else if(rd == 14 && current_state == MULT && counter == 1) core_r14 <= mult3_out[15:0] ;
    else if(rd == 14 && current_state ==  SUB && counter == 1) core_r14 <= sub2_out[15:0] ;
    else if(rd == 14 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r14 <= 1 ;
    else if(rd == 14 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r14 <= 0 ;
    else core_r14 <= core_r14 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) core_r15 <= 0 ;
    else if(rt == 15 && current_state == LOAD && rvalid_m_inf[0] == 1) core_r15 <= rdata_m_inf[15:0] ;
    else if(rd == 15 && current_state ==  ADD && counter == 1) core_r15 <= add2_out[15:0] ;
    else if(rd == 15 && current_state == MULT && counter == 1) core_r15 <= mult3_out[15:0] ;
    else if(rd == 15 && current_state ==  SUB && counter == 1) core_r15 <= sub2_out[15:0] ;
    else if(rd == 15 && current_state == SET_LESS_THAN &&  (rs_reg < rt_reg)) core_r15 <= 1 ;
    else if(rd == 15 && current_state == SET_LESS_THAN && !(rs_reg < rt_reg)) core_r15 <= 0 ;
    else core_r15 <= core_r15 ;
end

assign opcode  = instruction[15:13] ;
assign rs 	   = instruction[12:9] ;
assign rt 	   = instruction[8:5] ;
assign rd 	   = instruction[4:1] ;
assign imm 	   = instruction[4:0] ;
assign func    = instruction[0] ;
assign coeff_a = instruction[12:9] ;
assign coeff_b = instruction[8:0] ;

// rs_reg, rt_reg
always@(*) begin
	if(rs == 0) rs_reg = core_r0 ;
  else if(rs ==  1) rs_reg = core_r1 ;
  else if(rs ==  2) rs_reg = core_r2 ;
  else if(rs ==  3) rs_reg = core_r3 ;
  else if(rs ==  4) rs_reg = core_r4 ;
  else if(rs ==  5) rs_reg = core_r5 ;
  else if(rs ==  6) rs_reg = core_r6 ;
  else if(rs ==  7) rs_reg = core_r7 ;
  else if(rs ==  8) rs_reg = core_r8 ;
  else if(rs ==  9) rs_reg = core_r9 ;
  else if(rs == 10) rs_reg = core_r10 ;
  else if(rs == 11) rs_reg = core_r11 ;
  else if(rs == 12) rs_reg = core_r12 ;
  else if(rs == 13) rs_reg = core_r13 ;
  else if(rs == 14) rs_reg = core_r14 ;
  else if(rs == 15) rs_reg = core_r15 ;
  else begin
    rs_reg = 0 ;
	end
end

always@(*) begin
	if(rt == 0) rt_reg = core_r0 ;
  else if(rt ==  1) rt_reg = core_r1 ;
  else if(rt ==  2) rt_reg = core_r2 ;
  else if(rt ==  3) rt_reg = core_r3 ;
  else if(rt ==  4) rt_reg = core_r4 ;
  else if(rt ==  5) rt_reg = core_r5 ;
  else if(rt ==  6) rt_reg = core_r6 ;
  else if(rt ==  7) rt_reg = core_r7 ;
  else if(rt ==  8) rt_reg = core_r8 ;
  else if(rt ==  9) rt_reg = core_r9 ;
  else if(rt == 10) rt_reg = core_r10 ;
  else if(rt == 11) rt_reg = core_r11 ;
  else if(rt == 12) rt_reg = core_r12 ;
  else if(rt == 13) rt_reg = core_r13 ;
  else if(rt == 14) rt_reg = core_r14 ;
  else if(rt == 15) rt_reg = core_r15 ;
  else begin
    rt_reg = 0 ;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		instruction <= 0 ;
	end 
  else if(current_state == INSTRUCTION_FETCH) begin
    instruction <= DO_cache ;
  end
	else begin 
		instruction <= instruction ;
	end
end

//####################################################
//                      Output
//####################################################
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		IO_stall <= 1 ;
	end 
  else if(current_state == INSTRUCTION_FETCH_DELAY1) IO_stall <= 1 ;
  // else if(current_state == 6 && next_state != 6) IO_stall <= 0 ;
  else if(next_state == OUTPUT) IO_stall <= 0 ;
  // else if(current_state == LOAD && rlast_m_inf[0] == 1) IO_stall <= 0 ;
  // else if(counter == 1 && !(current_state == LOAD)) IO_stall <= 0 ;
	else begin 
		IO_stall <= 1 ;
	end
end


SRAM_128x16 cache(
  .A0(Addr_cache[0]), .A1(Addr_cache[1]), .A2(Addr_cache[2]), .A3(Addr_cache[3]), .A4(Addr_cache[4]), .A5(Addr_cache[5]), 
  .A6(Addr_cache[6]), .DO0(DO_cache[0]), .DO1(DO_cache[1]), .DO2(DO_cache[2]), .DO3(DO_cache[3]), .DO4(DO_cache[4]), 
  .DO5(DO_cache[5]), .DO6(DO_cache[6]), .DO7(DO_cache[7]), .DO8(DO_cache[8]), .DO9(DO_cache[9]), .DO10(DO_cache[10]), 
  .DO11(DO_cache[11]), .DO12(DO_cache[12]), .DO13(DO_cache[13]), .DO14(DO_cache[14]),.DO15(DO_cache[15]),
  .DI0(DI_cache[0]), .DI1(DI_cache[1]), .DI2(DI_cache[2]), .DI3(DI_cache[3]), .DI4(DI_cache[4]), .DI5(DI_cache[5]), 
  .DI6(DI_cache[6]), .DI7(DI_cache[7]), .DI8(DI_cache[8]), .DI9(DI_cache[9]), .DI10(DI_cache[10]), .DI11(DI_cache[11]), 
  .DI12(DI_cache[12]), .DI13(DI_cache[13]),.DI14(DI_cache[14]),.DI15(DI_cache[15]),
	.CK(clk),.WEB(WEB_Cache),.OE(1'b1), .CS(1'b1));
endmodule

module Mult3 (
	input  signed [50:0]  mult3_in0, 
	input  signed [15:0]  mult3_in1,
	input  signed [15:0]  mult3_in2,
	output signed [66:0]  mult3_out
	) ;

 assign mult3_out = mult3_in0 * mult3_in1 * mult3_in2 ;
endmodule

module Add2 (
	input  signed [66:0]  add2_in0, 
	input  signed [66:0]  add2_in1,
	output signed [68:0]  add2_out
	) ;

 assign add2_out = add2_in0 + add2_in1 ;
endmodule

module Sub2 (
	input  signed [66:0]  sub2_in0, 
	input  signed [66:0]  sub2_in1,
	output signed [68:0]  sub2_out
	) ;

 assign sub2_out = sub2_in0 - sub2_in1 ;
endmodule















