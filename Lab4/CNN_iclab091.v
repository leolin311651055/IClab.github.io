//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Cheng-Te Chang (chengdez.ee12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
// synopsys translate_off
// `include "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_mult.v"
// `include "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_sum3.v"
// `include "/usr/cad/synopsys/synthesis/cur/dw/sim_ver/DW_fp_add.v"
// synopsys translate_on

module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,

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

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel, Weight;
input [1:0] Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;


//register
reg [47:0][31:0] img_catch_convolution_result; //image catch and convolution result
reg [107:0][31:0] Image_padding;
reg [26:0][31:0] Kernel_catch;
reg [3:0][31:0] Weight_catch;
reg [1:0] Opt_catch;
reg [7:0] current_state,next_state;
reg [7:0] counter,counter_output;

reg [8:0][31:0] mult_in2;
reg [8:0][31:0] mult_in1;
reg [8:0][31:0] mult_out;
reg [15:0][31:0] convolution_output;
// reg [3:0][31:0] convolution_out;
reg [1:0] padding;
reg[3:0][31:0] pooling_fullyconnect_xscale_outputs; //pooling and fully connect and xscale and outputs
reg[1:0][31:0] compair;
reg[3:0][31:0] normolize;
reg[3:0][31:0] fully_normolize;
reg[31:0] max,mini;
reg[31:0] denominator; 
reg[31:0] sub_ina,sub_inb,sub_out;
reg[31:0] div_ina,div_inb,div_out;
reg[31:0] exp_in_1,exp_out_1,ln_in_1,ln_out_1;
reg cmp_pick;
reg [3:0][31:0] exp_1,exp_2;
reg [3:0][31:0] add_sub_1,add_sub_2;
reg [4:0][31:0] add_in0,add_in1,add_in2,add_out;


//state parameter
parameter IDLE = 0;
parameter LOAD = 1;
parameter PADDING = 2;
parameter CONVOLUTION = 3;
parameter MAXPOOLING = 4; //CONVOLUTION and MAXPOOLING 
parameter FULLYCONNECT = 5;
parameter MAXORMINI = 6;
parameter NORMOLIZATION = 7;
parameter ACTIVEFUNCTION = 8;
parameter FLOATING_ONE = 32'b00111111100000000000000000000000;
integer i;


//Mult 1
DW_fp_mult #(23,8,1) mult_convolution_0 ( .a(mult_in1[0]),.b(mult_in2[0]),.rnd(3'b000),.z(mult_out[0]));
DW_fp_mult #(23,8,1) mult_convolution_1 ( .a(mult_in1[1]),.b(mult_in2[1]),.rnd(3'b000),.z(mult_out[1]));
DW_fp_mult #(23,8,1) mult_convolution_2 ( .a(mult_in1[2]),.b(mult_in2[2]),.rnd(3'b000),.z(mult_out[2]));
DW_fp_mult #(23,8,1) mult_convolution_3 ( .a(mult_in1[3]),.b(mult_in2[3]),.rnd(3'b000),.z(mult_out[3]));
DW_fp_mult #(23,8,1) mult_convolution_4 ( .a(mult_in1[4]),.b(mult_in2[4]),.rnd(3'b000),.z(mult_out[4]));
DW_fp_mult #(23,8,1) mult_convolution_5 ( .a(mult_in1[5]),.b(mult_in2[5]),.rnd(3'b000),.z(mult_out[5]));
DW_fp_mult #(23,8,1) mult_convolution_6 ( .a(mult_in1[6]),.b(mult_in2[6]),.rnd(3'b000),.z(mult_out[6]));
DW_fp_mult #(23,8,1) mult_convolution_7 ( .a(mult_in1[7]),.b(mult_in2[7]),.rnd(3'b000),.z(mult_out[7]));
DW_fp_mult #(23,8,1) mult_convolution_8 ( .a(mult_in1[8]),.b(mult_in2[8]),.rnd(3'b000),.z(mult_out[8]));

//Add1
DW_fp_sum3 #(23,8,1) Add_convolution_0( .a(add_in0[0]),.b(add_in1[0]),.c(add_in2[0]),.z(add_out[0]),.rnd(3'b000) );
DW_fp_sum3 #(23,8,1) Add_convolution_1( .a(add_in0[1]),.b(add_in1[1]),.c(add_in2[1]),.z(add_out[1]),.rnd(3'b000) );
DW_fp_sum3 #(23,8,1) Add_convolution_2( .a(add_in0[2]),.b(add_in1[2]),.c(add_in2[2]),.z(add_out[2]),.rnd(3'b000) );

//Add2
DW_fp_sum3 #(23,8,1) Add_convolution_4( .a(add_in0[3]),.b(add_in1[3]),.c(add_in2[3]),.z(add_out[3]),.rnd(3'b000) );

//Max pooling_fullyconnect_xscale_outputs
DW_fp_cmp #(23,8,0) compair1 (.a(compair[0]), .b(compair[1]), .agtb(cmp_pick), .zctr(1'd0));//agtb = 1，a is MAX，agtb = 0，b is Max

//normolization
DW_fp_sub #(23, 8, 1) sub1 ( .a(sub_ina), .b(sub_inb), .rnd(3'b000), .z(sub_out) );
DW_fp_div #(23, 8, 1, 1) div1 ( .a(div_ina), .b(div_inb), .rnd(3'b000), .z(div_out) );

