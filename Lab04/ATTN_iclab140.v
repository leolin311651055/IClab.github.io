//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Two Head Attention
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : ATTN.v
//   Module Name : ATTN
//   Release version : V1.0 (Release Date: 2025-3)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


module ATTN(
    //Input Port
    clk,
    rst_n,

    in_valid,
    in_str,
    q_weight,
    k_weight,
    v_weight,
    out_weight,

    //Output Port
    out_valid,
    out
    );

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;
parameter sqare_root_2 = 32'b00111111101101010000010011110011;

parameter IDLE = 6'd0;
parameter IN = 6'd1;
parameter CAL_1 = 6'd2;
parameter OUT = 6'd7;


parameter CAL_2 = 6'd3;
parameter CAL_3 = 6'd4;
parameter CAL_4 = 6'd5;
parameter CAL_5 = 6'd6;



input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] in_str, q_weight, k_weight, v_weight, out_weight;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;


//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
reg[31:0] indata[0:4][0:3]; 
// reg[31:0] final_answer[0:4][0:3]; 
reg[31:0] weight_k[0:3][0:3];
reg[31:0] weight_q[0:3][0:3];
reg[31:0] weight_v[0:3][0:3];
reg[31:0] outweight[0:3][0:3];
reg[5:0]  current_state;
reg[5:0]  next_state;
reg[8:0]  counter_1;
reg[8:0]  counter_2;
reg[8:0]  counter_3;
reg [31:0] mult_a[0:7];
reg [31:0] mult_b[0:7];
reg [31:0] mult_z[0:7];
reg [31:0] add_a [0:1];
reg [31:0] add_b [0:1];
reg [31:0] add_z [0:5];
reg [31:0] div_a [0:1];
reg [31:0] div_b [0:1];
reg [31:0] div_z [0:1];
// reg [31:0] head_k_0  [0:4][0:1]; //can combine
// reg [31:0] head_k_1  [0:4][0:1]; //can combine
reg [31:0] head_q_0  [0:4][0:1]; //can combine
reg [31:0] head_q_1  [0:4][0:1]; //can combine
reg [31:0] head_v_0  [0:4][0:1]; //can combine
reg [31:0] head_v_1  [0:4][0:1]; //can combine
reg [31:0] head_k_0[0:4][0:1];//can be replaced by head_k_0
reg [31:0] head_k_1[0:4][0:1];//can be replaced by head_k_1
// reg [31:0] softmax_0   [0:4]; //You can replace it with other add or mult in or out reg
// reg [31:0] softmax_1   [0:4]; //You can replace it with other add or mult in or out reg
reg [31:0] exp_i     [0:1];
reg [31:0] exp_o     [0:1];
reg [31:0] score_0   [0:4][0:4];
reg [31:0] score_1   [0:4][0:4];
wire[31:0] Root_num_2;
reg [31:0] add_z_4_span;

integer i, j;

assign Root_num_2 = 32'b00111111101101010000010011110011;

