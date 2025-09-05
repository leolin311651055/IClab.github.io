module MVDM(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    in_data,
    // output signals
    out_valid,
    out_sad
    );

input clk;
input rst_n;
input in_valid;
input in_valid2;
input [11:0] in_data;

output reg out_valid;
output reg out_sad;

reg [6:0] Addr_BI_0;
reg [15:0] DI_BI_0;
reg [15:0] DO_BI_0;
reg WEB_BI_0;

reg [6:0] Addr_BI_1;
reg [15:0] DI_BI_1;
reg [15:0] DO_BI_1;
reg WEB_BI_1;

reg [6:0] Addr_BI_2;
reg [15:0] DI_BI_2;
reg [15:0] DO_BI_2;
reg WEB_BI_2;

reg [6:0] Addr_BI_3;
reg [15:0] DI_BI_3;
reg [15:0] DO_BI_3;
reg WEB_BI_3;

reg [13:0] Addr_first_Img;
reg [7:0] DI_first_Img;
reg [7:0] DO_first_Img;
reg WEB_first;

reg [13:0] Addr_second_Img;
reg [7:0] DI_second_Img;
reg [7:0] DO_second_Img;
reg WEB_second;

parameter IDLE            = 0;
parameter IN_IMG_0        = 1;
parameter IN_IMG_1        = 2;
parameter IN_MV           = 3;
parameter BI_LOAD_FIRST_0 = 4;
parameter BI_COMPUTE_0    = 5;
parameter BI_LOAD_FIRST_1 = 6;
parameter BI_COMPUTE_1    = 7;
parameter SAD             = 8;
parameter OUT             = 9;

integer i, j, k;

reg  [6:0] counter_1;
reg  [6:0] counter_2;
reg  [8:0]  counter_3;
reg  [8:0]  counter_4;
reg  [8:0]  current_state;
reg  [8:0]  next_state;

reg  [11:0] Mv_0 [0:1][0:1];      //L0, first information and second information ; x and y
reg  [11:0] Mv_1 [0:1][0:1];      //L1, first information and second information ; x and y


reg  [7:0]  previous_node_0 [0:10];
reg  [3:0]  f0_0, f1_0;
reg  [7:0]  p0_0, p1_0, p2_0, p3_0;
wire [7:0]  f0_0_span, f1_0_span;
wire [7:0]  f0x1_0; //Optimize : It is fp3_0, maybe it can be merged
reg  [8:0]  fp0_0, fp1_0, fp2_0, fp3_0;