//Active Function
DW_fp_exp #(23, 8, 1, 1) exp1 ( .a(exp_in_1), .z(exp_out_1) );
DW_fp_ln #(23, 8, 1, 1) ln1 ( .a(ln_in_1), .z(ln_out_1) );


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(*) begin
	if(!rst_n) next_state = IDLE;
	else begin
		case(current_state)
			IDLE : begin
				if(in_valid) next_state = LOAD;
				else next_state = current_state;
			end
            LOAD : begin
				if(!in_valid) next_state = PADDING;
				else next_state = current_state;
			end
            PADDING : begin
				if(padding) next_state = CONVOLUTION;
				else next_state = current_state;
			end
            CONVOLUTION : begin
				if(counter == 98) next_state = MAXPOOLING;
				else next_state = current_state;
			end
            MAXPOOLING : begin
				if(counter == 29) next_state = FULLYCONNECT;
				else next_state = current_state;
			end
            FULLYCONNECT : begin
				if(counter == 3) next_state = MAXORMINI;
				else next_state = current_state;
			end
            MAXORMINI : begin
				if(counter == 11) next_state = NORMOLIZATION;
				else next_state = current_state;
			end
            NORMOLIZATION : begin
				if(counter == 17) next_state = ACTIVEFUNCTION;
				else next_state = current_state;
			end
            ACTIVEFUNCTION : begin
				if((Opt_catch == 0 & counter > 4) | (Opt_catch == 1 & counter > 18) | (Opt_catch == 2 & counter > 12) | (Opt_catch == 3 & counter > 12)) next_state = IDLE;
				else next_state = current_state;
			end
			default : next_state = current_state;
		endcase
	end
end

//counter
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 0;
    end
    else if(in_valid) begin
        counter <= counter + 1;
    end

    //for convolution
    else if((counter == 21 | counter == 57) & current_state == CONVOLUTION & counter <= 96) begin
        counter <= counter + 15;
    end
    else if((((((counter)/3))%2 == 1) & (counter)%3 == 0) & current_state == CONVOLUTION & counter <= 96) begin
        counter <= counter + 3;
    end
    else if ((!(((((counter)/3))%2 == 1) & (counter)%3 == 0) & !(counter == 21 | counter == 57)) 
    & current_state == CONVOLUTION & counter <= 97)begin
        counter <= counter + 1;
    end

    // for convolution and max pooling_fullyconnect_xscale_outputs
    else if (current_state == MAXPOOLING & counter <= 29)begin
        counter <= counter + 1;
    end
    else if(current_state == MAXPOOLING & counter == 29) counter <= 0;
    else if(current_state == FULLYCONNECT & counter <= 2) begin //use old mult
        counter <= counter + 1;
    end
    else if(current_state == MAXORMINI & counter <= 10) begin //use old mult
        counter <= counter + 1;
    end
    else if(current_state == NORMOLIZATION & counter <= 16) begin //use old mult
        counter <= counter + 1;
    end
    else if(current_state == ACTIVEFUNCTION & ((Opt_catch == 0 & counter <= 4) | (Opt_catch == 1 & counter <= 18) | (Opt_catch == 2 & counter <= 12) | (Opt_catch == 3 & counter <= 12))) begin //use old mult
        counter <= counter + 1;
    end
    else if(current_state == ACTIVEFUNCTION & !((Opt_catch == 0 & counter <= 4) | (Opt_catch == 1 & counter <= 18) | (Opt_catch == 2 & counter <= 12) | (Opt_catch == 3 & counter <= 12))) begin //use old mult
        counter <= 0;
    end
    else begin
        counter <= 0;
    end
end


//Image
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        img_catch_convolution_result <= 0; 
    end
    else if(in_valid) begin
        img_catch_convolution_result[counter] <= Img;
    end
    else if(current_state == CONVOLUTION) begin
       img_catch_convolution_result[counter_output-3] <= add_out[3];
    end
    else begin
        img_catch_convolution_result <= img_catch_convolution_result; 
    end
end




//weight
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Weight_catch <= 0; 
    end
    else if(in_valid & counter <= 3) begin
        Weight_catch[counter] <= Weight;
    end
    else begin
        Weight_catch <= Weight_catch; 
    end
end


//Kernel
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Kernel_catch <= 0; 
    end
    else if(in_valid & counter <= 26) begin
        Kernel_catch[counter] <= Kernel;
    end
    else begin
        Kernel_catch <= Kernel_catch; 
    end
end

//Opt
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Opt_catch <= 0; 
    end
    else if(in_valid & counter == 0) begin
        Opt_catch <= Opt;
    end
    else begin
        Opt_catch <= Opt_catch; 
    end
end

