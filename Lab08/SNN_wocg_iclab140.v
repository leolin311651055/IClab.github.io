module SNN(
	// Input signals
	clk,
	rst_n,
	in_valid,
	img,
	ker,
	weight,
	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
reg [7:0]   img_catch		        [0:1][0:5][0:5]; 
reg [7:0]   kernel_catch	        [0:2][0:2];  
reg [7:0]   weight_catch	        [0:3];  
reg [15:0]  distance	            ; 
reg [19:0]  img_conv_to_quan    	[0:1][0:3][0:3]; 
reg [7:0]   mult_in1		        [0:8];
reg [7:0]   mult_in0		        [0:8];
reg [15:0]  mult_out		        [0:8];
reg [20:0]  div_in1		            ;
reg [20:0]  div_in0		            ;
reg [15:0]  div_out		            ;
reg [17:0]  add_5_in                [0:4];
reg [20:0]  add_5_out               ;
reg [16:0]  add_2_in0	    	    [0:3];
reg [16:0]  add_2_in1	    	    [0:3];
reg [17:0]  add_2_out               [0:3];
reg [15:0]  sub_2_in0	    	    [0:3];
reg [15:0]  sub_2_in1	    	    [0:3];
reg [15:0]  sub_2_out               [0:3];
reg [15:0]  max_to_fully          [0:1][0:3];
reg [9:0]   comp_in0, comp_in1, comp_in2, comp_in3, comp_out;
reg [19:0]  counter, counter2, counter3, counter4, counter5, counter6, counter7, counter8, counter9, counter10, counter11, counter12;
reg [7:0]   current_state,next_state;

parameter SCALE_4x4         = 2295;
parameter SCALE_4x1         = 510;
parameter IDLE              = 0;
parameter LOAD_BOTH         = 1;
parameter LOAD_KER_IMG      = 2;
parameter LOAD_IMG_ONLY     = 3;
parameter CON_TO_FULLY      = 4;
parameter DISTANCE          = 5;
parameter OUTPUT            = 6;
integer i, j, k;



mult mult_0(.mult_in0(mult_in0[0]),.mult_in1(mult_in1[0]),.mult_out(mult_out[0]));
mult mult_1(.mult_in0(mult_in0[1]),.mult_in1(mult_in1[1]),.mult_out(mult_out[1]));
mult mult_2(.mult_in0(mult_in0[2]),.mult_in1(mult_in1[2]),.mult_out(mult_out[2]));
mult mult_3(.mult_in0(mult_in0[3]),.mult_in1(mult_in1[3]),.mult_out(mult_out[3]));
mult mult_4(.mult_in0(mult_in0[4]),.mult_in1(mult_in1[4]),.mult_out(mult_out[4]));
mult mult_5(.mult_in0(mult_in0[5]),.mult_in1(mult_in1[5]),.mult_out(mult_out[5]));
mult mult_6(.mult_in0(mult_in0[6]),.mult_in1(mult_in1[6]),.mult_out(mult_out[6]));
mult mult_7(.mult_in0(mult_in0[7]),.mult_in1(mult_in1[7]),.mult_out(mult_out[7]));
mult mult_8(.mult_in0(mult_in0[8]),.mult_in1(mult_in1[8]),.mult_out(mult_out[8]));

add_2 add_2_0(.add_2_in0(add_2_in0[0]),.add_2_in1(add_2_in1[0]),.add_2_out(add_2_out[0]));
add_2 add_2_1(.add_2_in0(add_2_in0[1]),.add_2_in1(add_2_in1[1]),.add_2_out(add_2_out[1]));
add_2 add_2_2(.add_2_in0(add_2_in0[2]),.add_2_in1(add_2_in1[2]),.add_2_out(add_2_out[2]));
add_2 add_2_3(.add_2_in0(add_2_in0[3]),.add_2_in1(add_2_in1[3]),.add_2_out(add_2_out[3]));

sub_2 sub_2_0(.sub_2_in0(sub_2_in0[0]),.sub_2_in1(sub_2_in1[0]),.sub_2_out(sub_2_out[0]));
sub_2 sub_2_1(.sub_2_in0(sub_2_in0[1]),.sub_2_in1(sub_2_in1[1]),.sub_2_out(sub_2_out[1]));
sub_2 sub_2_2(.sub_2_in0(sub_2_in0[2]),.sub_2_in1(sub_2_in1[2]),.sub_2_out(sub_2_out[2]));
sub_2 sub_2_3(.sub_2_in0(sub_2_in0[3]),.sub_2_in1(sub_2_in1[3]),.sub_2_out(sub_2_out[3]));

add_5 add_5(
    .add_5_in0(add_5_in[0]),
    .add_5_in1(add_5_in[1]),
    .add_5_in2(add_5_in[2]),
    .add_5_in3(add_5_in[3]),
    .add_5_in4(add_5_in[4]),
    .add_5_out(add_5_out)
    );
div div(.div_in0(div_in0),.div_in1(div_in1),.div_out(div_out));

comp comp(.comp_in0(comp_in0),.comp_in1(comp_in1),.comp_in2(comp_in2),.comp_in3(comp_in3),.comp_out(comp_out));

//==============================================//
//                    FSM                       //
//==============================================//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(*) begin
	if(!rst_n) next_state = IDLE;
	else begin
		case(current_state)
			IDLE : begin
				if(in_valid) next_state = LOAD_BOTH;
				else next_state = current_state;
			end
            LOAD_BOTH : begin
				if(counter == 3) next_state = LOAD_KER_IMG ;
				else next_state = current_state;
			end
            LOAD_KER_IMG  : begin 
				if(counter4[1] == 1 && counter5[1] == 1) next_state = LOAD_IMG_ONLY;
				else next_state = current_state;
			end
            LOAD_IMG_ONLY : begin
				if(counter == 5 && counter2 == 5 && counter3 == 1) next_state = CON_TO_FULLY;
				else next_state = current_state;
			end//
			CON_TO_FULLY : begin
				if(counter8 == 1 && counter9 == 28) next_state = DISTANCE ;
				else next_state = current_state;
			end
            DISTANCE : begin
				if(counter12[2] == 1) next_state = OUTPUT ;
				else next_state = current_state;
			end
            OUTPUT : begin
				next_state = IDLE;
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
    //LOAD
    else if(((current_state == IDLE && in_valid) || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG || current_state == LOAD_IMG_ONLY) && counter < 5) begin
        counter <= counter + 1;
    end
	else if(((current_state == IDLE && in_valid) || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG || current_state == LOAD_IMG_ONLY) && counter == 5) begin
        counter <= 0;
    end
    else begin
        counter <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter12 <= 0;
    end
    //DISTANCE
    else if(current_state == DISTANCE && counter12 < 4) begin
        counter12 <= counter12 + 1;
    end
	else if(current_state == DISTANCE && counter12 == 4) begin
        counter12 <= 0;
    end
    else begin
        counter12 <= 0;
    end
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter11 <= 0;
    end
    //CON_TO_FULLY
    else if(current_state == CON_TO_FULLY && counter9 == 28) begin
        counter11 <= 0;
    end
    else if(current_state == CON_TO_FULLY && counter11 < 3) begin
        counter11 <= counter11 + 1;
    end
	else if(current_state == CON_TO_FULLY && counter11 == 3) begin
        counter11 <= 0;
    end
    else begin
        counter11 <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter2 <= 0;
    end
    //LOAD
    else if(((current_state == IDLE && in_valid) || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG || current_state == LOAD_IMG_ONLY) && counter != 5) begin
        counter2 <= counter2;
    end
    else if(((current_state == IDLE && in_valid) || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG || current_state == LOAD_IMG_ONLY) && counter == 5 && counter2 != 5) begin
        counter2 <= counter2 + 1;
    end
    else if(((current_state == IDLE && in_valid) || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG || current_state == LOAD_IMG_ONLY) && counter == 5 && counter2 == 5) begin
        counter2 <= 0;
    end
    else begin
        counter2 <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter10 <= 0;
    end
    //CON_TO_FULLY
    else if(current_state == CON_TO_FULLY && counter9 == 28) begin
        counter10 <= 0;
    end
    else if(current_state == CON_TO_FULLY && counter11 != 3) begin
        counter10 <= counter10;
    end
    else if(current_state == CON_TO_FULLY && counter11 == 3 && counter10 != 3) begin
        counter10 <= counter10 + 1;
    end
    else if(current_state == CON_TO_FULLY && counter11 == 3 && counter10 == 3) begin
        counter10 <= 0;
    end
    else begin
        counter10 <= 0;
    end
end



always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter3 <= 0;
    end
    //LOAD
    else if(((current_state == IDLE && in_valid) || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG || current_state == LOAD_IMG_ONLY) && (counter == 5 && counter2 == 5 && counter3 == 1)) begin
        counter3 <= 0;
    end
    else if(((current_state == IDLE && in_valid) || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG || current_state == LOAD_IMG_ONLY) && (counter != 5 || counter2 != 5)) begin
        counter3 <= counter3;
    end
    else if(((current_state == IDLE && in_valid) || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG || current_state == LOAD_IMG_ONLY) && counter == 5 && counter2 == 5) begin
        counter3 <= counter3 + 1;
    end
    else begin
        counter3 <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter9 <= 0;
    end
    //CON_TO_FULLY
    else if(current_state == CON_TO_FULLY && counter9 < 28) begin
        counter9 <= counter9 + 1;
    end
	else if(current_state == CON_TO_FULLY && counter9 == 28) begin
        counter9 <= 0;
    end
    else begin
        counter9 <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter4 <= 0;
    end
    //LOAD
    else if((next_state == LOAD_BOTH || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG) && counter4 < 2) begin
        counter4 <= counter4 + 1;
    end
	else if((next_state == LOAD_BOTH || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG) && counter4[1] == 1 && counter5[1] == 1) begin
        counter4 <= 0;
    end
    else begin
        counter4 <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter8 <= 0;
    end
    //CON_TO_FULLY
    else if(current_state == CON_TO_FULLY && counter9 != 28) begin
        counter8 <= counter8;
    end
    else if(current_state == CON_TO_FULLY && counter8 == 0 && counter9 == 28) begin
        counter8 <= counter8 + 1;
    end
	else if(current_state == CON_TO_FULLY && counter8 == 1 && counter9 == 28) begin
        counter8 <= 0;
    end
    else begin
        counter8 <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter5 <= 0;
    end
    //LOAD
    else if((next_state == LOAD_BOTH || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG) && counter4 != 2) begin
        counter5 <= counter5;
    end
    else if((next_state == LOAD_BOTH || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG) && counter4[1] == 1 && counter5 != 3) begin
        counter5 <= counter5 + 1;
    end
    else if((next_state == LOAD_BOTH || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG) && (counter == 5 && counter2 == 5 && counter3 == 2)) begin
        counter5 <= counter5;
    end
    else begin
        counter5 <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter7 <= 0;
    end
    //CON_TO_FULLY
    else if(current_state == CON_TO_FULLY && counter7 < 3 && counter9 >= 4) begin
        counter7 <= counter7 + 1;
    end
	else if(current_state == CON_TO_FULLY && counter7 == 3 && counter9 >= 4) begin
        counter7 <= 0;
    end
    else begin
        counter7 <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter6 <= 0;
    end
    //CON_TO_FULLY
    else if(current_state == CON_TO_FULLY && counter7 != 3 && counter9 >= 3) begin
        counter6 <= counter6;
    end
    else if(current_state == CON_TO_FULLY && counter7 == 3 && counter6 != 3 && counter9 >= 4) begin
        counter6 <= counter6 + 1;
    end
    else if(current_state == CON_TO_FULLY && counter7 == 3 && counter6 == 3 && counter9 >= 4) begin
        counter6 <= 0;
    end
    else begin
        counter6 <= 0;
    end
end


//==============================================//
//                  Input                       //
//==============================================//
//Image
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0 ; i < 2 ; i++) begin
			for(j = 0 ; j < 6 ; j++) begin
                for(k = 0 ; k < 6 ; k++) begin
				    img_catch[i][j][k] <= 0; 
                end
		    end
        end
    end
    else if(((current_state == IDLE && in_valid) || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG || current_state == LOAD_IMG_ONLY)) begin
        img_catch[counter3][counter2][counter] <= img;
    end
    else begin
        img_catch <= img_catch; 
    end