assign f0_0_span = {f0_0,4'b0};
assign f1_0_span = {f1_0,4'b0};
assign f0x1_0    = f0_0 * f1_0;

reg  [7:0]  previous_node_1 [0:10];
reg  [3:0]  f0_1, f1_1;
reg  [7:0]  p0_1, p1_1, p2_1, p3_1;
wire [7:0]  f0_1_span, f1_1_span;
wire [7:0]  f0x1_1; //Optimize : It is fp3_0, maybe it can be merged
reg  [8:0]  fp0_1, fp1_1, fp2_1, fp3_1;

reg  [23:0] accumulation_0;
reg  [23:0] accumulation_1;

wire [19:0] accumulation_0_debug_int; //debug
wire [19:0] accumulation_1_debug_int; //debug

assign accumulation_0_debug_int = accumulation_0[23:8]; //debug
assign accumulation_1_debug_int = accumulation_1[23:8]; //debug

reg  [27:0] SAD_0;
reg  [27:0] SAD_1;

wire [19:0] SAD_0_debug_int; //debug
wire [19:0] SAD_1_debug_int; //debug

assign SAD_0_debug_int = SAD_0[23:8]; //debug
assign SAD_1_debug_int = SAD_1[23:8]; //debug

assign f0_1_span = {f0_1,4'b0};
assign f1_1_span = {f1_1,4'b0};
assign f0x1_1    = f0_1 * f1_1;

wire [7:0]indata_debug; //debug 2144
assign indata_debug = in_data[11:4];

wire [1:0] index_L0 [0:8][0:1];
assign index_L0[0] = {2'd0, 2'd0};
assign index_L0[1] = {2'd1, 2'd0};
assign index_L0[2] = {2'd2, 2'd0};
assign index_L0[3] = {2'd0, 2'd1};
assign index_L0[4] = {2'd1, 2'd1};
assign index_L0[5] = {2'd2, 2'd1};
assign index_L0[6] = {2'd0, 2'd2};
assign index_L0[7] = {2'd1, 2'd2};
assign index_L0[8] = {2'd2, 2'd2};

wire [1:0] index_L1 [0:8][0:1];
assign index_L1[0] = {2'd2, 2'd2};
assign index_L1[1] = {2'd1, 2'd2};
assign index_L1[2] = {2'd0, 2'd2};
assign index_L1[3] = {2'd2, 2'd1};
assign index_L1[4] = {2'd1, 2'd1};
assign index_L1[5] = {2'd0, 2'd1};
assign index_L1[6] = {2'd2, 2'd0};
assign index_L1[7] = {2'd1, 2'd0};
assign index_L1[8] = {2'd0, 2'd0};
//=======================================================
//                      FSM
//=======================================================
always@(*) begin
    if(!rst_n) next_state = IDLE;
    else if(current_state == IDLE) begin
        if(in_valid) next_state = IN_IMG_0;
        else if(in_valid2) next_state = IN_MV;
        else next_state = current_state;
    end
    else if(current_state == IN_IMG_0) begin
        if(counter_1 == 127 && counter_2 == 127) next_state = IN_IMG_1;
        else next_state = current_state;
    end
    else if(current_state == IN_IMG_1) begin
        if(counter_1 == 127 && counter_2 == 127) next_state = IDLE;
        else next_state = current_state;
    end
    else if(current_state == IN_MV) begin
        if(counter_1 == 7) next_state = BI_LOAD_FIRST_0;
        else next_state = current_state;
    end
    else if(current_state == BI_LOAD_FIRST_0) begin
        if(counter_3 == 13) next_state = BI_COMPUTE_0;
        else next_state = current_state;
    end
    else if(current_state == BI_COMPUTE_0) begin
        if(counter_4 == 9 && counter_3 == 10) next_state = BI_LOAD_FIRST_1;
        else next_state = current_state;
    end
    else if(current_state == BI_LOAD_FIRST_1) begin
        if(counter_3 == 13) next_state = BI_COMPUTE_1;
        else next_state = current_state;
    end
    else if(current_state == BI_COMPUTE_1) begin
        if(counter_4 == 9 && counter_3 == 10) next_state = SAD;
        else next_state = current_state;
    end
    else if(current_state == SAD) begin
        if(counter_4 == 65 && counter_3 == 8) next_state = OUT;
        else next_state = current_state;
    end
    else if(current_state == OUT) begin
        if(counter_1 == 27 && counter_2 == 1) next_state = IDLE;
        else next_state = current_state;
    end
    else next_state = current_state;
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= next_state;
    else current_state <= next_state;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter_1 <= 0;
    else if(current_state == IN_IMG_0 && counter_1 == 127 && counter_2 == 127) counter_1 <= 0;
    else if(current_state == IN_IMG_0 && counter_2 == 127) counter_1 <= counter_1 + 1;
    else if(current_state == IN_IMG_1 && counter_1 == 127 && counter_2 == 127) counter_1 <= 0;
    else if(current_state == IN_IMG_1 && counter_2 == 127) counter_1 <= counter_1 + 1;
    else if(current_state == IN_MV && counter_1 == 7) counter_1 <= 0;
    else if(current_state == IN_MV || (in_valid2 && current_state == IDLE)) counter_1 <= counter_1 + 1;

    else if(current_state == BI_LOAD_FIRST_0 && counter_3 == 10) counter_1 <= 1;
    else if(current_state == BI_COMPUTE_0 && counter_4 == 9 && counter_3 == 10) counter_1 <= 0;
    else if(current_state == BI_COMPUTE_0 && counter_2 == 10) counter_1 <= counter_1 + 1;

    else if(current_state == BI_LOAD_FIRST_1 && counter_3 == 10) counter_1 <= 0 + 1;
    else if(current_state == BI_COMPUTE_1 && counter_4 == 9 && counter_3 == 10) counter_1 <= 0;
    else if(current_state == BI_COMPUTE_1 && counter_2 == 10) counter_1 <= counter_1 + 1;

    else if(current_state == SAD && counter_4 >= 0 && counter_4 <= 63 && counter_1 == 7 && counter_2 == 7) counter_1 <= 0;
    else if(current_state == SAD && counter_4 >= 0 && counter_4 <= 63 && counter_1 != 7 && counter_2 == 7) counter_1 <= counter_1 + 1;

    else if(current_state == OUT && counter_1 == 27) counter_1 <= 0;
    else if(current_state == OUT) counter_1 <= counter_1 + 1;
    else counter_1 <= counter_1;
end

wire [6:0] counter_1_L0;
wire [6:0] counter_1_L1;
assign counter_1_L0 = (current_state == BI_LOAD_FIRST_0 || current_state == BI_COMPUTE_0) ? (Mv_0[0][1][10:4] + counter_1) : (Mv_0[1][1][10:4] + counter_1);
assign counter_1_L1 = (current_state == BI_LOAD_FIRST_0 || current_state == BI_COMPUTE_0) ? (Mv_1[0][1][10:4] + counter_1) : (Mv_1[1][1][10:4] + counter_1);

wire [6:0] counter_1_SAD_L0;
wire [6:0] counter_1_SAD_L1;
assign counter_1_SAD_L0 = counter_1 + index_L0[counter_3][0];
assign counter_1_SAD_L1 = counter_1 + index_L1[counter_3][0];


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter_2 <= 0;
    else if(current_state == IN_IMG_0 && counter_2 == 127) counter_2 <= 0;
    else if(current_state == IN_IMG_0 || (in_valid && current_state == IDLE)) counter_2 <= counter_2 + 1;
    else if(current_state == IN_IMG_1 && counter_2 == 127) counter_2 <= 0; //Optimize : just for debug, can take it off later
    else if(current_state == IN_IMG_1) counter_2 <= counter_2 + 1;
    else if(current_state == IN_MV) counter_2 <= 0;

    else if(current_state == BI_LOAD_FIRST_0 && counter_3 == 10) counter_2 <= 0;
    else if(current_state == BI_LOAD_FIRST_0 && counter_3 != 10) counter_2 <= counter_2 + 1;
    else if(current_state == BI_COMPUTE_0 && counter_4 == 9 && counter_3 == 10) counter_2 <= 0;
    else if(current_state == BI_COMPUTE_0 && counter_2 == 10) counter_2 <= 0;
    else if(current_state == BI_COMPUTE_0 && counter_2 != 10) counter_2 <= counter_2 + 1;

    else if(current_state == BI_LOAD_FIRST_1 && counter_3 == 10) counter_2 <= 0;
    else if(current_state == BI_LOAD_FIRST_1 && counter_3 != 10) counter_2 <= counter_2 + 1;
    else if(current_state == BI_COMPUTE_1 && counter_4 == 9 && counter_3 == 10) counter_2 <= 0;
    else if(current_state == BI_COMPUTE_1 && counter_2 == 10) counter_2 <= 0;
    else if(current_state == BI_COMPUTE_1 && counter_2 != 10) counter_2 <= counter_2 + 1;

    else if(current_state == SAD && counter_4 >= 0 && counter_4 <= 63 && counter_2 == 7) counter_2 <= 0;
    else if(current_state == SAD && counter_4 >= 0 && counter_4 <= 63 && counter_2 != 7) counter_2 <= counter_2 + 1;

    else if(current_state == OUT && counter_1 == 27 && counter_2 == 1) counter_2 <= 0;
    else if(current_state == OUT && counter_1 == 27) counter_2 <= 1;
    else counter_2 <= counter_2;
end

wire [6:0] counter_2_L0;
wire [6:0] counter_2_L1;
assign counter_2_L0 = (current_state == BI_LOAD_FIRST_0 || current_state == BI_COMPUTE_0) ? (Mv_0[0][0][10:4] + counter_2) : (Mv_0[1][0][10:4] + counter_2);
assign counter_2_L1 = (current_state == BI_LOAD_FIRST_0 || current_state == BI_COMPUTE_0) ? (Mv_1[0][0][10:4] + counter_2) : (Mv_1[1][0][10:4] + counter_2);

wire [6:0] counter_2_SAD_L0;
wire [6:0] counter_2_SAD_L1;
assign counter_2_SAD_L0 = counter_2 + index_L0[counter_3][1];
assign counter_2_SAD_L1 = counter_2 + index_L1[counter_3][1];


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter_3 <= 0;
    
    else if(current_state == BI_LOAD_FIRST_0 && counter_3 == 13) counter_3 <= 0;
    else if(current_state == BI_LOAD_FIRST_0) counter_3 <= counter_3 + 1;
    else if(current_state == BI_COMPUTE_0 && counter_3 == 10) counter_3 <= 0;
    else if(current_state == BI_COMPUTE_0) counter_3 <= counter_3 + 1;

    else if(current_state == BI_LOAD_FIRST_1 && counter_3 == 13) counter_3 <= 0;
    else if(current_state == BI_LOAD_FIRST_1) counter_3 <= counter_3 + 1;
    else if(current_state == BI_COMPUTE_1 && counter_3 == 10) counter_3 <= 0;
    else if(current_state == BI_COMPUTE_1) counter_3 <= counter_3 + 1;

    else if(current_state == SAD && counter_4 == 65 && counter_3 == 8) counter_3 <= 0;
    else if(current_state == SAD && counter_4 == 65) counter_3 <= counter_3 + 1;
    else counter_3 <= counter_3;
end
wire [9:0]counter_3_1;
assign counter_3_1 = counter_3 - 2;

wire [9:0]counter_3_2;
assign counter_3_2 = counter_3 - 1;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter_4 <= 0;
    else if(current_state == BI_COMPUTE_0 && counter_3 == 10 && counter_4 == 9) counter_4 <= 0;
    else if(current_state == BI_COMPUTE_0 && counter_3 == 10) counter_4 <= counter_4 + 1;

    else if(current_state == BI_COMPUTE_1 && counter_3 == 10 && counter_4 == 9) counter_4 <= 0;
    else if(current_state == BI_COMPUTE_1 && counter_3 == 10) counter_4 <= counter_4 + 1;

    else if(current_state == SAD && counter_4 == 65) counter_4 <= 0;
    else if(current_state == SAD) counter_4 <= counter_4 + 1;
    else counter_4 <= counter_4;
end
//=======================================================
//                 BI  Memory Control
//=======================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) DI_BI_0 <= 0;
    else if(current_state == BI_COMPUTE_0) DI_BI_0 <= fp0_0*p0_0 + fp1_0* p1_0 + fp2_0*p2_0 +fp3_0*p3_0;
    else DI_BI_0 <= DI_BI_0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) Addr_BI_0 <= 0;
    else if(current_state == BI_COMPUTE_0 && counter_3 >= 1) Addr_BI_0 <= counter_3_2 + 10*counter_4;
    else if(current_state == SAD) Addr_BI_0 <= counter_2_SAD_L0 + 10*counter_1_SAD_L0;
    else Addr_BI_0 <= Addr_BI_0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) WEB_BI_0 <= 1;
    else if(current_state == BI_COMPUTE_0 && counter_3 >= 1 && counter_3 <= 10) WEB_BI_0 <= 0;
    else WEB_BI_0 <= 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) DI_BI_1 <= 0;
    else if(current_state == BI_COMPUTE_0) DI_BI_1 <= fp0_1*p0_1 + fp1_1* p1_1 + fp2_1*p2_1 +fp3_1*p3_1;
    else DI_BI_1 <= DI_BI_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) Addr_BI_1 <= 0;
    else if(current_state == BI_COMPUTE_0 && counter_3 >= 1) Addr_BI_1 <= counter_3_2 + 10*counter_4;
    else if(current_state == SAD) Addr_BI_1 <= counter_2_SAD_L1 + 10*counter_1_SAD_L1;
    else Addr_BI_1 <= Addr_BI_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) WEB_BI_1 <= 1;
    else if(current_state == BI_COMPUTE_0 && counter_3 >= 1 && counter_3 <= 10) WEB_BI_1 <= 0;
    else WEB_BI_1 <= 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) DI_BI_2 <= 0;
    else if(current_state == BI_COMPUTE_1) DI_BI_2 <= fp0_0*p0_0 + fp1_0* p1_0 + fp2_0*p2_0 +fp3_0*p3_0;
    else DI_BI_2 <= DI_BI_2;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) Addr_BI_2 <= 0;
    else if(current_state == BI_COMPUTE_1 && counter_3 >= 1) Addr_BI_2 <= counter_3_2 + 10*counter_4;
    else if(current_state == SAD) Addr_BI_2 <= counter_2_SAD_L0 + 10*counter_1_SAD_L0;
    else Addr_BI_2 <= Addr_BI_2;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) WEB_BI_2 <= 1;
    else if(current_state == BI_COMPUTE_1 && counter_3 >= 1 && counter_3 <= 10) WEB_BI_2 <= 0;
    else WEB_BI_2 <= 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) DI_BI_3 <= 0;
    else if(current_state == BI_COMPUTE_1) DI_BI_3 <= fp0_1*p0_1 + fp1_1* p1_1 + fp2_1*p2_1 +fp3_1*p3_1;
    else DI_BI_3 <= DI_BI_3;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) Addr_BI_3 <= 0;
    else if(current_state == BI_COMPUTE_1 && counter_3 >= 1) Addr_BI_3 <= counter_3_2 + 10*counter_4;
    else if(current_state == SAD) Addr_BI_3 <= counter_2_SAD_L1 + 10*counter_1_SAD_L1;
    else Addr_BI_3 <= Addr_BI_3;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) WEB_BI_3 <= 1;
    else if(current_state == BI_COMPUTE_1 && counter_3 >= 1 && counter_3 <= 10) WEB_BI_3 <= 0;
    else WEB_BI_3 <= 1;