//Image Padding
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Image_padding <= 0; 
        padding <= 0;
    end
    else if(current_state == PADDING & Opt_catch[1] == 0) begin
        for(i=0;i<108;i++) begin
            if(i/6 == 0 | i/6 == 5 | i/6 == 6 | i/6 == 11 | i/6 == 12 | i/6 == 17 | i%6 == 5 | i%6 == 0) begin
                Image_padding[i] <= 0;
            end
            else if(i <= 35) Image_padding[i] <= img_catch_convolution_result[i-(5+(i/6)*2)];
            else if(i <= 71 & i > 35) Image_padding[i] <= img_catch_convolution_result[i-(13+(i/6)*2)];
            else if(i <= 107 & i > 71) Image_padding[i] <= img_catch_convolution_result[i-(21+(i/6)*2)];
        end
        padding <= 1;
        //Image_padding[counter] <= Opt;
    end
    else if(current_state == PADDING & Opt_catch[1] == 1) begin
        for(i=0;i<108;i++) begin
            if(i == 0) Image_padding[i] <= img_catch_convolution_result[0];
            else if(i == 1) Image_padding[i] <= img_catch_convolution_result[0];
            else if(i == 2) Image_padding[i] <= img_catch_convolution_result[1];
            else if(i == 3) Image_padding[i] <= img_catch_convolution_result[2];
            else if(i == 4) Image_padding[i] <= img_catch_convolution_result[3];
            else if(i == 5) Image_padding[i] <= img_catch_convolution_result[3];
            else if(i == 6) Image_padding[i] <= img_catch_convolution_result[0];
            else if(i == 11) Image_padding[i] <= img_catch_convolution_result[3];
            else if(i == 12) Image_padding[i] <= img_catch_convolution_result[4];
            else if(i == 17) Image_padding[i] <= img_catch_convolution_result[7];
            else if(i == 18) Image_padding[i] <= img_catch_convolution_result[8];
            else if(i == 23) Image_padding[i] <= img_catch_convolution_result[11];
            else if(i == 24) Image_padding[i] <= img_catch_convolution_result[12];
            else if(i == 29) Image_padding[i] <= img_catch_convolution_result[15];
            else if(i == 30) Image_padding[i] <= img_catch_convolution_result[12];
            else if(i == 31) Image_padding[i] <= img_catch_convolution_result[12];
            else if(i == 32) Image_padding[i] <= img_catch_convolution_result[13];
            else if(i == 33) Image_padding[i] <= img_catch_convolution_result[14];
            else if(i == 34) Image_padding[i] <= img_catch_convolution_result[15];
            else if(i == 35) Image_padding[i] <= img_catch_convolution_result[15];

            else if(i == 36) Image_padding[i] <= img_catch_convolution_result[16];
            else if(i == 37) Image_padding[i] <= img_catch_convolution_result[16];
            else if(i == 38) Image_padding[i] <= img_catch_convolution_result[17];
            else if(i == 39) Image_padding[i] <= img_catch_convolution_result[18];
            else if(i == 40) Image_padding[i] <= img_catch_convolution_result[19];
            else if(i == 41) Image_padding[i] <= img_catch_convolution_result[19];
            else if(i == 42) Image_padding[i] <= img_catch_convolution_result[16];
            else if(i == 47) Image_padding[i] <= img_catch_convolution_result[19];
            else if(i == 48) Image_padding[i] <= img_catch_convolution_result[20];
            else if(i == 53) Image_padding[i] <= img_catch_convolution_result[23];
            else if(i == 54) Image_padding[i] <= img_catch_convolution_result[24];
            else if(i == 59) Image_padding[i] <= img_catch_convolution_result[27];
            else if(i == 60) Image_padding[i] <= img_catch_convolution_result[28];
            else if(i == 65) Image_padding[i] <= img_catch_convolution_result[31];
            else if(i == 66) Image_padding[i] <= img_catch_convolution_result[28];
            else if(i == 67) Image_padding[i] <= img_catch_convolution_result[28];
            else if(i == 68) Image_padding[i] <= img_catch_convolution_result[29];
            else if(i == 69) Image_padding[i] <= img_catch_convolution_result[30];
            else if(i == 70) Image_padding[i] <= img_catch_convolution_result[31];
            else if(i == 71) Image_padding[i] <= img_catch_convolution_result[31];

            else if(i == 72) Image_padding[i] <= img_catch_convolution_result[32];
            else if(i == 73) Image_padding[i] <= img_catch_convolution_result[32];
            else if(i == 74) Image_padding[i] <= img_catch_convolution_result[33];
            else if(i == 75) Image_padding[i] <= img_catch_convolution_result[34];
            else if(i == 76) Image_padding[i] <= img_catch_convolution_result[35];
            else if(i == 77) Image_padding[i] <= img_catch_convolution_result[35];
            else if(i == 78) Image_padding[i] <= img_catch_convolution_result[32];
            else if(i == 83) Image_padding[i] <= img_catch_convolution_result[35];
            else if(i == 84) Image_padding[i] <= img_catch_convolution_result[36];
            else if(i == 89) Image_padding[i] <= img_catch_convolution_result[39];
            else if(i == 90) Image_padding[i] <= img_catch_convolution_result[40];
            else if(i == 95) Image_padding[i] <= img_catch_convolution_result[43];
            else if(i == 96) Image_padding[i] <= img_catch_convolution_result[44];
            else if(i == 101) Image_padding[i] <= img_catch_convolution_result[47];
            else if(i == 102) Image_padding[i] <= img_catch_convolution_result[44];
            else if(i == 103) Image_padding[i] <= img_catch_convolution_result[44];
            else if(i == 104) Image_padding[i] <= img_catch_convolution_result[45];
            else if(i == 105) Image_padding[i] <= img_catch_convolution_result[46];
            else if(i == 106) Image_padding[i] <= img_catch_convolution_result[47];
            else if(i == 107) Image_padding[i] <= img_catch_convolution_result[47];

            else if(i <= 35) Image_padding[i] <= img_catch_convolution_result[i-(5+(i/6)*2)];
            else if(i <= 71 & i > 35) Image_padding[i] <= img_catch_convolution_result[i-(13+(i/6)*2)];
            else if(i <= 107 & i > 71) Image_padding[i] <= img_catch_convolution_result[i-(21+(i/6)*2)];
        end
        padding <= 1;
    end
    else begin
        Image_padding <= Image_padding; 
        padding <= 0;
    end
end