end

//Kernel
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0 ; i < 3 ; i++) begin
            for(j = 0 ; j < 3 ; j++) begin
			    kernel_catch[i][j] <= 0; 
            end
		end
    end
    else if(next_state == LOAD_BOTH || current_state == LOAD_BOTH || current_state == LOAD_KER_IMG) begin
        kernel_catch[counter5][counter4] <= ker;
    end
    else begin
        kernel_catch <= kernel_catch; 
    end
end

//Weight
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0 ; i < 4 ; i++) begin
			weight_catch[i] <= 0; 
		end
    end
    else if(next_state == LOAD_BOTH || current_state == LOAD_BOTH) begin
        weight_catch[counter] <= weight;
    end
    else begin
        weight_catch <= weight_catch; 
    end
end

//==============================================//
//                  Distance                    //
//==============================================//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		distance <= 0; 
    end
    else if(current_state == DISTANCE && counter12 == 2) begin
        distance <= add_5_out;
    end
    else if(current_state == DISTANCE && counter12 == 3) begin
        if(distance < 16) distance <= 0;
        else distance <= distance;
    end
    else begin
        distance <= distance; 
    end
end


//==============================================//
//        Max Pooling and Fully Connect         //
//==============================================//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0 ; i < 2 ; i++) begin
			for(j = 0 ; j < 2 ; j++) begin
                for(k = 0 ; k < 2 ; k++) begin
				    max_to_fully[i][j][k] <= 0; 
                end
		    end
        end
    end
    //Max-Pooling 
    else if(current_state == CON_TO_FULLY && counter9 == 11) begin
        max_to_fully[counter8][0] <= comp_out;
    end
    else if(current_state == CON_TO_FULLY && counter9 == 16) begin
        max_to_fully[counter8][1] <= comp_out;
    end
    else if(current_state == CON_TO_FULLY && counter9 == 19) begin
        max_to_fully[counter8][2] <= comp_out;
    end
    else if(current_state == CON_TO_FULLY && counter9 == 21) begin
        max_to_fully[counter8][3] <= comp_out;
    end
    else if(current_state == CON_TO_FULLY && counter9 == 25) begin
        max_to_fully[counter8][0] <= div_out;
    end
    else if(current_state == CON_TO_FULLY && counter9 == 26) begin
        max_to_fully[counter8][1] <= div_out;
    end
    else if(current_state == CON_TO_FULLY && counter9 == 27) begin
        max_to_fully[counter8][2] <= div_out;
    end
    
    else if(current_state == CON_TO_FULLY && counter9 == 28) begin
        max_to_fully[counter8][3] <= div_out;
    end
    else begin
        max_to_fully<= max_to_fully;
    end