//---------------------------------------------------------------------
// IPs
//---------------------------------------------------------------------
/////////Mult/////////
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
MUL0 ( .a(mult_a[0]), .b(mult_b[0]), .rnd(3'b000), .z(mult_z[0]), .status());

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
MUL1 ( .a(mult_a[1]), .b(mult_b[1]), .rnd(3'b000), .z(mult_z[1]), .status());

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
MUL2 ( .a(mult_a[2]), .b(mult_b[2]), .rnd(3'b000), .z(mult_z[2]), .status());

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
MUL3 ( .a(mult_a[3]), .b(mult_b[3]), .rnd(3'b000), .z(mult_z[3]), .status());

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
MUL4 ( .a(mult_a[4]), .b(mult_b[4]), .rnd(3'b000), .z(mult_z[4]), .status());

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
MUL5 ( .a(mult_a[5]), .b(mult_b[5]), .rnd(3'b000), .z(mult_z[5]), .status());

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
MUL6 ( .a(mult_a[6]), .b(mult_b[6]), .rnd(3'b000), .z(mult_z[6]), .status());

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
MUL7 ( .a(mult_a[7]), .b(mult_b[7]), .rnd(3'b000), .z(mult_z[7]), .status());

/////////Add/////////
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
ADD0 ( .a(mult_z[0]), .b(mult_z[1]), .rnd(3'b000), .z(add_z[2]), .status());

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
ADD1 ( .a(mult_z[2]), .b(mult_z[3]), .rnd(3'b000), .z(add_z[3]), .status());

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
ADD2 ( .a(mult_z[4]), .b(mult_z[5]), .rnd(3'b000), .z(add_z[4]), .status());

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
ADD3 ( .a(mult_z[6]), .b(mult_z[7]), .rnd(3'b000), .z(add_z[5]), .status());

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
ADD4 ( .a(add_a[0]), .b(add_b[0]), .rnd(3'b000), .z(add_z[0]), .status());

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
ADD5 ( .a(add_a[1]), .b(add_b[1]), .rnd(3'b000), .z(add_z[1]), .status());

// DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
// ADD6 ( .a(add_z[0]), .b(add_z[1]), .rnd(3'b000), .z(add_z[6]), .status());

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
DIV0 ( .a(div_a[0]), .b(div_b[0]), .rnd(3'b000), .z(div_z[0]), .status());

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
DIV1 ( .a(div_a[1]), .b(div_b[1]), .rnd(3'b000), .z(div_z[1]), .status());

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
EXP0 ( .a(exp_i[0]), .z(exp_o[0]), .status());

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
EXP1 ( .a(exp_i[1]), .z(exp_o[1]), .status());

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) add_z_4_span <= 0;
    else add_z_4_span <= add_z[4];
end
// ex.
// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
// MUL1 ( .a(mul1_a), .b(mul1_b), .rnd(3'b000), .z(mul1_res), .status());
//DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
//mac (.a(), .b(), .c(), rnd(3'b000), .z(), .status(0));
//suggest MAC, (A*B)+C, use SYSTOLIC ARRAY, finish muli in 9 cycle 

//---------------------------------------------------------------------
// FSM
//---------------------------------------------------------------------
always@(*) begin
    if(!rst_n) next_state = IDLE;
    else if(current_state == IDLE) begin
        if(in_valid) next_state = IN;
        else next_state = current_state;
    end
    else if(current_state == IN) begin
        // if(counter_1 == 4 && counter_2 == 3) next_state = SPLIT;
        if(counter_1 == 4 && counter_2 == 3) next_state = CAL_1;
        else next_state = current_state;
    end
    else if(current_state == CAL_1) begin
        if(counter_1 == 21) next_state = CAL_2;
        else next_state = current_state;
    end
    else if(current_state == CAL_2) begin
        if(counter_1 == 26) next_state = CAL_3;
        else next_state = current_state;
    end
    else if(current_state == CAL_3) begin
        if(counter_1 == 13 && counter_2 == 4) next_state = CAL_4;
        else next_state = current_state;
    end
    else if(current_state == CAL_4) begin
        if(counter_1 == 19) next_state = CAL_5;
        else next_state = current_state;
    end
    else if(current_state == CAL_5) begin
        if(counter_1 == 19) next_state = OUT;
        else next_state = current_state;
    end
    else if(current_state == OUT) begin
        if(counter_1 == 21) next_state = IDLE;
        else next_state = current_state;
    end
    // else if(current_state == OUT) begin //can combine with OUT，output when caculate answer
    //     if(counter_1 == 4 && counter_2 == 3) next_state = IDLE;
    //     else next_state = current_state;
    // end
    else next_state = current_state;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

wire [8:0] counter_1_1;
assign counter_1_1 = counter_1 - 3;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter_1 <= 0;
    else if(current_state == IN && counter_2 == 3 && counter_1 == 4) counter_1 <= 0;
    else if(current_state == IN && counter_2 == 3) counter_1 <= counter_1 + 1;
    else if(current_state == CAL_1 && counter_1 == 21)  counter_1 <= 0;
    else if(current_state == CAL_1)  counter_1 <= counter_1 + 1;
    else if(current_state == CAL_2 && counter_1 == 26)  counter_1 <= 0;
    else if(current_state == CAL_2)  counter_1 <= counter_1 + 1;

    else if(current_state == CAL_3 && counter_1 == 13)  counter_1 <= 0;
    else if(current_state == CAL_3 && counter_1 < 13)  counter_1 <= counter_1 + 1;
    else if(current_state == CAL_3)  counter_1 <= counter_1;

    else if(current_state == CAL_4 && counter_1 == 19)  counter_1 <= 0;
    else if(current_state == CAL_4)  counter_1 <= counter_1 + 1;
    else if(current_state == CAL_5 && counter_1 == 19)  counter_1 <= 0;
    else if(current_state == CAL_5)  counter_1 <= counter_1 + 1;
    else if(current_state == OUT && counter_1 == 21)  counter_1 <= 0;
    else if(current_state == OUT)  counter_1 <= counter_1 + 1; 
    // else if(current_state == OUT && counter_2 == 3 && counter_1 == 4) counter_1 <= 0;
    // else if(current_state == OUT && counter_2 == 3) counter_1 <= counter_1 + 1;
    else counter_1 <= counter_1;
end



always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter_2 <= 0;
    else if(current_state == IN || (current_state == IDLE && in_valid)) begin
        if(counter_2 != 3) counter_2 <= counter_2 + 1;
        else counter_2 <= 0;
    end
    else if(current_state == CAL_1 && counter_1 == 21)  counter_2 <= 0;
    else if(current_state == CAL_1 && counter_1 >= 1)   counter_2 <= counter_1 - 1;
    else if(current_state == CAL_2 && counter_1 == 26)  counter_2 <= 0;
    else if(current_state == CAL_2 && counter_1 >= 1)   counter_2 <= counter_1 - 1;
    
    else if(current_state == CAL_3 && counter_1 == 13 && counter_2 == 4)  counter_2 <= 0;
    else if(current_state == CAL_3 && counter_1 == 13)   counter_2 <= counter_2 + 1;

    else if(current_state == CAL_4 && counter_1 == 19)  counter_2 <= 0;
    else if(current_state == CAL_4 && counter_1 >= 1)   counter_2 <= counter_1 - 1;
    else if(current_state == CAL_5 && counter_1 == 19)  counter_2 <= 0;
    else if(current_state == CAL_5 && counter_1 >= 1)   counter_2 <= counter_1 - 1;
    else if(current_state == OUT && counter_1 == 21)  counter_2 <= 0;
    else if(current_state == OUT && counter_1 >= 1)   counter_2 <= counter_1 - 1;
    // else if(current_state == OUT) begin
    //     if(counter_2 != 3) counter_2 <= counter_2 + 1;
    //     else counter_2 <= 0;
    // end
    else counter_2 <= counter_2;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter_3 <= 0;
    else if(current_state == CAL_2 && counter_1 == 19)  counter_3 <= 0;
    else if(current_state == CAL_2 && counter_1 >= 1) counter_3 <= counter_1;
    else if(current_state == CAL_3 && counter_1 == 13 && counter_2 == 4)  counter_3 <= 0;
    else if(current_state == CAL_3 && counter_1 >= 4) counter_3 <= counter_1 - 4;

    else if(current_state == CAL_4 && counter_1 == 19)   counter_3 <= 0;
    else if(current_state == CAL_4) counter_3 <= counter_2;
    else if(current_state == CAL_5 && counter_1 == 19)   counter_3 <= 0;
    else if(current_state == CAL_5 && counter_2 >= 1) counter_3 <= counter_2;
    else counter_3 <= counter_3;
end

wire [8:0] counter_3_1;
assign counter_3_1 = counter_3 - 3;

wire [8:0] counter_4;
assign counter_4 = counter_3 - 1;

wire [8:0] counter_4_1;
assign counter_4_1 = counter_4 - 3;


//---------------------------------------------------------------------
// Design
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        exp_i[0] <= 0; exp_i[1] <= 0;
    end
    else if(current_state == CAL_3) begin
        if(counter_1 == 0) begin
            exp_i[0] <= score_0[counter_2][0];
            exp_i[1] <= score_0[counter_2][1];
        end
        else if(counter_1 == 1) begin
            exp_i[0] <= score_0[counter_2][2];
            exp_i[1] <= score_0[counter_2][3];
        end
        else if(counter_1 == 2) begin
            exp_i[0] <= score_0[counter_2][4];
        end
        else if(counter_1 == 3) begin
            exp_i[0] <= score_1[counter_2][0];
            exp_i[1] <= score_1[counter_2][1];
        end
        else if(counter_1 == 4) begin
            exp_i[0] <= score_1[counter_2][2];
            exp_i[1] <= score_1[counter_2][3];
        end
        else if(counter_1 == 5) begin
            exp_i[0] <= score_1[counter_2][4];
        end
    end
    else begin
        exp_i[0] <= exp_i[0]; exp_i[1] <= exp_i[1];
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 4 ; i ++) mult_a[i] <= 0;
    else if(current_state == CAL_1) begin
        if((counter_1 >> 2) == 0) begin
            mult_a[0] <= indata[0][0];
            mult_a[1] <= indata[0][1];
            mult_a[2] <= indata[0][2];
            mult_a[3] <= indata[0][3];
        end
        else if((counter_1 >> 2) == 1) begin
            mult_a[0] <= indata[1][0];
            mult_a[1] <= indata[1][1];
            mult_a[2] <= indata[1][2];
            mult_a[3] <= indata[1][3];
        end
        else if((counter_1 >> 2) == 2) begin
            mult_a[0] <= indata[2][0];
            mult_a[1] <= indata[2][1];
            mult_a[2] <= indata[2][2];
            mult_a[3] <= indata[2][3];
        end
        else if((counter_1 >> 2) == 3) begin
            mult_a[0] <= indata[3][0];
            mult_a[1] <= indata[3][1];
            mult_a[2] <= indata[3][2];
            mult_a[3] <= indata[3][3];
        end
        else if((counter_1 >> 2) == 4) begin
            mult_a[0] <= indata[4][0];
            mult_a[1] <= indata[4][1];
            mult_a[2] <= indata[4][2];
            mult_a[3] <= indata[4][3];
        end
    end
    else if(current_state == CAL_2) begin
        if((counter_1 / 5) == 0) begin
            mult_a[0] <= head_q_0[0][0];
            mult_a[1] <= head_q_0[0][1];
            mult_a[2] <= head_q_1[0][0];
            mult_a[3] <= head_q_1[0][1];
        end
        else if((counter_1 / 5) == 1) begin
            mult_a[0] <= head_q_0[1][0];
            mult_a[1] <= head_q_0[1][1];
            mult_a[2] <= head_q_1[1][0];
            mult_a[3] <= head_q_1[1][1];
        end
        else if((counter_1 / 5) == 2) begin
            mult_a[0] <= head_q_0[2][0];
            mult_a[1] <= head_q_0[2][1];
            mult_a[2] <= head_q_1[2][0];
            mult_a[3] <= head_q_1[2][1];
        end
        else if((counter_1 / 5) == 3) begin
            mult_a[0] <= head_q_0[3][0];
            mult_a[1] <= head_q_0[3][1];
            mult_a[2] <= head_q_1[3][0];
            mult_a[3] <= head_q_1[3][1];
        end
        else if((counter_1 / 5) == 4) begin
            mult_a[0] <= head_q_0[4][0];
            mult_a[1] <= head_q_0[4][1];
            mult_a[2] <= head_q_1[4][0];
            mult_a[3] <= head_q_1[4][1];
        end
    end
    else if(current_state == CAL_4) begin
        if((counter_1 >> 1) == 0) begin
            mult_a[0] <= score_0[0][0];
            mult_a[1] <= score_0[0][1];
            mult_a[2] <= score_0[0][2];
            mult_a[3] <= score_0[0][3];
        end
        else if((counter_1 >> 1) == 1) begin
            mult_a[0] <= score_0[1][0];
            mult_a[1] <= score_0[1][1];
            mult_a[2] <= score_0[1][2];
            mult_a[3] <= score_0[1][3];
        end
        else if((counter_1 >> 1) == 2) begin
            mult_a[0] <= score_0[2][0];
            mult_a[1] <= score_0[2][1];
            mult_a[2] <= score_0[2][2];
            mult_a[3] <= score_0[2][3];
        end
        else if((counter_1 >> 1) == 3) begin
            mult_a[0] <= score_0[3][0];
            mult_a[1] <= score_0[3][1];
            mult_a[2] <= score_0[3][2];
            mult_a[3] <= score_0[3][3];
        end
        else if((counter_1 >> 1) == 4) begin
            mult_a[0] <= score_0[4][0];
            mult_a[1] <= score_0[4][1];
            mult_a[2] <= score_0[4][2];
            mult_a[3] <= score_0[4][3];
        end
    end
    else if(current_state == CAL_5) begin
        if((counter_1 >> 1) == 0) begin
            mult_a[0] <= score_1[0][0];
            mult_a[1] <= score_1[0][1];
            mult_a[2] <= score_1[0][2];
            mult_a[3] <= score_1[0][3];
        end
        else if((counter_1 >> 1) == 1) begin
            mult_a[0] <= score_1[1][0];
            mult_a[1] <= score_1[1][1];
            mult_a[2] <= score_1[1][2];
            mult_a[3] <= score_1[1][3];
        end
        else if((counter_1 >> 1) == 2) begin
            mult_a[0] <= score_1[2][0];
            mult_a[1] <= score_1[2][1];
            mult_a[2] <= score_1[2][2];
            mult_a[3] <= score_1[2][3];
        end
        else if((counter_1 >> 1) == 3) begin
            mult_a[0] <= score_1[3][0];
            mult_a[1] <= score_1[3][1];
            mult_a[2] <= score_1[3][2];
            mult_a[3] <= score_1[3][3];
        end
        else if((counter_1 >> 1) == 4) begin
            mult_a[0] <= score_1[4][0];
            mult_a[1] <= score_1[4][1];
            mult_a[2] <= score_1[4][2];
            mult_a[3] <= score_1[4][3];
        end
    end
    else if(current_state == OUT) begin
        if((counter_1 >> 2) == 0) begin
            mult_a[0] <= head_k_0[0][0];
            mult_a[1] <= head_k_0[0][1];
            mult_a[2] <= head_k_1[0][0];
            mult_a[3] <= head_k_1[0][1];
        end
        else if((counter_1 >> 2) == 1) begin
            mult_a[0] <= head_k_0[1][0];;
            mult_a[1] <= head_k_0[1][1];;
            mult_a[2] <= head_k_1[1][0];;
            mult_a[3] <= head_k_1[1][1];;
        end
        else if((counter_1 >> 2) == 2) begin
            mult_a[0] <= head_k_0[2][0];
            mult_a[1] <= head_k_0[2][1];
            mult_a[2] <= head_k_1[2][0];
            mult_a[3] <= head_k_1[2][1];
        end
        else if((counter_1 >> 2) == 3) begin
            mult_a[0] <= head_k_0[3][0];
            mult_a[1] <= head_k_0[3][1];
            mult_a[2] <= head_k_1[3][0];
            mult_a[3] <= head_k_1[3][1];
        end
        else if((counter_1 >> 2) == 4) begin
            mult_a[0] <= head_k_0[4][0];
            mult_a[1] <= head_k_0[4][1];
            mult_a[2] <= head_k_1[4][0];
            mult_a[3] <= head_k_1[4][1];
        end
    end
    else if(current_state == CAL_3) begin
        if(counter_1 == 1) begin 
            mult_a[0] <= exp_o[0]; 
            mult_a[1] <= exp_o[1]; 
        end
        else if(counter_1 == 2) begin 
            mult_a[2] <= exp_o[0]; 
            mult_a[3] <= exp_o[1]; 
        end
    end
    else for(i = 0 ; i < 4 ; i ++) mult_a[i] <= mult_a[i];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 4 ; i < 8 ; i ++) mult_a[i] <= 0;
    else if(current_state == CAL_1) begin
        if((counter_1 >> 2) == 0) begin
            mult_a[4] <= indata[0][0];
            mult_a[5] <= indata[0][1];
            mult_a[6] <= indata[0][2];
            mult_a[7] <= indata[0][3];
        end
        else if((counter_1 >> 2) == 1) begin
            mult_a[4] <= indata[1][0];
            mult_a[5] <= indata[1][1];
            mult_a[6] <= indata[1][2];
            mult_a[7] <= indata[1][3];
        end
        else if((counter_1 >> 2) == 2) begin
            mult_a[4] <= indata[2][0];
            mult_a[5] <= indata[2][1];
            mult_a[6] <= indata[2][2];
            mult_a[7] <= indata[2][3];
        end
        else if((counter_1 >> 2) == 3) begin
            mult_a[4] <= indata[3][0];
            mult_a[5] <= indata[3][1];
            mult_a[6] <= indata[3][2];
            mult_a[7] <= indata[3][3];
        end
        else if((counter_1 >> 2) == 4) begin
            mult_a[4] <= indata[4][0];
            mult_a[5] <= indata[4][1];
            mult_a[6] <= indata[4][2];
            mult_a[7] <= indata[4][3];
        end
    end
    else if(current_state == CAL_2) begin
        if((counter_1 >> 2) == 0) begin
            mult_a[4] <= indata[0][0];
            mult_a[5] <= indata[0][1];
            mult_a[6] <= indata[0][2];
            mult_a[7] <= indata[0][3];
        end
        else if((counter_1 >> 2) == 1) begin
            mult_a[4] <= indata[1][0];
            mult_a[5] <= indata[1][1];
            mult_a[6] <= indata[1][2];
            mult_a[7] <= indata[1][3];
        end
        else if((counter_1 >> 2) == 2) begin
            mult_a[4] <= indata[2][0];
            mult_a[5] <= indata[2][1];
            mult_a[6] <= indata[2][2];
            mult_a[7] <= indata[2][3];
        end
        else if((counter_1 >> 2) == 3) begin
            mult_a[4] <= indata[3][0];
            mult_a[5] <= indata[3][1];
            mult_a[6] <= indata[3][2];
            mult_a[7] <= indata[3][3];
        end
        else if((counter_1 >> 2) == 4) begin
            mult_a[4] <= indata[4][0];
            mult_a[5] <= indata[4][1];
            mult_a[6] <= indata[4][2];
            mult_a[7] <= indata[4][3];
        end
    end
    else if(current_state == CAL_4) begin
        if((counter_1 >> 1) == 0) begin
            mult_a[4] <= score_0[0][4];
            mult_a[5] <= 0;
        end
        else if((counter_1 >> 1) == 1) begin
            mult_a[4] <= score_0[1][4];
            mult_a[5] <= 0;
        end
        else if((counter_1 >> 1) == 2) begin
            mult_a[4] <= score_0[2][4];
            mult_a[5] <= 0;
        end
        else if((counter_1 >> 1) == 3) begin
            mult_a[4] <= score_0[3][4];
            mult_a[5] <= 0;
        end
        else if((counter_1 >> 1) == 4) begin
            mult_a[4] <= score_0[4][4];
            mult_a[5] <= 0;
        end
    end
    else if(current_state == CAL_5) begin
        if((counter_1 >> 1) == 0) begin
            mult_a[4] <= score_1[0][4];
            mult_a[5] <= 0;
        end
        else if((counter_1 >> 1) == 1) begin
            mult_a[4] <= score_1[1][4];
            mult_a[5] <= 0;
        end
        else if((counter_1 >> 1) == 2) begin
            mult_a[4] <= score_1[2][4];
            mult_a[5] <= 0;
        end
        else if((counter_1 >> 1) == 3) begin
            mult_a[4] <= score_1[3][4];
            mult_a[5] <= 0;
        end
        else if((counter_1 >> 1) == 4) begin
            mult_a[4] <= score_1[4][4];
            mult_a[5] <= 0;
        end
    end
    else if(current_state == CAL_3) begin
        if(counter_1 == 4) begin 
            mult_a[4] <= exp_o[0]; 
            mult_a[5] <= exp_o[1]; 
        end
        else if(counter_1 == 5) begin 
            mult_a[6] <= exp_o[0]; 
            mult_a[7] <= exp_o[1]; 
        end
    end
    else for(i = 4 ; i < 8 ; i ++) mult_a[i] <= mult_a[i];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 4 ; i ++) mult_b[i] <= 0;
    else if(current_state == CAL_1) begin
        if(counter_1[1:0] == 0) begin
            mult_b[0] <= weight_k[0][0];
            mult_b[1] <= weight_k[1][0];
            mult_b[2] <= weight_k[2][0];
            mult_b[3] <= weight_k[3][0];
        end
        else if(counter_1[1:0] == 1) begin
            mult_b[0] <= weight_k[0][1];
            mult_b[1] <= weight_k[1][1];
            mult_b[2] <= weight_k[2][1];
            mult_b[3] <= weight_k[3][1];
        end
        else if(counter_1[1:0] == 2) begin
            mult_b[0] <= weight_k[0][2];
            mult_b[1] <= weight_k[1][2];
            mult_b[2] <= weight_k[2][2];
            mult_b[3] <= weight_k[3][2];
        end
        else if(counter_1[1:0] == 3) begin
            mult_b[0] <= weight_k[0][3];
            mult_b[1] <= weight_k[1][3];
            mult_b[2] <= weight_k[2][3];
            mult_b[3] <= weight_k[3][3];
        end
    end
    else if(current_state == CAL_2) begin
        if(counter_1 % 5 == 0) begin
            mult_b[0] <= head_k_0[0][0];
            mult_b[1] <= head_k_0[0][1];
            mult_b[2] <= head_k_1[0][0];
            mult_b[3] <= head_k_1[0][1];
        end
        else if(counter_1 % 5 == 1) begin
            mult_b[0] <= head_k_0[1][0];
            mult_b[1] <= head_k_0[1][1];
            mult_b[2] <= head_k_1[1][0];
            mult_b[3] <= head_k_1[1][1];
        end
        else if(counter_1 % 5 == 2) begin
            mult_b[0] <= head_k_0[2][0];
            mult_b[1] <= head_k_0[2][1];
            mult_b[2] <= head_k_1[2][0];
            mult_b[3] <= head_k_1[2][1];
        end
        else if(counter_1 % 5 == 3) begin
            mult_b[0] <= head_k_0[3][0];
            mult_b[1] <= head_k_0[3][1];
            mult_b[2] <= head_k_1[3][0];
            mult_b[3] <= head_k_1[3][1];
        end
        else if(counter_1 % 5 == 4) begin
            mult_b[0] <= head_k_0[4][0];
            mult_b[1] <= head_k_0[4][1];
            mult_b[2] <= head_k_1[4][0];
            mult_b[3] <= head_k_1[4][1];
        end
    end
    else if(current_state == CAL_4) begin
        if(counter_1[0] == 0) begin
            mult_b[0] <= head_v_0[0][0];
            mult_b[1] <= head_v_0[1][0];
            mult_b[2] <= head_v_0[2][0];
            mult_b[3] <= head_v_0[3][0];
        end
        else if(counter_1[0] == 1) begin
            mult_b[0] <= head_v_0[0][1];
            mult_b[1] <= head_v_0[1][1];
            mult_b[2] <= head_v_0[2][1];
            mult_b[3] <= head_v_0[3][1];
        end
    end
    else if(current_state == CAL_5) begin
        if(counter_1[0] == 0) begin
            mult_b[0] <= head_v_1[0][0];
            mult_b[1] <= head_v_1[1][0];
            mult_b[2] <= head_v_1[2][0];
            mult_b[3] <= head_v_1[3][0];
        end
        else if(counter_1[0] == 1) begin
            mult_b[0] <= head_v_1[0][1];
            mult_b[1] <= head_v_1[1][1];
            mult_b[2] <= head_v_1[2][1];
            mult_b[3] <= head_v_1[3][1];
        end
    end
    else if(current_state == OUT) begin
        if(counter_1[1:0] == 0) begin
            mult_b[0] <= outweight[0][0];
            mult_b[1] <= outweight[1][0];
            mult_b[2] <= outweight[2][0];
            mult_b[3] <= outweight[3][0];
        end
        else if(counter_1[1:0] == 1) begin
            mult_b[0] <= outweight[0][1];
            mult_b[1] <= outweight[1][1];
            mult_b[2] <= outweight[2][1];
            mult_b[3] <= outweight[3][1];
        end
        else if(counter_1[1:0] == 2) begin
            mult_b[0] <= outweight[0][2];
            mult_b[1] <= outweight[1][2];
            mult_b[2] <= outweight[2][2];
            mult_b[3] <= outweight[3][2];
        end
        else if(counter_1[1:0] == 3) begin
            mult_b[0] <= outweight[0][3];
            mult_b[1] <= outweight[1][3];
            mult_b[2] <= outweight[2][3];
            mult_b[3] <= outweight[3][3];
        end
    end
    else if(current_state == CAL_3) begin
        if(counter_1 == 1) begin 
            mult_b[0] <= 32'b0111111100000000000000000000000; 
            mult_b[1] <= 32'b0111111100000000000000000000000; 
        end
        else if(counter_1 == 2) begin 
            mult_b[2] <= 32'b0111111100000000000000000000000; 
            mult_b[3] <= 32'b0111111100000000000000000000000; 
        end
    end
    else for(i = 0 ; i < 4 ; i ++) mult_b[i] <= mult_b[i];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 4 ; i < 8 ; i ++) mult_b[i] <= 0;
    else if(current_state == CAL_1) begin
        if(counter_1[1:0] == 0) begin
            mult_b[4] <= weight_q[0][0];
            mult_b[5] <= weight_q[1][0];
            mult_b[6] <= weight_q[2][0];
            mult_b[7] <= weight_q[3][0];
        end
        else if(counter_1[1:0] == 1) begin
            mult_b[4] <= weight_q[0][1];
            mult_b[5] <= weight_q[1][1];
            mult_b[6] <= weight_q[2][1];
            mult_b[7] <= weight_q[3][1];
        end
        else if(counter_1[1:0] == 2) begin
            mult_b[4] <= weight_q[0][2];
            mult_b[5] <= weight_q[1][2];
            mult_b[6] <= weight_q[2][2];
            mult_b[7] <= weight_q[3][2];
        end
        else if(counter_1[1:0] == 3) begin
            mult_b[4] <= weight_q[0][3];
            mult_b[5] <= weight_q[1][3];
            mult_b[6] <= weight_q[2][3];
            mult_b[7] <= weight_q[3][3];
        end
    end
    else if(current_state == CAL_2) begin
        if(counter_1[1:0] == 0) begin
            mult_b[4] <= weight_v[0][0];
            mult_b[5] <= weight_v[1][0];
            mult_b[6] <= weight_v[2][0];
            mult_b[7] <= weight_v[3][0];
        end
        else if(counter_1[1:0] == 1) begin
            mult_b[4] <= weight_v[0][1];
            mult_b[5] <= weight_v[1][1];
            mult_b[6] <= weight_v[2][1];
            mult_b[7] <= weight_v[3][1];
        end
        else if(counter_1[1:0] == 2) begin
            mult_b[4] <= weight_v[0][2];
            mult_b[5] <= weight_v[1][2];
            mult_b[6] <= weight_v[2][2];
            mult_b[7] <= weight_v[3][2];
        end
        else if(counter_1[1:0] == 3) begin
            mult_b[4] <= weight_v[0][3];
            mult_b[5] <= weight_v[1][3];
            mult_b[6] <= weight_v[2][3];
            mult_b[7] <= weight_v[3][3];
        end
    end
    else if(current_state == CAL_4) begin
        if(counter_1[0] == 0) begin
            mult_b[4] <= head_v_0[4][0];
            mult_b[5] <= 0;
        end
        else if(counter_1[0] == 1) begin
            mult_b[4] <= head_v_0[4][1];
            mult_b[5] <= 0;
        end
    end
    else if(current_state == CAL_5) begin
        if(counter_1[0] == 0) begin
            mult_b[4] <= head_v_1[4][0];
            mult_b[5] <= 0;
        end
        else if(counter_1[0] == 1) begin
            mult_b[4] <= head_v_1[4][1];
            mult_b[5] <= 0;
        end
    end
    else if(current_state == CAL_3) begin
        if(counter_1 == 4) begin 
            mult_b[4] <= 32'b0111111100000000000000000000000; 
            mult_b[5] <= 32'b0111111100000000000000000000000; 
        end
        else if(counter_1 == 5) begin 
            mult_b[6] <= 32'b0111111100000000000000000000000; 
            mult_b[7] <= 32'b0111111100000000000000000000000; 
        end
    end
    // else if(current_state == CAL_3) begin
    //     if(counter_1 == 3) begin 
    //         mult_b[4] <= 32'b0111111100000000000000000000000; 
    //         mult_b[5] <= 0; 
    //     end
    // end
    else for(i = 4 ; i < 8 ; i ++) mult_b[i] <= mult_b[i];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        div_a[0] <= 0;
        div_a[1] <= 0;
    end
    else if(current_state == CAL_2) begin
        div_a[0] <= add_z[2];
        div_a[1] <= add_z[3];
    end
    // else if(current_state == CAL_5) begin
    //     div_a[0] <= add_z[1];
    // end
    else if(current_state == CAL_3) begin
        if(counter_1 >= 5) div_a[0] <= indata[counter_3][0];
        if(counter_1 >= 8) div_a[1] <= indata[counter_3_1][1];
    end
    else begin
        div_a[0] <= div_a[0];
        div_a[1] <= div_a[1];
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        div_b[0] <= 0;
        div_b[1] <= 0;
    end
    else if(current_state == CAL_2) begin
        div_b[0] <= Root_num_2;
        div_b[1] <= Root_num_2;
    end
    // else if(current_state == CAL_5) begin
    //     div_b[0] <= Root_num_2;
    // end
    else if(current_state == CAL_3) begin
        if(counter_1 == 5) div_b[0] <= add_z[1];
        else if(counter_1 == 8) div_b[1] <= add_z[1];
    end
    else begin
        div_b[0] <= div_b[0];
        div_b[1] <= div_b[1];
    end
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 5 ; j ++) score_0[i][j] <= 0;
    else if(current_state == CAL_2) begin
        score_0[counter_2 / 5][counter_2 % 5] <= div_z[0];
    end
    else if(current_state == CAL_3) begin
        if(counter_1 >= 6 && counter_1 <= 10) score_0[counter_2][counter_4] <= div_z[0];
    end
    else for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 5 ; j ++) score_0[i][j] <= score_0[i][j];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 5 ; j ++) score_1[i][j] <= 0;
    else if(current_state == CAL_2) begin
        score_1[counter_2 / 5][counter_2 % 5] <= div_z[1];
    end
    else if(current_state == CAL_3) begin
        if(counter_1 >= 9 && counter_1 <= 13) score_1[counter_2][counter_4_1] <= div_z[1];
    end
    else for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 5 ; j ++) score_1[i][j] <= score_1[i][j];
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 2 ; i ++) add_a[i] <= 0;
    else if(current_state == CAL_1 || current_state == CAL_2 || current_state == OUT) begin
        add_a[0] <= add_z[2]; 
        add_a[1] <= add_z[4]; 
    end
    else if(current_state == CAL_4 || current_state == CAL_5) begin
        add_a[0] <= add_z[2]; 
        // add_a[1] <= add_z[4]; 
        add_a[1] <= add_z_4_span;
    end
    else if(current_state == CAL_3) begin
        if(counter_1 == 3) add_a[0] <= add_z[2]; 
        else if(counter_1 == 4) add_a[1] <= add_z[0]; 
        if(counter_1 == 6) add_a[0] <= add_z[4]; 
        else if(counter_1 == 7) add_a[1] <= add_z[0]; 
        // add_a[1] <= add_z_4_span;
    end
    else for(i = 0 ; i < 2 ; i ++) add_a[i] <= add_a[i];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 2 ; i ++) add_b[i] <= 0;
    else if(current_state == CAL_1 || current_state == CAL_2 || current_state == OUT) begin
        add_b[0] <= add_z[3]; 
        add_b[1] <= add_z[5]; 
    end
    else if(current_state == CAL_4 || current_state == CAL_5) begin
        add_b[0] <= add_z[3]; ;
        add_b[1] <= add_z[0];
    end
    else if(current_state == CAL_3) begin
        if(counter_1 == 3) add_b[0] <= add_z[3];
        else if(counter_1 == 4) add_b[1] <= indata[4][0];  
        if(counter_1 == 6) add_b[0] <= add_z[5];
        else if(counter_1 == 7) add_b[1] <= indata[4][1];
    end
    else for(i = 0 ; i < 2 ; i ++) add_b[i] <= add_b[i];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 1 ; j ++) head_k_0[i][j] <= 0;
    else if(current_state == CAL_1) begin
        if(counter_2[1:0] <= 1) head_k_0[counter_2 >> 2][counter_2[1:0]] <= add_z[0];
    end
    else if(current_state == CAL_4) head_k_0[counter_3 >> 1][counter_3[0]] <= add_z[1];
    else for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 1 ; j ++) head_k_0[i][j] <= head_k_0[i][j];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 1 ; j ++) head_k_1[i][j] <= 0;
    else if(current_state == CAL_1) begin
        if(counter_2[1:0] > 1) head_k_1[counter_2 >> 2][(counter_2[1:0]) - 2] <= add_z[0];
    end
    else if(current_state == CAL_5) head_k_1[counter_3 >> 1][counter_3[0]] <= add_z[1];
    else for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 1 ; j ++) head_k_1[i][j] <= head_k_1[i][j];
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 1 ; j ++) head_q_0[i][j] <= 0;
    else if(current_state == CAL_1) begin
        if(counter_2[1:0] <= 1) head_q_0[counter_2 >> 2][counter_2[1:0]] <= add_z[1];
    end
    else for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 1 ; j ++) head_q_0[i][j] <= head_q_0[i][j];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 1 ; j ++) head_q_1[i][j] <= 0;
    else if(current_state == CAL_1) begin
        if(counter_2[1:0] > 1) head_q_1[counter_2 >> 2][(counter_2[1:0]) - 2] <= add_z[1];
    end
    else for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 1 ; j ++) head_q_1[i][j] <= head_q_1[i][j];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 1 ; j ++) head_v_0[i][j] <= 0;
    else if(current_state == CAL_2) begin
        if(counter_2[1:0] <= 1) head_v_0[counter_2 >> 2][counter_2[1:0]] <= add_z[1];
    end
    else for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 1 ; j ++) head_v_0[i][j] <= head_v_0[i][j];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 1 ; j ++) head_v_1[i][j] <= 0;
    else if(current_state == CAL_2) begin
        if(counter_2[1:0] > 1) head_v_1[counter_2 >> 2][(counter_2[1:0]) - 2] <= add_z[1];
    end
    else for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 1 ; j ++) head_v_1[i][j] <= head_v_1[i][j];
end





always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 4 ; j ++) indata[i][j] <= 0;
    else if(current_state == CAL_3) begin
        if(counter_1 == 1) begin
            indata[0][0] <= exp_o[0];
            indata[1][0] <= exp_o[1];
        end
        else if(counter_1 == 2) begin
            indata[2][0] <= exp_o[0];
            indata[3][0] <= exp_o[1];
        end
        else if(counter_1 == 3) begin
            indata[4][0] <= exp_o[0];
        end
        else if(counter_1 == 4) begin
            indata[0][1] <= exp_o[0];
            indata[1][1] <= exp_o[1];
        end
        else if(counter_1 == 5) begin
            indata[2][1] <= exp_o[0];
            indata[3][1] <= exp_o[1];
        end
        else if(counter_1 == 6) begin
            indata[4][1] <= exp_o[0];
        end
    end 
    else if(current_state == IN || (current_state == IDLE && in_valid)) indata[counter_1][counter_2] <= in_str;
    // else if(current_state == OUT) indata[counter_2 >> 2][counter_2[1:0]] <= add_z[0];
    else for(i = 0 ; i < 5 ; i ++) for(j = 0 ; j < 4 ; j ++) indata[i][j] <= indata[i][j];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 4 ; i ++) for(j = 0 ; j < 4 ; j ++) weight_k[i][j] <= 0;
    else if(current_state == IN || (current_state == IDLE && in_valid) && counter_1 < 4) weight_k[counter_2][counter_1] <= k_weight;
    else for(i = 0 ; i < 4 ; i ++) for(j = 0 ; j < 4 ; j ++) weight_k[i][j] <= weight_k[i][j];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 4 ; i ++) for(j = 0 ; j < 4 ; j ++) weight_q[i][j] <= 0;
    else if(current_state == IN || (current_state == IDLE && in_valid) && counter_1 < 4) weight_q[counter_2][counter_1] <= q_weight;
    else for(i = 0 ; i < 4 ; i ++) for(j = 0 ; j < 4 ; j ++) weight_q[i][j] <= weight_q[i][j];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 4 ; i ++) for(j = 0 ; j < 4 ; j ++) weight_v[i][j] <= 0;
    else if(current_state == IN || (current_state == IDLE && in_valid) && counter_1 < 4) weight_v[counter_2][counter_1] <= v_weight;
    else for(i = 0 ; i < 4 ; i ++) for(j = 0 ; j < 4 ; j ++) weight_v[i][j] <= weight_v[i][j];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 4 ; i ++) for(j = 0 ; j < 4 ; j ++) outweight[i][j] <= 0;
    else if(current_state == IN || (current_state == IDLE && in_valid) && counter_1 < 4) outweight[counter_2][counter_1] <= out_weight;
    else for(i = 0 ; i < 4 ; i ++) for(j = 0 ; j < 4 ; j ++) outweight[i][j] <= outweight[i][j];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid <= 0;
    else if(current_state == OUT && counter_1 >= 2) out_valid <= 1;
    else out_valid <= 0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) out <= 0;
    else if(current_state == OUT && counter_1 >= 2) out <= add_z[0];
    else out <= 0;
end

endmodule