//convolution
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        add_in0 <= 0;
        add_in1 <= 0;
        add_in2 <= 0;
    end
    else if(current_state == CONVOLUTION | current_state == FULLYCONNECT) begin
        add_in0[0] <= mult_out[0];
        add_in0[1] <= mult_out[3];
        add_in0[2] <= mult_out[6];
        add_in0[3] <= add_out[0];
        add_in1[0] <= mult_out[1];
        add_in1[1] <= mult_out[4];
        add_in1[2] <= mult_out[7];
        add_in1[3] <= add_out[1];
        add_in2[0] <= mult_out[2];
        add_in2[1] <= mult_out[5];
        add_in2[2] <= mult_out[8];
        add_in2[3] <= add_out[2];
    end


    else if(current_state == MAXPOOLING & counter_output <= 15) begin
        add_in0[3] <= img_catch_convolution_result[counter];
        add_in1[3] <= img_catch_convolution_result[counter+16];
        add_in2[3] <= img_catch_convolution_result[counter+32];
    end
    

    //Active Function Case1
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 4) begin
        add_in0[3] <= exp_2[0];
        add_in1[3] <= 0;
        add_in2[3] <= exp_1[0];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 6) begin
        add_in0[3] <= exp_2[1];
        add_in1[3] <= 0;
        add_in2[3] <= exp_1[1];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 8) begin
        add_in0[3] <= exp_2[2];
        add_in1[3] <= 0;
        add_in2[3] <= exp_1[2];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 10) begin
        add_in0[3] <= exp_2[3];
        add_in1[3] <= 0;
        add_in2[3] <= exp_1[3];
    end


    //Active Function Case2
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 2) begin
        add_in0[3] <= FLOATING_ONE;
        add_in1[3] <= 0;
        add_in2[3] <= exp_1[0];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 4) begin
        add_in0[3] <= FLOATING_ONE;
        add_in1[3] <= 0;
        add_in2[3] <= exp_1[1];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 6) begin
        add_in0[3] <= FLOATING_ONE;
        add_in1[3] <= 0;
        add_in2[3] <= exp_1[2];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 8) begin
        add_in0[3] <= FLOATING_ONE;
        add_in1[3] <= 0;
        add_in2[3] <= exp_1[3];
    end

    //Active Function Case3
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 2) begin
        add_in0[3] <= FLOATING_ONE;
        add_in1[3] <= 0;
        add_in2[3] <= exp_1[0];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 4) begin
        add_in0[3] <= FLOATING_ONE;
        add_in1[3] <= 0;
        add_in2[3] <= exp_1[1];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 6) begin
        add_in0[3] <= FLOATING_ONE;
        add_in1[3] <= 0;
        add_in2[3] <= exp_1[2];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 8) begin
        add_in0[3] <= FLOATING_ONE;
        add_in1[3] <= 0;
        add_in2[3] <= exp_1[3];
    end
    else begin
        add_in0 <= add_in0;
        add_in1 <= add_in1;
        add_in2 <= add_in2;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mult_in1 <= 0;
    end
    else if(counter <= 93 & current_state == CONVOLUTION) begin
        mult_in1[0] <= Image_padding[counter];
        mult_in1[1] <= Image_padding[counter+1];
        mult_in1[2] <= Image_padding[counter+2];
        mult_in1[3] <= Image_padding[counter+6];
        mult_in1[4] <= Image_padding[counter+7];
        mult_in1[5] <= Image_padding[counter+8];
        mult_in1[6] <= Image_padding[counter+12];
        mult_in1[7] <= Image_padding[counter+13];
        mult_in1[8] <= Image_padding[counter+14];
    end
    else if(current_state == FULLYCONNECT & counter == 0) begin //state 5
        mult_in1[0] <= pooling_fullyconnect_xscale_outputs[0];
        mult_in1[1] <= pooling_fullyconnect_xscale_outputs[1];
        mult_in1[2] <= 0;
        mult_in1[3] <= pooling_fullyconnect_xscale_outputs[0];
        mult_in1[4] <= pooling_fullyconnect_xscale_outputs[1];
        mult_in1[5] <= 0;
    end
    else if(current_state == FULLYCONNECT & counter == 1) begin //state 5
        mult_in1[0] <= pooling_fullyconnect_xscale_outputs[2];
        mult_in1[1] <= pooling_fullyconnect_xscale_outputs[3];
        mult_in1[2] <= 0;
        mult_in1[3] <= pooling_fullyconnect_xscale_outputs[2];
        mult_in1[4] <= pooling_fullyconnect_xscale_outputs[3];
        mult_in1[5] <= 0;
    end
    else begin
        mult_in1 <= 0;
    end
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter_output <= 0;
    end
    //for convolution
    else if((counter == 21 | counter == 57) & current_state == CONVOLUTION & counter <= 96) begin
        counter_output <= counter_output + 1;
    end
    else if((((((counter)/3))%2 == 1) & (counter)%3 == 0) & current_state == CONVOLUTION & counter <= 96) begin
        counter_output <= counter_output + 1;
    end
    else if ((!(((((counter)/3))%2 == 1) & (counter)%3 == 0) & !(counter == 21 | counter == 57)) 
    & current_state == CONVOLUTION & counter <= 97)begin
        counter_output <= counter_output + 1;
    end
    else begin
        counter_output <= 0;
    end
end