end

//==============================================//
//                  compare                     //
//==============================================//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        comp_in0 <= 0;
    end
    //Max-Pooling 
    else if(current_state == CON_TO_FULLY && counter9 == 10) begin
        comp_in0 <= img_conv_to_quan[counter8][0][0];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 15) begin
        comp_in0 <= img_conv_to_quan[counter8][0][2];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 18) begin
        comp_in0 <= img_conv_to_quan[counter8][2][0];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 20) begin
        comp_in0 <= img_conv_to_quan[counter8][2][2];
    end
    else begin
        comp_in0 <= comp_in0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        comp_in1 <= 0;
    end
    //Max-Pooling 
    else if(current_state == CON_TO_FULLY && counter9 == 10) begin
        comp_in1 <= img_conv_to_quan[counter8][0][1];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 15) begin
        comp_in1 <= img_conv_to_quan[counter8][0][3];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 18) begin
        comp_in1 <= img_conv_to_quan[counter8][2][1];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 20) begin
        comp_in1 <= img_conv_to_quan[counter8][2][3];
    end
    else begin
        comp_in1 <= comp_in1;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        comp_in2 <= 0;
    end
    //Max-Pooling 
    else if(current_state == CON_TO_FULLY && counter9 == 10) begin
        comp_in2 <= img_conv_to_quan[counter8][1][0];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 15) begin
        comp_in2 <= img_conv_to_quan[counter8][1][2];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 18) begin
        comp_in2 <= img_conv_to_quan[counter8][3][0];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 20) begin
        comp_in2 <= img_conv_to_quan[counter8][3][2];
    end
    else begin
        comp_in2 <= comp_in2;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        comp_in3 <= 0;
    end
    //Max-Pooling 
    else if(current_state == CON_TO_FULLY && counter9 == 10) begin
        comp_in3 <= img_conv_to_quan[counter8][1][1];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 15) begin
        comp_in3 <= img_conv_to_quan[counter8][1][3];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 18) begin
        comp_in3 <= img_conv_to_quan[counter8][3][1];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 20) begin
        comp_in3 <= img_conv_to_quan[counter8][3][3];
    end
    else begin
        comp_in3 <= comp_in3;
    end