end
//=======================================================
//                Img  Memory Control
//=======================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) Addr_first_Img <= 0;
    else if(current_state == IN_IMG_0 || (in_valid && current_state == IDLE)) Addr_first_Img <= {counter_1,counter_2};

    else if(current_state == IN_MV && counter_1 == 7) Addr_first_Img <= {counter_1_L0,counter_2_L0}; //Optimize : counter_1 == 7 do not need, just for debug ; or maybe this one isn't necessary at all.
    // else if(current_state == BI_COMPUTE_0 && counter_4 == 9 && counter_3 == 10) Addr_first_Img <= {counter_1_L0,counter_2_L0}; //Optimize :counter_4 == 9 && counter_3 == 10 do not need, just for debug
    
    else if(current_state == BI_LOAD_FIRST_0 || current_state == BI_COMPUTE_0) Addr_first_Img <= {counter_1_L0,counter_2_L0};

    else if(current_state == BI_LOAD_FIRST_1 || current_state == BI_COMPUTE_1) Addr_first_Img <= {counter_1_L0,counter_2_L0};
    
    else Addr_first_Img <= Addr_first_Img;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) DI_first_Img <= 0;
    else if(current_state == IN_IMG_0 || in_valid) DI_first_Img <= in_data[11:4]; 
    else DI_first_Img <= DI_first_Img;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) WEB_first <= 1;
    else if(current_state == IN_IMG_0 || (in_valid && current_state == IDLE)) WEB_first <= 0; 
    else WEB_first <= 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) Addr_second_Img <= 0;
    else if(current_state == IN_IMG_1) Addr_second_Img <= {counter_1,counter_2};

    else if(current_state == IN_MV && counter_1 == 7) Addr_second_Img <= {counter_1_L1,counter_2_L1}; //Optimize : counter_1 == 7 do not need, just for debug ; or maybe this one isn't necessary at all
    // else if(current_state == BI_COMPUTE_0 && counter_4 == 9 && counter_3 == 10) Addr_second_Img <= {counter_1_L1,counter_2_L1}; //Optimize : counter_4 == 9 && counter_3 == 10 do not need, just for debug
    
    else if(current_state == BI_LOAD_FIRST_0 || current_state == BI_COMPUTE_0) Addr_second_Img <= {counter_1_L1,counter_2_L1};

    else if(current_state == BI_LOAD_FIRST_1 || current_state == BI_COMPUTE_1) Addr_second_Img <= {counter_1_L1,counter_2_L1};

    else Addr_second_Img <= Addr_second_Img;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) DI_second_Img <= 0;
    else if(current_state == IN_IMG_1 || (current_state == IN_IMG_0 && counter_1 == 127 && counter_2 == 127)) DI_second_Img <= in_data[11:4]; 
    else DI_second_Img <= DI_second_Img;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) WEB_second <= 1;
    else if(current_state == IN_IMG_1) WEB_second <= 0; 
    else WEB_second <= 1;