//convolution kernel
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mult_in2 <= 0;
    end
    else if(counter <= 21 & current_state == CONVOLUTION) begin
       mult_in2[8:0] <= Kernel_catch[8:0];
    end
    else if(counter > 21 & counter <= 57 & current_state == CONVOLUTION) begin
       mult_in2[8:0] <= Kernel_catch[17:9];
    end
    else if(counter > 57 & counter <= 93 & current_state == CONVOLUTION) begin
       mult_in2[8:0] <= Kernel_catch[26:18];
    end
    else if(current_state == FULLYCONNECT & counter == 0) begin //state 5
        mult_in2[0] <= Weight_catch[0];
        mult_in2[1] <= Weight_catch[2];
        mult_in2[2] <= 0;
        mult_in2[3] <= Weight_catch[1];
        mult_in2[4] <= Weight_catch[3];
        mult_in2[5] <= 0;
    end
    else if(current_state == FULLYCONNECT & counter == 1) begin //state 5
        mult_in2[0] <= Weight_catch[0];
        mult_in2[1] <= Weight_catch[2];
        mult_in2[2] <= 0;;
        mult_in2[3] <= Weight_catch[1];
        mult_in2[4] <= Weight_catch[3];
        mult_in2[5] <= 0;;
    end
    else begin
        mult_in2 <= 0;
    end
end

// //convolution output
// always@(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         img_catch_convolution_result <= 0;
//     end
//     else if(current_state == CONVOLUTION) begin
//        img_catch_convolution_result[counter_output-3] <= add_out[3];
//     end
//     else begin
//         img_catch_convolution_result <= img_catch_convolution_result;
//     end
// end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        convolution_output <= 0;
    end
    else if(current_state == MAXPOOLING) begin
       convolution_output[counter-1] <= add_out[3];
    end
    else begin
        convolution_output <= convolution_output;
    end
end