end

//==============================================//
//                    sub                       //
//==============================================//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0 ; i < 4 ; i++) begin
            sub_2_in0[i] <= 0;
		end
    end
	//convolution
    else if(current_state == DISTANCE && counter12 == 0) begin
        if(max_to_fully[0][0] > max_to_fully[1][0]) sub_2_in0[0] <= max_to_fully[0][0];
        else sub_2_in0[0] <= max_to_fully[1][0];
        if(max_to_fully[0][1] > max_to_fully[1][1]) sub_2_in0[1] <= max_to_fully[0][1];
        else sub_2_in0[1] <= max_to_fully[1][1];
        if(max_to_fully[0][2] > max_to_fully[1][2]) sub_2_in0[2] <= max_to_fully[0][2];
        else sub_2_in0[2] <= max_to_fully[1][2];
        if(max_to_fully[0][3] > max_to_fully[1][3]) sub_2_in0[3] <= max_to_fully[0][3];
        else sub_2_in0[3] <= max_to_fully[1][3];
    end
	else begin
        sub_2_in0 <= sub_2_in0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0 ; i < 4 ; i++) begin
            sub_2_in1[i] <= 0;
		end
    end
	//convolution
    else if(current_state == DISTANCE && counter12 == 0) begin
        if(max_to_fully[0][0] > max_to_fully[1][0]) sub_2_in1[0] <= max_to_fully[1][0];
        else sub_2_in1[0] <= max_to_fully[0][0];
        if(max_to_fully[0][1] > max_to_fully[1][1]) sub_2_in1[1] <= max_to_fully[1][1];
        else sub_2_in1[1] <= max_to_fully[0][1];
        if(max_to_fully[0][2] > max_to_fully[1][2]) sub_2_in1[2] <= max_to_fully[1][2];
        else sub_2_in1[2] <= max_to_fully[0][2];
        if(max_to_fully[0][3] > max_to_fully[1][3]) sub_2_in1[3] <= max_to_fully[1][3];
        else sub_2_in1[3] <= max_to_fully[0][3];
    end
	else begin
        sub_2_in1 <= sub_2_in1;
    end