end

//=======================================================
//              Bilinear Interpolation L0
//=======================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) p0_0 <= 0;

    else if(current_state == BI_COMPUTE_0 && counter_3 == 10) p0_0 <= p0_0;
    else if(current_state == BI_COMPUTE_0 && counter_3 != 10) p0_0 <= previous_node_0[counter_3];

    else if(current_state == BI_COMPUTE_1 && counter_3 == 10) p0_0 <= p0_0;
    else if(current_state == BI_COMPUTE_1 && counter_3 != 10) p0_0 <= previous_node_0[counter_3];

    else p0_0 <= p0_0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) p1_0 <= 0;

    else if(current_state == BI_COMPUTE_0 && counter_3 == 10) p1_0 <= p1_0;
    else if(current_state == BI_COMPUTE_0) p1_0 <= previous_node_0[counter_3 + 1];

    else if(current_state == BI_COMPUTE_1 && counter_3 == 10) p1_0 <= p1_0;
    else if(current_state == BI_COMPUTE_1) p1_0 <= previous_node_0[counter_3 + 1];

    else p1_0 <= p1_0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) p2_0 <= 0;

    else if(current_state == BI_LOAD_FIRST_0 && counter_3 == 13) p2_0 <= DO_first_Img;
    else if(current_state == BI_COMPUTE_0 && counter_3 == 10) p2_0 <= DO_first_Img;
    else if(current_state == BI_COMPUTE_0 && counter_3 > 0 && counter_3 != 10) p2_0 <= p3_0;

    else if(current_state == BI_LOAD_FIRST_1 && counter_3 == 13) p2_0 <= DO_first_Img;
    else if(current_state == BI_COMPUTE_1 && counter_3 == 10) p2_0 <= DO_first_Img;
    else if(current_state == BI_COMPUTE_1 && counter_3 > 0 && counter_3 != 10) p2_0 <= p3_0;

    else p2_0 <= p2_0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) p3_0 <= 0;
    else if(current_state == BI_COMPUTE_0) p3_0 <= DO_first_Img;
    else if(current_state == BI_COMPUTE_1) p3_0 <= DO_first_Img;
    else p3_0 <= p3_0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) f0_0 <= 0;
    else if(current_state == BI_LOAD_FIRST_0) f0_0 <= Mv_0[0][0][3:0];
    else if(current_state == BI_LOAD_FIRST_1) f0_0 <= Mv_0[1][0][3:0];
    else f0_0 <= f0_0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) f1_0 <= 0;
    else if(current_state == BI_LOAD_FIRST_0) f1_0 <= Mv_0[0][1][3:0];
    else if(current_state == BI_LOAD_FIRST_1) f1_0 <= Mv_0[1][1][3:0];
    else f1_0 <= f1_0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) fp0_0 <= 0;
    else if(current_state == BI_LOAD_FIRST_0) fp0_0 <= 256 - f0_0_span - f1_0_span + f0x1_0;
    else if(current_state == BI_LOAD_FIRST_1) fp0_0 <= 256 - f0_0_span - f1_0_span + f0x1_0;
    else fp0_0 <= fp0_0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) fp1_0 <= 0;
    else if(current_state == BI_LOAD_FIRST_0) fp1_0 <= f0_0_span - f0x1_0;
    else if(current_state == BI_LOAD_FIRST_1) fp1_0 <= f0_0_span - f0x1_0;
    else fp1_0 <= fp1_0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) fp2_0 <= 0;
    else if(current_state == BI_LOAD_FIRST_0) fp2_0 <= f1_0_span - f0x1_0;
    else if(current_state == BI_LOAD_FIRST_1) fp2_0 <= f1_0_span - f0x1_0;
    else fp2_0 <= fp2_0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) fp3_0 <= 0;
    else if(current_state == BI_LOAD_FIRST_0) fp3_0 <= f0x1_0;
    else if(current_state == BI_LOAD_FIRST_1) fp3_0 <= f0x1_0;
    else fp3_0 <= fp3_0;
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 11 ; i ++) previous_node_0[i] <= 0;

    else if(current_state == BI_LOAD_FIRST_0) previous_node_0[counter_3_1] <= DO_first_Img;
    else if(current_state == BI_COMPUTE_0 && counter_3 == 10) begin
        previous_node_0[9] <= p2_0;
        previous_node_0[10] <= p3_0;
    end
    else if(current_state == BI_COMPUTE_0 && counter_3 > 0 && counter_3 < 10) previous_node_0[counter_3 - 1] <= p2_0;

    else if(current_state == BI_LOAD_FIRST_1) previous_node_0[counter_3_1] <= DO_first_Img;
    else if(current_state == BI_COMPUTE_1 && counter_3 == 10) begin
        previous_node_0[9] <= p2_0;
        previous_node_0[10] <= p3_0;
    end
    else if(current_state == BI_COMPUTE_1 && counter_3 > 0 && counter_3 < 10) previous_node_0[counter_3 - 1] <= p2_0;

    else for(i = 0 ; i < 11 ; i ++) previous_node_0[i] <= previous_node_0[i];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 2 ; i ++) for(j = 0 ; j < 2 ; j ++) Mv_0[i][j] <= 0;
    else if(current_state == IN_MV || (in_valid2 && current_state == IDLE)) begin
        if(counter_1 == 0) Mv_0[0][0] <= in_data;
        else if(counter_1 == 1) Mv_0[0][1] <= in_data;
        else if(counter_1 == 4) Mv_0[1][0] <= in_data;
        else if(counter_1 == 5) Mv_0[1][1] <= in_data;
    end
    else for(i = 0 ; i < 2 ; i ++) for(j = 0 ; j < 2 ; j ++) Mv_0[i][j] <= Mv_0[i][j];