//Max pooling_fullyconnect_xscale_outputs
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pooling_fullyconnect_xscale_outputs <= 0;
        compair[1:0] <= 2'b0;
    end

    //Max pooling_fullyconnect_xscale_outputs Number1
    else if(current_state == MAXPOOLING & counter == 6) begin
       compair[0] <= convolution_output[0];
       compair[1] <= convolution_output[1];
    end
    else if(current_state == MAXPOOLING & counter == 7) begin
        if(cmp_pick == 1) pooling_fullyconnect_xscale_outputs[0] <= compair[0];
        else pooling_fullyconnect_xscale_outputs[0] <= compair[1];
    end
    else if(current_state == MAXPOOLING & counter == 8) begin
       compair[0] <= convolution_output[4];
       compair[1] <= pooling_fullyconnect_xscale_outputs[0];;
    end
    else if(current_state == MAXPOOLING & counter == 9) begin
        if(cmp_pick == 1) pooling_fullyconnect_xscale_outputs[0] <= compair[0];
        else pooling_fullyconnect_xscale_outputs[0] <= compair[1];
    end
    else if(current_state == MAXPOOLING & counter == 10) begin
       compair[0] <= convolution_output[5];
       compair[1] <= pooling_fullyconnect_xscale_outputs[0];
    end
    else if(current_state == MAXPOOLING & counter == 11) begin
        if(cmp_pick == 1) pooling_fullyconnect_xscale_outputs[0] <= compair[0];
        else pooling_fullyconnect_xscale_outputs[0] <= compair[1];
    end

    //Max pooling_fullyconnect_xscale_outputs Number2
    else if(current_state == MAXPOOLING & counter == 12) begin
       compair[0] <= convolution_output[2];
       compair[1] <= convolution_output[3];
    end
    else if(current_state == MAXPOOLING & counter == 13) begin
        if(cmp_pick == 1) pooling_fullyconnect_xscale_outputs[1] <= compair[0];
        else pooling_fullyconnect_xscale_outputs[1] <= compair[1];
    end
    else if(current_state == MAXPOOLING & counter == 14) begin
       compair[0] <= convolution_output[6];
       compair[1] <= pooling_fullyconnect_xscale_outputs[1];
    end
    else if(current_state == MAXPOOLING & counter == 15) begin
        if(cmp_pick == 1) pooling_fullyconnect_xscale_outputs[1] <= compair[0];
        else pooling_fullyconnect_xscale_outputs[1] <= compair[1];
    end
    else if(current_state == MAXPOOLING & counter == 16) begin
       compair[0] <= convolution_output[7];
       compair[1] <= pooling_fullyconnect_xscale_outputs[1];
    end
    else if(current_state == MAXPOOLING & counter == 17) begin
        if(cmp_pick == 1) pooling_fullyconnect_xscale_outputs[1] <= compair[0];
        else pooling_fullyconnect_xscale_outputs[1] <= compair[1];
    end

    //Max pooling_fullyconnect_xscale_outputs Number3
    else if(current_state == MAXPOOLING & counter == 18) begin
       compair[0] <= convolution_output[8];
       compair[1] <= convolution_output[9];
    end
    else if(current_state == MAXPOOLING & counter == 19) begin
        if(cmp_pick == 1) pooling_fullyconnect_xscale_outputs[2] <= compair[0];
        else pooling_fullyconnect_xscale_outputs[2] <= compair[1];
    end
    else if(current_state == MAXPOOLING & counter == 20) begin
       compair[0] <= convolution_output[12];
       compair[1] <= pooling_fullyconnect_xscale_outputs[2];
    end
    else if(current_state == MAXPOOLING & counter == 21) begin
        if(cmp_pick == 1) pooling_fullyconnect_xscale_outputs[2] <= compair[0];
        else pooling_fullyconnect_xscale_outputs[2] <= compair[1];
    end
    else if(current_state == MAXPOOLING & counter == 22) begin
       compair[0] <= convolution_output[13];
       compair[1] <= pooling_fullyconnect_xscale_outputs[2];
    end
    else if(current_state == MAXPOOLING & counter == 23) begin
        if(cmp_pick == 1) pooling_fullyconnect_xscale_outputs[2] <= compair[0];
        else pooling_fullyconnect_xscale_outputs[2] <= compair[1];
    end

    //Max pooling_fullyconnect_xscale_outputs Number4
    else if(current_state == MAXPOOLING & counter == 24) begin
       compair[0] <= convolution_output[10];
       compair[1] <= convolution_output[11];
    end
    else if(current_state == MAXPOOLING & counter == 25) begin
        if(cmp_pick == 1) pooling_fullyconnect_xscale_outputs[3] <= compair[0];
        else pooling_fullyconnect_xscale_outputs[3] <= compair[1];
    end
    else if(current_state == MAXPOOLING & counter == 26) begin
       compair[0] <= convolution_output[14];
       compair[1] <= pooling_fullyconnect_xscale_outputs[3];
    end
    else if(current_state == MAXPOOLING & counter == 27) begin
       if(cmp_pick == 1) pooling_fullyconnect_xscale_outputs[3] <= compair[0];
        else pooling_fullyconnect_xscale_outputs[3] <= compair[1];
    end
    else if(current_state == MAXPOOLING & counter == 28) begin
       compair[0] <= convolution_output[15];
       compair[1] <= pooling_fullyconnect_xscale_outputs[3];
    end
    else if(current_state == MAXPOOLING & counter == 29) begin
        if(cmp_pick == 1) pooling_fullyconnect_xscale_outputs[3] <= compair[0];
        else pooling_fullyconnect_xscale_outputs[3] <= compair[1];
    end

    //Normolize find Max
    else if(current_state == MAXORMINI & counter == 0) begin //use old mult
        compair[0] <= pooling_fullyconnect_xscale_outputs[0];
        compair[1] <= pooling_fullyconnect_xscale_outputs[1];
    end
    else if(current_state == MAXORMINI & counter == 2) begin //use old mult
        compair[0] <= max;
        compair[1] <= pooling_fullyconnect_xscale_outputs[2];
    end
    else if(current_state == MAXORMINI & counter == 4) begin //use old mult
        compair[0] <= max;
        compair[1] <= pooling_fullyconnect_xscale_outputs[3];
    end

    //Normolize find mini
    else if(current_state == MAXORMINI & counter == 6) begin //use old mult
        compair[0] <= pooling_fullyconnect_xscale_outputs[0];
        compair[1] <= pooling_fullyconnect_xscale_outputs[1];
    end
    else if(current_state == MAXORMINI & counter == 8) begin //use old mult
        compair[0] <= mini;
        compair[1] <= pooling_fullyconnect_xscale_outputs[2];
    end
    else if(current_state == MAXORMINI & counter == 10) begin //use old mult
        compair[0] <= mini;
        compair[1] <= pooling_fullyconnect_xscale_outputs[3];
    end
    else if(current_state == FULLYCONNECT & counter == 2) begin //use old mult
        pooling_fullyconnect_xscale_outputs[0] <= add_out[0] ;
        pooling_fullyconnect_xscale_outputs[1] <= add_out[1] ;
    end
    else if(current_state == FULLYCONNECT & counter == 3) begin //use old mult
        pooling_fullyconnect_xscale_outputs[2] <= add_out[0] ;
        pooling_fullyconnect_xscale_outputs[3] <= add_out[1] ;
    end
    else if(current_state == NORMOLIZATION & counter == 11)
    begin
        pooling_fullyconnect_xscale_outputs[0] <= div_out;
    end
    else if(current_state == NORMOLIZATION & counter == 13)
    begin
        pooling_fullyconnect_xscale_outputs[1] <= div_out;
    end
    else if(current_state == NORMOLIZATION & counter == 15)
    begin
        pooling_fullyconnect_xscale_outputs[2] <= div_out;
    end
    else if(current_state == NORMOLIZATION & counter == 17)
    begin
        pooling_fullyconnect_xscale_outputs[3] <= div_out;
    end

    else if(current_state == ACTIVEFUNCTION & Opt_catch == 0) begin
        pooling_fullyconnect_xscale_outputs <= pooling_fullyconnect_xscale_outputs;
        //done <= 1;
    end
    //1
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 11) begin
        pooling_fullyconnect_xscale_outputs[0] <= div_out;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 13) begin
        pooling_fullyconnect_xscale_outputs[1] <= div_out;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 15) begin
        pooling_fullyconnect_xscale_outputs[2] <= div_out;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 17) begin
        pooling_fullyconnect_xscale_outputs[3] <= div_out;
    end
    //2
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 5) begin
        pooling_fullyconnect_xscale_outputs[0] <= div_out;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 7) begin
        pooling_fullyconnect_xscale_outputs[1] <= div_out;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 9) begin
        pooling_fullyconnect_xscale_outputs[2] <= div_out;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 11) begin
        pooling_fullyconnect_xscale_outputs[3] <= div_out;
    end
    //3
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 5) begin
        pooling_fullyconnect_xscale_outputs[0] <= ln_out_1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 7) begin
        pooling_fullyconnect_xscale_outputs[1] <= ln_out_1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 9) begin
        pooling_fullyconnect_xscale_outputs[2] <= ln_out_1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 11) begin
        pooling_fullyconnect_xscale_outputs[3] <= ln_out_1;
    end
    else begin 
        pooling_fullyconnect_xscale_outputs <= pooling_fullyconnect_xscale_outputs;
        compair[1:0] <= compair[1:0];
    end