end

//==============================================//
//                    add                       //
//==============================================//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0 ; i < 4 ; i++) begin
            add_2_in0[i] <= 0;
		end
    end
	//convolution
    else if(current_state == CON_TO_FULLY && counter9 >= 1 && counter9 <= 16) begin
        add_2_in0[0] <= mult_out[0];
        add_2_in0[1] <= mult_out[1];
        add_2_in0[2] <= mult_out[2];
        add_2_in0[3] <= mult_out[3];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 23) begin
        add_2_in0[0] <= mult_out[0];
        add_2_in0[1] <= mult_out[2];
        add_2_in0[2] <= mult_out[4];
        add_2_in0[3] <= mult_out[6];
    end
	else begin
        add_2_in0 <= add_2_in0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0 ; i < 4 ; i++) begin
            add_2_in1[i] <= 0;
		end
    end
	//convolution
    else if(current_state == CON_TO_FULLY && counter9 >= 1 && counter9 <= 16) begin
        add_2_in1[0] <= mult_out[4];
        add_2_in1[1] <= mult_out[5];
        add_2_in1[2] <= mult_out[6];
        add_2_in1[3] <= mult_out[7];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 23) begin
        add_2_in1[0] <= mult_out[1];
        add_2_in1[1] <= mult_out[3];
        add_2_in1[2] <= mult_out[5];
        add_2_in1[3] <= mult_out[7];
    end
	else begin
        add_2_in1 <= add_2_in1;
    end
