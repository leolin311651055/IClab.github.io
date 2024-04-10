//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Tzu-Yun Huang
//	 Editor		: Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : pseudo_DRAM.v
//   Module Name : pseudo_DRAM
//   Release version : v3.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module pseudo_DRAM(
	clk, rst_n,
	AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP
);

input clk, rst_n;
// write address channel
input [31:0] AW_ADDR;
input AW_VALID;
output reg AW_READY;
// write data channel
input W_VALID;
input [63:0] W_DATA;
output reg W_READY;
// write response channel
output reg B_VALID;
output reg [1:0] B_RESP;
input B_READY;
// read address channel
input [31:0] AR_ADDR;
input AR_VALID;
output reg AR_READY;
// read data channel
output reg [63:0] R_DATA;
output reg R_VALID;
output reg [1:0] R_RESP;
input R_READY;
reg [31:0] AR_ADDR_temp,AW_ADDR_temp;
//================================================================
// parameters & integer
//================================================================
real CYCLE = `CYCLE_TIME;
parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
parameter OKAY   = 2'b00;
parameter EXOKAY = 2'b01;
parameter SLVERR = 2'b10;
parameter DECERR = 2'b11;

//================================================================
// wire & registers 
//================================================================
reg [63:0] DRAM[0:8191];
initial begin
	$readmemh(DRAM_p_r, DRAM);
end

//////////////////////////////////////////////////////////////////////
// Write your own task here
//////////////////////////////////////////////////////////////////////

//Read
reg cnt_r;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		AR_READY <= 0;
		AR_ADDR_temp <= 0;
		cnt_r <= 0;
	end
	else if(AR_VALID == 1 & cnt_r == 0) begin
		AR_READY <= 1;
		AR_ADDR_temp <= AR_ADDR;
		cnt_r <= 1;
	end
	else begin
		AR_READY <= 0;
		AR_ADDR_temp <= 0;
		cnt_r <= 0;
	end
end

always@(*) begin
	if(!rst_n) R_VALID = 0;
	else if(R_READY == 1) R_VALID = 1;
	else R_VALID = 0;
end

always@(*) begin
	if(!rst_n) R_DATA = 0;
	else if(R_VALID == 1) R_DATA = DRAM[AR_ADDR_temp];
	else R_DATA = 0;
end


//Write
reg cnt_aw,cnt_w;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		AW_READY <= 0;
		cnt_aw <= 0;
		AW_ADDR_temp <= 0;
	end
	else if(AW_VALID == 1 & cnt_aw == 0) begin
		AW_READY <= 1;
		AW_ADDR_temp <= AW_ADDR;
		cnt_aw <= 1;
	end
	else begin
		AW_READY <= 0;
		cnt_aw <= 0;
		AW_ADDR_temp <= 0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		W_READY <= 0;
		cnt_w <= 0;
	end
	else if(AW_READY == 1 & cnt_w == 0) begin
		W_READY <= 1;
		cnt_w <= 1;
	end
	else if(B_READY == 0)begin
		W_READY <= 0;
		cnt_w <= 0;
	end
end

always@(*) begin
	if(W_VALID == 1)  DRAM[AW_ADDR_temp] = W_DATA;
end


//Response
reg cnt_b;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		B_VALID <= 0;
		cnt_b <= 0;
	end
	else if(B_READY == 1 & W_VALID == 1 & cnt_b == 0) begin
		//#(CYCLE);
		B_VALID <= 1;
		cnt_b <= 1;
	end
	else if(B_READY == 1 & R_VALID == 1 & cnt_b == 0) begin
		//#(CYCLE);
		B_VALID <= 1;
		cnt_b <= 1;
	end
	else begin
		B_VALID <= 0;
		cnt_b <= 0;
	end
end

always@(*) begin
	if(!rst_n) B_RESP = 0;
	else if(B_VALID == 1) B_RESP = OKAY;
	else B_RESP = 0;
end

always@(*) begin
	if(!rst_n) R_RESP = 0;
	else if(R_VALID == 1) R_RESP = OKAY;
	else R_RESP = 0;
end





//////////////////////////////////////////////////////////////////////

task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                 Error message from pseudo_SD.v                        *");
end endtask

endmodule
