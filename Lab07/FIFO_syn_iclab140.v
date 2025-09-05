module FIFO_syn #(parameter WIDTH=32, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);


input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
input clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;

input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;

wire [WIDTH-1:0] rdata_q;

reg fifo_clk3_flag4_pre;
reg fifo_clk3_flag4;



// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

reg flag;
always @ (posedge rclk) begin 
	flag <= rinc ;
end
// rdata
//  Add one more register stage to rdata
always @(posedge rclk, negedge rst_n) begin
    if (!rst_n) begin
        rdata <= 0;
    end
    else if (rinc || flag) begin
        rdata <= rdata_q;
    end
end

//==========================================
//             reg
//==========================================
wire write_enable;
wire wen_a;
// reg winc_q;
wire wfull_q;

wire rempty_q;
wire read_enable;


wire [6:0]w_addr_grey;
wire [6:0]r_addr_grey;

reg  [6:0]w_addr;
reg  [6:0]r_addr;
// pointer
wire [$clog2(WORDS):0] rptr_q;
wire [$clog2(WORDS):0] wptr_q;
reg  [$clog2(WORDS):0] wq2_rptr;
reg  [$clog2(WORDS):0] rq2_wptr;

// counter
reg [8:0]counter;
reg [8:0]cnt_read;
//----- ip --------------------------------
NDFF_BUS_syn #(.WIDTH(7)) sync_w2r (.D(wptr), .Q(rq2_wptr), .clk(rclk), .rst_n(rst_n));
NDFF_BUS_syn #(.WIDTH(7)) sync_r2w (.D(rptr), .Q(wq2_rptr), .clk(wclk), .rst_n(rst_n));

//=============================================
//            WRITE
//=============================================
assign write_enable = (winc && !wfull); //Controls whether FIFO write is performed
assign wen_a = !write_enable;

//===============gray code====================
assign w_addr_grey = w_addr + write_enable;
assign wptr_q  = (w_addr_grey >> 1) ^ w_addr_grey;
//===============gray code====================
assign wfull_q = (wptr_q == {~wq2_rptr[$clog2(WORDS):$clog2(WORDS)-1], wq2_rptr[$clog2(WORDS)-2:0]});
assign clk2_fifo_flag3 = (counter == 256) ;

always @(posedge wclk or negedge rst_n) begin
    if(!rst_n) counter <= 0;
    else if(clk2_fifo_flag3) counter <= 0;
	else if (winc) counter <= counter + 1;
	else counter <= counter ;
end
always @(posedge wclk or negedge rst_n) begin
    if(!rst_n)      wfull <= 0;
    else if(fifo_clk3_flag3)    wfull <= 0;
    else            wfull <= wfull_q;
end
always @(posedge wclk or negedge rst_n) begin
    if(!rst_n)     w_addr <= 0;
    // else if(fifo_clk3_flag3)    w_addr <= 0;
    else           w_addr <= w_addr_grey;
end
always @(posedge wclk or negedge rst_n) begin
    if(!rst_n)      wptr <= 0;
    // else if(fifo_clk3_flag3)    wptr <= 0;
    else            wptr <= wptr_q;
end
//===================================================
//              READ
//===================================================
assign read_enable = (rinc & ~rempty); //When you request to read data (rinc = 1) and the FIFO is not empty (rempty = 0), reading is allowed.

//===============gray code====================
assign r_addr_grey  = r_addr + read_enable;
assign rptr_q   = (r_addr_grey >> 1) ^ r_addr_grey;
//===============gray code====================
always @(posedge rclk or negedge rst_n) begin //optimization : just for debug
    if(!rst_n) cnt_read <= 0;
    else if(fifo_clk3_flag3) cnt_read <= 0;
    else cnt_read <= cnt_read + read_enable;
end

always @(posedge rclk or negedge rst_n) begin
    if(!rst_n)  rptr  <= 0;
    // else if(fifo_clk3_flag3)    rptr  <= 0;
    else        rptr  <= rptr_q;
end
always @(posedge rclk or negedge rst_n) begin
    if(!rst_n)  r_addr <= 0;
    // else if(fifo_clk3_flag3)    r_addr <= 0;
    else        r_addr <= r_addr + read_enable;
end
always @ (*) begin 
	if (rptr == rq2_wptr) rempty = 1 ; 
	else rempty = 0 ;