end

reg [15:0] mult_out8 ; //span mult_out[8] to next stage adder
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mult_out8 <= 0;
    end
	//convolution
    else if(current_state == CON_TO_FULLY) begin
        mult_out8 <= mult_out[8] ;
    end
	else begin
        mult_out8 <= mult_out8;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0 ; i < 4 ; i++) begin
            add_5_in[i] <= 0;
		end
    end
	//convolution
    else if(current_state == CON_TO_FULLY && counter9 >= 2 && counter9 <= 17) begin
        add_5_in[0] <= add_2_out[0];
        add_5_in[1] <= add_2_out[1];
        add_5_in[2] <= add_2_out[2];
        add_5_in[3] <= add_2_out[3];
        add_5_in[4] <= mult_out8 ;
    end
    else if(current_state == DISTANCE && counter12 == 1) begin
        add_5_in[0] <= sub_2_out[0];
        add_5_in[1] <= sub_2_out[1];
        add_5_in[2] <= sub_2_out[2];
        add_5_in[3] <= sub_2_out[3];
        add_5_in[4] <= 0 ;
    end
	else begin
        add_5_in <= add_5_in;
    end
end



//==============================================//
//                   mult                       //
//==============================================//
wire [19:0]  counter10_t1, counter11_t1;
wire [19:0]  counter10_t2, counter11_t2;
assign counter10_t1 = counter10 + 1;
assign counter10_t2 = counter10 + 2;
assign counter11_t1 = counter11 + 1;
assign counter11_t2 = counter11 + 2;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0 ; i < 9; i++) begin
             mult_in0[i] <= 0;
		end
    end
	//convolution
    else if(current_state == CON_TO_FULLY && counter9 < 22) begin
        mult_in0[0] <= img_catch[counter8][counter10][counter11];
        mult_in0[1] <= img_catch[counter8][counter10][counter11_t1];
        mult_in0[2] <= img_catch[counter8][counter10][counter11_t2];
        mult_in0[3] <= img_catch[counter8][counter10_t1][counter11];
        mult_in0[4] <= img_catch[counter8][counter10_t1][counter11_t1];
        mult_in0[5] <= img_catch[counter8][counter10_t1][counter11_t2];
        mult_in0[6] <= img_catch[counter8][counter10_t2][counter11];
        mult_in0[7] <= img_catch[counter8][counter10_t2][counter11_t1];
        mult_in0[8] <= img_catch[counter8][counter10_t2][counter11_t2];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 22) begin
        mult_in0[0] <= max_to_fully[counter8][0];
        mult_in0[1] <= max_to_fully[counter8][1];
        mult_in0[2] <= max_to_fully[counter8][0];
        mult_in0[3] <= max_to_fully[counter8][1];
        mult_in0[4] <= max_to_fully[counter8][2];
        mult_in0[5] <= max_to_fully[counter8][3];
        mult_in0[6] <= max_to_fully[counter8][2];
        mult_in0[7] <= max_to_fully[counter8][3];
    end
    else begin
        mult_in0 <= mult_in0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0 ; i < 9; i++) begin
             mult_in1[i] <= 0;
		end
    end
	//convolution
    else if(current_state == CON_TO_FULLY && counter9 < 22) begin
        mult_in1[0] <= kernel_catch[0][0];
        mult_in1[1] <= kernel_catch[0][1];
        mult_in1[2] <= kernel_catch[0][2];
        mult_in1[3] <= kernel_catch[1][0];
        mult_in1[4] <= kernel_catch[1][1];
        mult_in1[5] <= kernel_catch[1][2];
        mult_in1[6] <= kernel_catch[2][0];
        mult_in1[7] <= kernel_catch[2][1];
        mult_in1[8] <= kernel_catch[2][2];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 22) begin
        mult_in1[0] <= weight_catch[0];
        mult_in1[1] <= weight_catch[2];
        mult_in1[2] <= weight_catch[1];
        mult_in1[3] <= weight_catch[3];
        mult_in1[4] <= weight_catch[0];
        mult_in1[5] <= weight_catch[2];
        mult_in1[6] <= weight_catch[1];
        mult_in1[7] <= weight_catch[3];
    end
    else begin
        mult_in1 <= mult_in1;
    end