end
//=======================================================
//              Bilinear Interpolation L1
//=======================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) p0_1 <= 0;
    else if(current_state == BI_COMPUTE_0 && counter_3 == 10) p0_1 <= p0_1;
    else if(current_state == BI_COMPUTE_0 && counter_3 != 10) p0_1 <= previous_node_1[counter_3];
    else if(current_state == BI_COMPUTE_1 && counter_3 == 10) p0_1 <= p0_1;
    else if(current_state == BI_COMPUTE_1 && counter_3 != 10) p0_1 <= previous_node_1[counter_3];
    else p0_1 <= p0_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) p1_1 <= 1;
    else if(current_state == BI_COMPUTE_0 && counter_3 == 10) p1_1 <= p1_1;
    else if(current_state == BI_COMPUTE_0) p1_1 <= previous_node_1[counter_3 + 1];
    else if(current_state == BI_COMPUTE_1 && counter_3 == 10) p1_1 <= p1_1;
    else if(current_state == BI_COMPUTE_1) p1_1 <= previous_node_1[counter_3 + 1];
    else p1_1 <= p1_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) p2_1 <= 0;
    else if(current_state == BI_LOAD_FIRST_0 && counter_3 == 13) p2_1 <= DO_second_Img;
    else if(current_state == BI_COMPUTE_0 && counter_3 == 10) p2_1 <= DO_second_Img;
    else if(current_state == BI_COMPUTE_0 && counter_3 > 0 && counter_3 != 10) p2_1 <= p3_1;
    else if(current_state == BI_LOAD_FIRST_1 && counter_3 == 13) p2_1 <= DO_second_Img;
    else if(current_state == BI_COMPUTE_1 && counter_3 == 10) p2_1 <= DO_second_Img;
    else if(current_state == BI_COMPUTE_1 && counter_3 > 0 && counter_3 != 10) p2_1 <= p3_1;
    else p2_1 <= p2_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) p3_1 <= 0;
    else if(current_state == BI_COMPUTE_0) p3_1 <= DO_second_Img;
    else if(current_state == BI_COMPUTE_1) p3_1 <= DO_second_Img;
    else p3_1 <= p3_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) f0_1 <= 0;
    else if(current_state == BI_LOAD_FIRST_0) f0_1 <= Mv_1[0][0][3:0];
    else if(current_state == BI_LOAD_FIRST_1) f0_1 <= Mv_1[1][0][3:0];
    else f0_1 <= f0_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) f1_1 <= 0;
    else if(current_state == BI_LOAD_FIRST_0) f1_1 <= Mv_1[0][1][3:0];
    else if(current_state == BI_LOAD_FIRST_1) f1_1 <= Mv_1[1][1][3:0];
    else f1_1 <= f1_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) fp0_1 <= 0;
    else if(current_state == BI_LOAD_FIRST_0) fp0_1 <= 256 - f0_1_span - f1_1_span + f0x1_1;
    else if(current_state == BI_LOAD_FIRST_1) fp0_1 <= 256 - f0_1_span - f1_1_span + f0x1_1;
    else fp0_1 <= fp0_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) fp1_1 <= 0;
    else if(current_state == BI_LOAD_FIRST_0) fp1_1 <= f0_1_span - f0x1_1;
    else if(current_state == BI_LOAD_FIRST_1) fp1_1 <= f0_1_span - f0x1_1;
    else fp1_1 <= fp1_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) fp2_1 <= 0;
    else if(current_state == BI_LOAD_FIRST_0) fp2_1 <= f1_1_span - f0x1_1;
    else if(current_state == BI_LOAD_FIRST_1) fp2_1 <= f1_1_span - f0x1_1;
    else fp2_1 <= fp2_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) fp3_1 <= 0;
    else if(current_state == BI_LOAD_FIRST_0) fp3_1 <= f0x1_1;
    else if(current_state == BI_LOAD_FIRST_1) fp3_1 <= f0x1_1;
    else fp3_1 <= fp3_1;
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 11 ; i ++) previous_node_1[i] <= 0;
    else if(current_state == BI_LOAD_FIRST_0) previous_node_1[counter_3_1] <= DO_second_Img;
    else if(current_state == BI_COMPUTE_0 && counter_3 == 10) begin
        previous_node_1[9] <= p2_1;
        previous_node_1[10] <= p3_1;
    end
    else if(current_state == BI_COMPUTE_0 && counter_3 > 0 && counter_3 < 10) previous_node_1[counter_3 - 1] <= p2_1;

    else if(current_state == BI_LOAD_FIRST_1) previous_node_1[counter_3_1] <= DO_second_Img;
    else if(current_state == BI_COMPUTE_1 && counter_3 == 10) begin
        previous_node_1[9] <= p2_1;
        previous_node_1[10] <= p3_1;
    end
    else if(current_state == BI_COMPUTE_1 && counter_3 > 0 && counter_3 < 10) previous_node_1[counter_3 - 1] <= p2_1;

    else for(i = 0 ; i < 11 ; i ++) previous_node_1[i] <= previous_node_1[i];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 2 ; i ++) for(j = 0 ; j < 2 ; j ++) Mv_1[i][j] <= 0;
    else if(current_state == IN_MV || (in_valid2 && current_state == IDLE)) begin
        if(counter_1 == 2) Mv_1[0][0] <= in_data;
        else if(counter_1 == 3) Mv_1[0][1] <= in_data;
        else if(counter_1 == 6) Mv_1[1][0] <= in_data;
        else if(counter_1 == 7) Mv_1[1][1] <= in_data;
    end
    else for(i = 0 ; i < 2 ; i ++) for(j = 0 ; j < 2 ; j ++) Mv_1[i][j] <= Mv_1[i][j];