end


//MAXORMINI
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        max <= 0;
    end
    else if(current_state == MAXORMINI & counter == 1) begin //use old mult
        if(cmp_pick) max <= compair[0];
        else max <= compair[1];
    end
    else if(current_state == MAXORMINI & counter == 3) begin //use old mult
        if(cmp_pick) max <= compair[0];
        else max <= compair[1];
    end
    else if(current_state == MAXORMINI & counter == 5) begin //use old mult
        if(cmp_pick) max <= compair[0];
        else max <= compair[1];
    end
    else begin
        max <= max;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mini <= 0;
    end
    else if(current_state == MAXORMINI & counter == 7) begin //use old mult
        if(!cmp_pick) mini <= compair[0];
        else mini <= compair[1];
    end
    else if(current_state == MAXORMINI & counter == 9) begin //use old mult
        if(!cmp_pick) mini <= compair[0];
        else mini <= compair[1];
    end
    else if(current_state == MAXORMINI & counter == 11) begin //use old mult
        if(!cmp_pick) mini <= compair[0];
        else mini <= compair[1];
    end
    else begin
        mini <= mini;
    end
end



always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fully_normolize <= 0;
        sub_ina <= 0;
        sub_inb <= 0;
    end
    //fully_normolize
    else if(current_state == NORMOLIZATION & counter == 2)
    begin
        sub_ina <= pooling_fullyconnect_xscale_outputs[0];
        sub_inb <= mini;
    end
    else if(current_state == NORMOLIZATION & counter == 3)
    begin
        fully_normolize[0] <= sub_out;
    end
    else if(current_state == NORMOLIZATION & counter == 4)
    begin
        sub_ina <= pooling_fullyconnect_xscale_outputs[1];
        sub_inb <= mini;
    end
    else if(current_state == NORMOLIZATION & counter == 5)
    begin
        fully_normolize[1] <= sub_out;
    end
    else if(current_state == NORMOLIZATION & counter == 6)
    begin
        sub_ina <= pooling_fullyconnect_xscale_outputs[2];
        sub_inb <= mini;
    end
    else if(current_state == NORMOLIZATION & counter == 7)
    begin
        fully_normolize[2] <= sub_out;
    end
    else if(current_state == NORMOLIZATION & counter == 8)
    begin
        sub_ina <= pooling_fullyconnect_xscale_outputs[3];
        sub_inb <= mini;
    end
    else if(current_state == NORMOLIZATION & counter == 9)
    begin
        fully_normolize[3] <= sub_out;
    end
    else if(current_state == NORMOLIZATION & counter == 0)
    begin
        sub_ina <= max;
        sub_inb <= mini;
    end


    //Active Function Case1
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 4) begin
        sub_ina <= exp_1[0];
        sub_inb <= exp_2[0];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 6) begin
        sub_ina <= exp_1[1];
        sub_inb <= exp_2[1];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 8) begin
        sub_ina <= exp_1[2];
        sub_inb <= exp_2[2];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 10) begin
        sub_ina <= exp_1[3];
        sub_inb <= exp_2[3];
    end
    
    else begin
        fully_normolize <= fully_normolize;
        sub_ina <= sub_ina;
        sub_inb <= sub_inb;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        denominator <= 0;
    end
    else if(current_state == NORMOLIZATION & counter == 1)
    begin
        denominator <= sub_out;
    end
    else begin
        denominator <= denominator;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        div_ina <= 0;
        div_inb <= 0;
    end
    else if(current_state == NORMOLIZATION & counter == 10)
    begin
        div_ina <= fully_normolize[0];
        div_inb <= denominator;
    end
    else if(current_state == NORMOLIZATION & counter == 12)
    begin
        div_ina <= fully_normolize[1];
        div_inb <= denominator;
    end
    else if(current_state == NORMOLIZATION & counter == 14)
    begin
        div_ina <= fully_normolize[2];
        div_inb <= denominator;
    end
    else if(current_state == NORMOLIZATION & counter == 16)
    begin
        div_ina <= fully_normolize[3];
        div_inb <= denominator;
    end
   
    //Active Function Case1
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 2) begin
        div_ina <= FLOATING_ONE;
        div_inb <= exp_1[0];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 4) begin
        div_ina <= FLOATING_ONE;
        div_inb <= exp_1[1];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 6) begin
        div_ina <= FLOATING_ONE;
        div_inb <= exp_1[2];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 8) begin
        div_ina <= FLOATING_ONE;
        div_inb <= exp_1[3];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 10) begin
        div_ina <= add_sub_2[0];
        div_inb <= add_sub_1[0];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 12) begin
        div_ina <= add_sub_2[1];
        div_inb <= add_sub_1[1];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 14) begin
        div_ina <= add_sub_2[2];
        div_inb <= add_sub_1[2];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 16) begin
        div_ina <= add_sub_2[3];
        div_inb <= add_sub_1[3];
    end


    //Active Function Case2
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 4) begin
        div_ina <= exp_1[0];
        div_inb <= add_sub_1[0];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 6) begin
        div_ina <= exp_1[1];
        div_inb <= add_sub_1[1];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 8) begin
        div_ina <= exp_1[2];
        div_inb <= add_sub_1[2];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 10) begin
        div_ina <= exp_1[3];
        div_inb <= add_sub_1[3];
    end

    else begin
        div_ina <= div_ina;
        div_inb <= div_inb;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        exp_1 <= 0;
        //pooling_fullyconnect_xscale_outputs <= 0;
        //done <= 0;
    end
    //0
    // else if(current_state == ACTIVEFUNCTION & Opt_catch == 0) begin
    //     //pooling_fullyconnect_xscale_outputs <= pooling_fullyconnect_xscale_outputs;
    //     //done <= 1;
    // end

    //1
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 0) begin
        exp_in_1 <= pooling_fullyconnect_xscale_outputs[0];
        //done <= 1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 1) begin
        exp_1[0] <= exp_out_1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 2) begin
        exp_in_1 <= pooling_fullyconnect_xscale_outputs[1];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 3) begin
        exp_1[1] <= exp_out_1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 4) begin
        exp_in_1 <= pooling_fullyconnect_xscale_outputs[2];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 5) begin
        exp_1[2] <= exp_out_1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 6) begin
        exp_in_1 <= pooling_fullyconnect_xscale_outputs[3];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 7) begin
        exp_1[3] <= exp_out_1;
    end
    //2
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 0) begin
        exp_in_1 <= pooling_fullyconnect_xscale_outputs[0];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 1) begin
        exp_1[0] <= exp_out_1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 2) begin
        exp_in_1 <= pooling_fullyconnect_xscale_outputs[1];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 3) begin
        exp_1[1] <= exp_out_1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 4) begin
        exp_in_1 <= pooling_fullyconnect_xscale_outputs[2];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 5) begin
        exp_1[2] <= exp_out_1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 6) begin
        exp_in_1 <= pooling_fullyconnect_xscale_outputs[3];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 7) begin
        exp_1[3] <= exp_out_1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 0) begin
        exp_in_1 <= pooling_fullyconnect_xscale_outputs[0];
        //done <= 1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 1) begin
        exp_1[0] <= exp_out_1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 2) begin
        exp_in_1 <= pooling_fullyconnect_xscale_outputs[1];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 3) begin
        exp_1[1] <= exp_out_1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 4) begin
        exp_in_1 <= pooling_fullyconnect_xscale_outputs[2];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 5) begin
        exp_1[2] <= exp_out_1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 6) begin
        exp_in_1 <= pooling_fullyconnect_xscale_outputs[3];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 7) begin
        exp_1[3] <= exp_out_1;
    end
    else begin
        exp_1 <= exp_1;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        exp_2 <= 0;
    end
    //1
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 3) begin
        exp_2[0] <= div_out;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 5) begin
        exp_2[1] <= div_out;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 7) begin
        exp_2[2] <= div_out;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 9) begin
        exp_2[3] <= div_out;
    end
    else begin
        exp_2 <= exp_2;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        add_sub_1 <= 0;
    end
    //1
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 5) begin
        add_sub_1[0] <= add_out[3];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 7) begin
        add_sub_1[1] <= add_out[3];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 9) begin
        add_sub_1[2] <= add_out[3];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 11) begin
        add_sub_1[3] <= add_out[3];
    end
    //2
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 3) begin
        add_sub_1[0] <= add_out[3];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 5) begin
        add_sub_1[1] <= add_out[3];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 7) begin
        add_sub_1[2] <= add_out[3];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & counter == 9) begin
        add_sub_1[3] <= add_out[3];
    end
    //3
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 3) begin
        add_sub_1[0] <= add_out[3];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 5) begin
        add_sub_1[1] <= add_out[3];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 7) begin
        add_sub_1[2] <= add_out[3];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 9) begin
        add_sub_1[3] <= add_out[3];
    end
    else begin
        add_sub_1 <= add_sub_1;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        add_sub_2 <= 0;
    end
    //1
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 5) begin
        add_sub_2[0] <= sub_out ;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 7) begin
        add_sub_2[1] <= sub_out ;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 9) begin
        add_sub_2[2] <= sub_out ;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & counter == 11) begin
        add_sub_2[3] <= sub_out ;
    end
    else begin
        add_sub_2 <= add_sub_2;
    end