end


//==============================================//
//                   div                       //
//==============================================//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        div_in0 <= 0;
    end
	//convolution
    else if(current_state == CON_TO_FULLY && counter9 >= 3 && counter9 <24) begin
        div_in0 <= add_5_out;
    end
    else if(current_state == CON_TO_FULLY && counter9 == 24) begin
        div_in0 <= add_2_out[0];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 25) begin
        div_in0 <= add_2_out[1];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 26) begin
        div_in0 <= add_2_out[2];
    end
    else if(current_state == CON_TO_FULLY && counter9 == 27) begin
        div_in0 <= add_2_out[3];
    end
    else begin
        div_in0 <= div_in0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        div_in1 <= 0;
    end
	//convolution
    else if(current_state == CON_TO_FULLY && counter9 >= 3 && counter9 <24) begin
        div_in1 <= SCALE_4x4;
    end
    else if(current_state == CON_TO_FULLY && counter9 >= 24 && counter9 <=27) begin
        div_in1 <= SCALE_4x1;
    end
    else begin
        div_in1 <= div_in1;
    end
end




//==============================================//
//                 Convolution                  //
//==============================================//
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0 ; i < 2 ; i++) begin
			for(j = 0 ; j < 4 ; j++) begin
                for(k = 0 ; k < 4 ; k++) begin
				    img_conv_to_quan[i][j][k] <= 0; 
                end
		    end
        end
    end
	//convolution
    else if(current_state == CON_TO_FULLY && counter9 >= 4 && counter9 <= 19) begin
        img_conv_to_quan[counter8][counter6][counter7] <= div_out;
    end
    else begin
        img_conv_to_quan <= img_conv_to_quan;
    end
end


//==============================================//
//                 output                       //
//==============================================//

//out valid
always@(posedge clk or negedge rst_n) begin
// always@(posedge CLOCK_GATED_in_out or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else if(next_state == OUTPUT) out_valid <= 1;
    else begin
        out_valid <= 0;
    end
end

//output
always@(*) begin
    if(!rst_n) begin
        out_data = 0;
    end
    else if(out_valid) begin
        out_data = distance;
    end
    else begin
        out_data = 0;
    end
end

endmodule

module mult (
	input  [7:0]  mult_in0, 
	input  [7:0]  mult_in1,
	output [15:0] mult_out
	) ;
 
 assign mult_out = mult_in0 * mult_in1 ;
 
endmodule

module div (
	input  [20:0] div_in0, 
	input  [20:0] div_in1,
	output [15:0] div_out
	) ;
 
 assign div_out = div_in0 / div_in1 ;
 
endmodule


module add_2 (
	input [16:0] add_2_in0,
	input [16:0] add_2_in1,
	output[17:0] add_2_out
	) ;
 
 assign add_2_out = add_2_in0 + add_2_in1 ;
 
endmodule

module sub_2 (
	input [15:0] sub_2_in0,
	input [15:0] sub_2_in1,
	output[15:0] sub_2_out
	) ;
 
 assign sub_2_out = sub_2_in0 - sub_2_in1 ;
 
endmodule

module add_5 (
	input [17:0] add_5_in0,
	input [17:0] add_5_in1,
    input [17:0] add_5_in2,
    input [17:0] add_5_in3,
    input [17:0] add_5_in4,
	output[20:0] add_5_out
	) ;
 
 assign add_5_out = add_5_in0 + add_5_in1 + add_5_in2 + add_5_in3 + add_5_in4 ;
 
endmodule

module comp (
    input  [9:0] comp_in0, 
    input  [9:0] comp_in1, 
    input  [9:0] comp_in2, 
    input  [9:0] comp_in3, 
	output [9:0] comp_out
	) ;
 
    assign comp_out = (comp_in0 >= comp_in1 && comp_in0 >= comp_in2 && comp_in0 >= comp_in3) ? comp_in0 :
                    (comp_in1 >= comp_in0 && comp_in1 >= comp_in2 && comp_in1 >= comp_in3) ? comp_in1 :
                    (comp_in2 >= comp_in1 && comp_in2 >= comp_in0 && comp_in2 >= comp_in3) ? comp_in2 :
                    comp_in3;

 
endmodule