end

//=======================================================
//                      SAD
//=======================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) accumulation_0 <= 0;
    else if(current_state == SAD && counter_4 == 65) accumulation_0 <= 0;
    else if(current_state == SAD && counter_4 >= 2 && counter_4 < 65) begin
        if(DO_BI_0 > DO_BI_1) accumulation_0 <= accumulation_0 + (DO_BI_0 - DO_BI_1);
        else accumulation_0 <= accumulation_0 + (DO_BI_1 - DO_BI_0);
    end
    else accumulation_0 <= accumulation_0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) accumulation_1 <= 0;
    else if(current_state == SAD && counter_4 == 65) accumulation_1 <= 0;
    else if(current_state == SAD && counter_4 >= 2 && counter_4 < 65) begin
        if(DO_BI_2 > DO_BI_3) accumulation_1 <= accumulation_1 + (DO_BI_2 - DO_BI_3);
        else accumulation_1 <= accumulation_1 + (DO_BI_3 - DO_BI_2);
    end
    else accumulation_1 <= accumulation_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) SAD_0 <= 28'b1111111111111111111111111111;
    else if(current_state == IDLE) SAD_0 <= 28'b1111111111111111111111111111;
    else if(current_state == SAD && counter_4 == 65) begin
        if(DO_BI_0 > DO_BI_1) begin
            if((accumulation_0 + (DO_BI_0 - DO_BI_1)) < SAD_0[23:0]) begin
                SAD_0[23:0] <= accumulation_0 + (DO_BI_0 - DO_BI_1);
                SAD_0[27:24] <= counter_3[3:0];
            end
        end
        else begin
            if((accumulation_0 + (DO_BI_1 - DO_BI_0)) < SAD_0[23:0]) begin
                SAD_0[23:0] <= accumulation_0 + (DO_BI_1 - DO_BI_0);
                SAD_0[27:24] <= counter_3[3:0];
            end
        end
    end
    else SAD_0 <= SAD_0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) SAD_1 <=28'b1111111111111111111111111111;
    else if(current_state == IDLE) SAD_1 <= 28'b1111111111111111111111111111;
    else if(current_state == SAD && counter_4 == 65) begin
        if(DO_BI_2 > DO_BI_3) begin
            if((accumulation_1 + (DO_BI_2 - DO_BI_3)) < SAD_1[23:0]) begin
                SAD_1[23:0] <= accumulation_1 + (DO_BI_2 - DO_BI_3);
                SAD_1[27:24] <= counter_3[3:0];
            end
        end
        else begin
            if((accumulation_1 + (DO_BI_3 - DO_BI_2)) < SAD_1[23:0]) begin
                SAD_1[23:0] <= accumulation_1 + (DO_BI_3 - DO_BI_2);
                SAD_1[27:24] <= counter_3[3:0];
            end
        end
    end
    else SAD_1 <= SAD_1;