end




always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ln_in_1 <= 0;
    end
    //3
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 4) begin
        ln_in_1 <= add_sub_1[0];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 6) begin
        ln_in_1 <= add_sub_1[1];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 8) begin
        ln_in_1 <= add_sub_1[2];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & counter == 10) begin
        ln_in_1 <= add_sub_1[3];
    end
    else begin
        ln_in_1 <= ln_in_1;
    end
end






//out valid
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 0 & (counter >= 1 & counter <= 4)) begin
        out_valid <= 1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & (counter >= 15 & counter <= 18)) begin
        out_valid <= 1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & (counter >= 9 & counter <= 12)) begin
        out_valid <= 1;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & (counter >= 9 & counter <= 12)) begin
        out_valid <= 1;
    end
    else begin
        out_valid <= 0;
    end
end

//output
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out <= 0;
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 0 & (counter >= 1 & counter <= 4)) begin
        out <= pooling_fullyconnect_xscale_outputs[counter - 1];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 1 & (counter >= 15 & counter <= 18)) begin
        out <= pooling_fullyconnect_xscale_outputs[counter - 15];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 2 & (counter >= 9 & counter <= 12)) begin
        out <= pooling_fullyconnect_xscale_outputs[counter - 9];
    end
    else if(current_state == ACTIVEFUNCTION & Opt_catch == 3 & (counter >= 9 & counter <= 12)) begin
        out <= pooling_fullyconnect_xscale_outputs[counter - 9];
    end
    else begin
        out <= 0;
    end
end



endmodule