end
// ===============================================================
//  					 fifo_clk3_flag4
// ===============================================================
always @ (posedge rclk or negedge rst_n) begin 
	if (!rst_n) fifo_clk3_flag4 <= 0 ;
	else if (flag) fifo_clk3_flag4 <= 1 ;
	else fifo_clk3_flag4 <= 0 ;
end


DUAL_64X32X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(wen_a), 
    .WEBN(1'b1), // READ ONLY
    .CSA(1'b1),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(w_addr[0]),
    .A1(w_addr[1]),
    .A2(w_addr[2]),
    .A3(w_addr[3]),
    .A4(w_addr[4]),
    .A5(w_addr[5]),
    .B0(r_addr[0]),
    .B1(r_addr[1]),
    .B2(r_addr[2]),
    .B3(r_addr[3]),
    .B4(r_addr[4]),
    .B5(r_addr[5]),
    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),
    .DIA8(wdata[8]),
    .DIA9(wdata[9]),
    .DIA10(wdata[10]),
    .DIA11(wdata[11]),
    .DIA12(wdata[12]),
    .DIA13(wdata[13]),
    .DIA14(wdata[14]),
    .DIA15(wdata[15]),
    .DIA16(wdata[16]),
    .DIA17(wdata[17]),
    .DIA18(wdata[18]),
    .DIA19(wdata[19]),
    .DIA20(wdata[20]),
    .DIA21(wdata[21]),
    .DIA22(wdata[22]),
    .DIA23(wdata[23]),
    .DIA24(wdata[24]),
    .DIA25(wdata[25]),
    .DIA26(wdata[26]),
    .DIA27(wdata[27]),
    .DIA28(wdata[28]),
    .DIA29(wdata[29]),
    .DIA30(wdata[30]),
    .DIA31(wdata[31]),
    .DIB0(1'b0), // READ ONLY
    .DIB1(1'b0), // READ ONLY
    .DIB2(1'b0), // READ ONLY
    .DIB3(1'b0), // READ ONLY
    .DIB4(1'b0), // READ ONLY
    .DIB5(1'b0), // READ ONLY
    .DIB6(1'b0), // READ ONLY
    .DIB7(1'b0), // READ ONLY
    .DIB8(1'b0), // READ ONLY
    .DIB9(1'b0), // READ ONLY
    .DIB10(1'b0), // READ ONLY
    .DIB11(1'b0), // READ ONLY
    .DIB12(1'b0), // READ ONLY
    .DIB13(1'b0), // READ ONLY
    .DIB14(1'b0), // READ ONLY
    .DIB15(1'b0), // READ ONLY
    .DIB16(1'b0), // READ ONLY
    .DIB17(1'b0), // READ ONLY
    .DIB18(1'b0), // READ ONLY
    .DIB19(1'b0), // READ ONLY
    .DIB20(1'b0), // READ ONLY
    .DIB21(1'b0), // READ ONLY
    .DIB22(1'b0), // READ ONLY
    .DIB23(1'b0), // READ ONLY
    .DIB24(1'b0), // READ ONLY
    .DIB25(1'b0), // READ ONLY
    .DIB26(1'b0), // READ ONLY
    .DIB27(1'b0), // READ ONLY
    .DIB28(1'b0), // READ ONLY
    .DIB29(1'b0), // READ ONLY
    .DIB30(1'b0), // READ ONLY
    .DIB31(1'b0), // READ ONLY
    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7]),
    .DOB8(rdata_q[8]),
    .DOB9(rdata_q[9]),
    .DOB10(rdata_q[10]),
    .DOB11(rdata_q[11]),
    .DOB12(rdata_q[12]),
    .DOB13(rdata_q[13]),
    .DOB14(rdata_q[14]),
    .DOB15(rdata_q[15]),
    .DOB16(rdata_q[16]),
    .DOB17(rdata_q[17]),
    .DOB18(rdata_q[18]),
    .DOB19(rdata_q[19]),
    .DOB20(rdata_q[20]),
    .DOB21(rdata_q[21]),
    .DOB22(rdata_q[22]),
    .DOB23(rdata_q[23]),
    .DOB24(rdata_q[24]),
    .DOB25(rdata_q[25]),
    .DOB26(rdata_q[26]),
    .DOB27(rdata_q[27]),
    .DOB28(rdata_q[28]),
    .DOB29(rdata_q[29]),
    .DOB30(rdata_q[30]),
    .DOB31(rdata_q[31])
);

endmodule