end

//=======================================================
//                      Output
//=======================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid <= 0;
    else if(current_state == OUT) out_valid <= 1;
    else out_valid <= 0;
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) out_sad <= 0;
    else if(current_state == OUT) begin
        if(counter_2 == 0) out_sad <= SAD_0[counter_1];
        if(counter_2 == 1) out_sad <= SAD_1[counter_1];
    end
    else out_sad <= 0;
end

//=======================================================
//                   Memory
//=======================================================
BI BI_0( 
    .A0(Addr_BI_0[0]),
    .A1(Addr_BI_0[1]),
    .A2(Addr_BI_0[2]),
    .A3(Addr_BI_0[3]),
    .A4(Addr_BI_0[4]),
    .A5(Addr_BI_0[5]),
    .A6(Addr_BI_0[6]),
    .CK(clk),
    .CS(1'b1),
    .OE(1'b1),
    .DI0(DI_BI_0[0]),
    .DI1(DI_BI_0[1]),
    .DI2(DI_BI_0[2]),
    .DI3(DI_BI_0[3]),
    .DI4(DI_BI_0[4]),
    .DI5(DI_BI_0[5]),
    .DI6(DI_BI_0[6]),
    .DI7(DI_BI_0[7]),
    .DI8(DI_BI_0[8]),
    .DI9(DI_BI_0[9]),
    .DI10(DI_BI_0[10]),
    .DI11(DI_BI_0[11]),
    .DI12(DI_BI_0[12]),
    .DI13(DI_BI_0[13]),
    .DI14(DI_BI_0[14]),
    .DI15(DI_BI_0[15]),
    .DO0(DO_BI_0[0]),
    .DO1(DO_BI_0[1]),
    .DO2(DO_BI_0[2]),
    .DO3(DO_BI_0[3]),
    .DO4(DO_BI_0[4]),
    .DO5(DO_BI_0[5]),
    .DO6(DO_BI_0[6]),
    .DO7(DO_BI_0[7]),
    .DO8(DO_BI_0[8]),
    .DO9(DO_BI_0[9]),
    .DO10(DO_BI_0[10]),
    .DO11(DO_BI_0[11]),
    .DO12(DO_BI_0[12]),
    .DO13(DO_BI_0[13]),
    .DO14(DO_BI_0[14]),
    .DO15(DO_BI_0[15]),
    .WEB(WEB_BI_0)
 );

BI BI_1( 
    .A0(Addr_BI_1[0]),
    .A1(Addr_BI_1[1]),
    .A2(Addr_BI_1[2]),
    .A3(Addr_BI_1[3]),
    .A4(Addr_BI_1[4]),
    .A5(Addr_BI_1[5]),
    .A6(Addr_BI_1[6]),
    .CK(clk),
    .CS(1'b1),
    .OE(1'b1),
    .DI0(DI_BI_1[0]),
    .DI1(DI_BI_1[1]),
    .DI2(DI_BI_1[2]),
    .DI3(DI_BI_1[3]),
    .DI4(DI_BI_1[4]),
    .DI5(DI_BI_1[5]),
    .DI6(DI_BI_1[6]),
    .DI7(DI_BI_1[7]),
    .DI8(DI_BI_1[8]),
    .DI9(DI_BI_1[9]),
    .DI10(DI_BI_1[10]),
    .DI11(DI_BI_1[11]),
    .DI12(DI_BI_1[12]),
    .DI13(DI_BI_1[13]),
    .DI14(DI_BI_1[14]),
    .DI15(DI_BI_1[15]),
    .DO0(DO_BI_1[0]),
    .DO1(DO_BI_1[1]),
    .DO2(DO_BI_1[2]),
    .DO3(DO_BI_1[3]),
    .DO4(DO_BI_1[4]),
    .DO5(DO_BI_1[5]),
    .DO6(DO_BI_1[6]),
    .DO7(DO_BI_1[7]),
    .DO8(DO_BI_1[8]),
    .DO9(DO_BI_1[9]),
    .DO10(DO_BI_1[10]),
    .DO11(DO_BI_1[11]),
    .DO12(DO_BI_1[12]),
    .DO13(DO_BI_1[13]),
    .DO14(DO_BI_1[14]),
    .DO15(DO_BI_1[15]),
    .WEB(WEB_BI_1)
 );

 BI BI_2( 
    .A0(Addr_BI_2[0]),
    .A1(Addr_BI_2[1]),
    .A2(Addr_BI_2[2]),
    .A3(Addr_BI_2[3]),
    .A4(Addr_BI_2[4]),
    .A5(Addr_BI_2[5]),
    .A6(Addr_BI_2[6]),
    .CK(clk),
    .CS(1'b1),
    .OE(1'b1),
    .DI0(DI_BI_2[0]),
    .DI1(DI_BI_2[1]),
    .DI2(DI_BI_2[2]),
    .DI3(DI_BI_2[3]),
    .DI4(DI_BI_2[4]),
    .DI5(DI_BI_2[5]),
    .DI6(DI_BI_2[6]),
    .DI7(DI_BI_2[7]),
    .DI8(DI_BI_2[8]),
    .DI9(DI_BI_2[9]),
    .DI10(DI_BI_2[10]),
    .DI11(DI_BI_2[11]),
    .DI12(DI_BI_2[12]),
    .DI13(DI_BI_2[13]),
    .DI14(DI_BI_2[14]),
    .DI15(DI_BI_2[15]),
    .DO0(DO_BI_2[0]),
    .DO1(DO_BI_2[1]),
    .DO2(DO_BI_2[2]),
    .DO3(DO_BI_2[3]),
    .DO4(DO_BI_2[4]),
    .DO5(DO_BI_2[5]),
    .DO6(DO_BI_2[6]),
    .DO7(DO_BI_2[7]),
    .DO8(DO_BI_2[8]),
    .DO9(DO_BI_2[9]),
    .DO10(DO_BI_2[10]),
    .DO11(DO_BI_2[11]),
    .DO12(DO_BI_2[12]),
    .DO13(DO_BI_2[13]),
    .DO14(DO_BI_2[14]),
    .DO15(DO_BI_2[15]),
    .WEB(WEB_BI_2)
 );

 BI BI_3( 
    .A0(Addr_BI_3[0]),
    .A1(Addr_BI_3[1]),
    .A2(Addr_BI_3[2]),
    .A3(Addr_BI_3[3]),
    .A4(Addr_BI_3[4]),
    .A5(Addr_BI_3[5]),
    .A6(Addr_BI_3[6]),
    .CK(clk),
    .CS(1'b1),
    .OE(1'b1),
    .DI0(DI_BI_3[0]),
    .DI1(DI_BI_3[1]),
    .DI2(DI_BI_3[2]),
    .DI3(DI_BI_3[3]),
    .DI4(DI_BI_3[4]),
    .DI5(DI_BI_3[5]),
    .DI6(DI_BI_3[6]),
    .DI7(DI_BI_3[7]),
    .DI8(DI_BI_3[8]),
    .DI9(DI_BI_3[9]),
    .DI10(DI_BI_3[10]),
    .DI11(DI_BI_3[11]),
    .DI12(DI_BI_3[12]),
    .DI13(DI_BI_3[13]),
    .DI14(DI_BI_3[14]),
    .DI15(DI_BI_3[15]),
    .DO0(DO_BI_3[0]),
    .DO1(DO_BI_3[1]),
    .DO2(DO_BI_3[2]),
    .DO3(DO_BI_3[3]),
    .DO4(DO_BI_3[4]),
    .DO5(DO_BI_3[5]),
    .DO6(DO_BI_3[6]),
    .DO7(DO_BI_3[7]),
    .DO8(DO_BI_3[8]),
    .DO9(DO_BI_3[9]),
    .DO10(DO_BI_3[10]),
    .DO11(DO_BI_3[11]),
    .DO12(DO_BI_3[12]),
    .DO13(DO_BI_3[13]),
    .DO14(DO_BI_3[14]),
    .DO15(DO_BI_3[15]),
    .WEB(WEB_BI_3)
 );

Img img_first( 
    .A0(Addr_first_Img[0]),
    .A1(Addr_first_Img[1]),
    .A2(Addr_first_Img[2]),
    .A3(Addr_first_Img[3]),
    .A4(Addr_first_Img[4]),
    .A5(Addr_first_Img[5]),
    .A6(Addr_first_Img[6]),
    .A7(Addr_first_Img[7]),
    .A8(Addr_first_Img[8]),
    .A9(Addr_first_Img[9]),
    .A10(Addr_first_Img[10]),
    .A11(Addr_first_Img[11]),
    .A12(Addr_first_Img[12]),
    .A13(Addr_first_Img[13]),
    .CK(clk),
    .CS(1'b1),
    .OE(1'b1),
    .DI0(DI_first_Img[0]),
    .DI1(DI_first_Img[1]),
    .DI2(DI_first_Img[2]),
    .DI3(DI_first_Img[3]),
    .DI4(DI_first_Img[4]),
    .DI5(DI_first_Img[5]),
    .DI6(DI_first_Img[6]),
    .DI7(DI_first_Img[7]),
    .DO0(DO_first_Img[0]),
    .DO1(DO_first_Img[1]),
    .DO2(DO_first_Img[2]),
    .DO3(DO_first_Img[3]),
    .DO4(DO_first_Img[4]),
    .DO5(DO_first_Img[5]),
    .DO6(DO_first_Img[6]),
    .DO7(DO_first_Img[7]),
    .WEB(WEB_first)
 );

Img img_second( 
    .A0(Addr_second_Img[0]),
    .A1(Addr_second_Img[1]),
    .A2(Addr_second_Img[2]),
    .A3(Addr_second_Img[3]),
    .A4(Addr_second_Img[4]),
    .A5(Addr_second_Img[5]),
    .A6(Addr_second_Img[6]),
    .A7(Addr_second_Img[7]),
    .A8(Addr_second_Img[8]),
    .A9(Addr_second_Img[9]),
    .A10(Addr_second_Img[10]),
    .A11(Addr_second_Img[11]),
    .A12(Addr_second_Img[12]),
    .A13(Addr_second_Img[13]),
    .CK(clk),
    .CS(1'b1),
    .OE(1'b1),
    .DI0(DI_second_Img[0]),
    .DI1(DI_second_Img[1]),
    .DI2(DI_second_Img[2]),
    .DI3(DI_second_Img[3]),
    .DI4(DI_second_Img[4]),
    .DI5(DI_second_Img[5]),
    .DI6(DI_second_Img[6]),
    .DI7(DI_second_Img[7]),
    .DO0(DO_second_Img[0]),
    .DO1(DO_second_Img[1]),
    .DO2(DO_second_Img[2]),
    .DO3(DO_second_Img[3]),
    .DO4(DO_second_Img[4]),
    .DO5(DO_second_Img[5]),
    .DO6(DO_second_Img[6]),
    .DO7(DO_second_Img[7]),
    .WEB(WEB_second)
 );
endmodule