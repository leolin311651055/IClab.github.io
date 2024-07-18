module CAD(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    mode,
    matrix_size,
    matrix,
    matrix_idx,
    // output signals
    out_valid,
    out_value
    );

input [1:0] matrix_size;
input clk;
input [7:0] matrix;
input rst_n;
input [3:0] matrix_idx;
input in_valid2;

input mode;
input in_valid;
output reg out_valid;
output reg out_value;


//=======================================================
//                   Reg/Wire
//=======================================================
parameter IDLE           = 0;
parameter LOADIMG        = 1;
parameter LOADKERNEL     = 2;
parameter INPUT          = 3;
parameter INPUT_CON      = 4;
parameter INPUT_DECON    = 5;
parameter CONVOLUTION    = 6;
parameter MAX_POOLING    = 7;
parameter DECONVOLUTION  = 8;
parameter OUTPUTSETTING  = 9;
parameter OUTPUTLOAD_1   = 10;
parameter OUTPUTLOAD_2   = 11;
parameter OUTPUT         = 12;
reg        [8:0]   current_state;
reg        [8:0]   next_state;
reg        [15:0]  counter;
reg        [5:0]   counter2;
reg        [15:0]  counter3;
reg        [5:0]   counter4;
reg        [5:0]   counter5;
reg        [8:0]   counter6;
reg        [8:0]   counter7;
reg        [8:0]   counter8;
reg        [8:0]   counter9;
wire       [15:0]  counter3_t1;
reg        [13:0]  Addr_Img;
reg        [8:0]   Addr_Kernel;
reg        [11:0]  Addr_matrix;
reg signed [7:0]   DI_Kernel;
reg signed [7:0]   DO_Kernel;
reg signed [7:0]   DI_Img;
reg signed [7:0]   DO_Img;
reg signed [19:0]  DI_matrix;
reg signed [19:0]  DO_matrix;
reg                WEN_Img;
reg                WEN_Kernel;
reg                WEN_matrix;
reg        [1:0]   matrix_size_span;
reg                mode_span;
reg signed [7:0]   Img                  [0:39][0:39];
reg        [7:0]   Kernel               [0:4][0:4];
reg signed [19:0]  mp_data0             [0:39];
reg signed [19:0]  mp_data1             [0:1];
reg        [3:0]   Index_Img;
reg signed [3:0]   Index_Kernel;
integer            i, j;


assign counter3_t1 = counter3 - 3; 
//####################################################
//                      ALU
//####################################################
reg signed [7:0]  mult2_in0, mult2_in1 ;
reg signed [17:0] mult2_out, add2_in0, add2_in1 ;
reg signed [19:0] add2_out ;

reg signed [19:0] CONV_REG ;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) CONV_REG <= 0 ;
    else if(current_state == CONVOLUTION || current_state == DECONVOLUTION) CONV_REG <= add2_out ;
    else CONV_REG <= CONV_REG ;
end


Mult2 Mult2 (
    .mult2_in0(mult2_in0), 
    .mult2_in1(mult2_in1), 
    .mult2_out(mult2_out)
    ) ;

Add2 Add2 (
    .add2_in0(add2_in0), 
    .add2_in1(add2_in1), 
    .add2_out(add2_out)
    ) ;

always @ (*) begin
	if(!rst_n) begin
	    mult2_in0 = 0;
        mult2_in1 = 0;
	end 
    else if((current_state == CONVOLUTION || current_state == DECONVOLUTION)) begin
	    mult2_in0 = Img[counter2 + counter4][counter + counter5] ;
        mult2_in1 = Kernel[counter4][counter5] ;
	end 
	else begin 
	    mult2_in0 = 0 ;
        mult2_in1 = 0 ;
	end
end

always @ (*) begin
	if(!rst_n) begin
		add2_in0 = 0 ;
        add2_in1 = 0 ;
	end 
    else if((current_state == CONVOLUTION || current_state == DECONVOLUTION) && counter4 == 0 && counter5 == 0) begin
	    add2_in0 = mult2_out ;
        add2_in1 = 0 ;
	end 
    // else if((current_state == DECONVOLUTION)) begin
	//     add2_in0 = mult2_out ;
    //     add2_in1 = Img[counter2][counter] ;
	// end 
    else if((current_state == CONVOLUTION || current_state == DECONVOLUTION)) begin
	    add2_in0 = mult2_out ;
        add2_in1 = CONV_REG ;
	end 
	else begin 
	    add2_in0 = 0 ;
        add2_in1 = 0 ;
	end
end

//=======================================================
//                     FSM
//=======================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(*) begin
	if(!rst_n) next_state = IDLE;
	else begin
		case(current_state)
			IDLE : begin
				if(in_valid) next_state = LOADIMG;
                else if(in_valid2) next_state = INPUT;
				else next_state = current_state;
			end
            LOADIMG : begin
				if(((matrix_size_span == 0 & counter == (1023)) 
                || (matrix_size_span == 1 & counter == (4095)) 
                || (matrix_size_span == 2 & counter == (16383)))) 
                    next_state = LOADKERNEL;
				else next_state = current_state;
			end
            LOADKERNEL : begin
				if(counter == 400) next_state = IDLE;
				else next_state = current_state;
			end
            INPUT : begin
				if(mode_span == 0) next_state = INPUT_CON;
                else if(mode_span == 1) next_state = INPUT_DECON;
				else next_state = current_state;
			end
            INPUT_CON : begin
				if(((counter3 == 68 & matrix_size_span == 0) || (counter3 == 260 & matrix_size_span == 1) || (counter3 == 1028 & matrix_size_span == 2))) 
                    next_state = CONVOLUTION;
				else next_state = current_state;
			end
            INPUT_DECON : begin
                if(((matrix_size_span == 0 && counter == 15 && counter2 == 15) 
                || ( matrix_size_span == 1 && counter == 23 && counter2 == 23) 
                || ( matrix_size_span == 2 && counter == 39 && counter2 == 39))) next_state = DECONVOLUTION;
				else next_state = current_state;
			end
            CONVOLUTION : begin
				if(((matrix_size_span == 0 && counter == 3 && counter2 ==  3) 
                || (matrix_size_span == 1 && counter == 11 && counter2 == 11) 
                || (matrix_size_span == 2 && counter == 27 && counter2 == 27)) 
                && counter4 == 4 && counter5 == 4) next_state = MAX_POOLING;
				else next_state = current_state;
			end
            MAX_POOLING : begin
				next_state = OUTPUTSETTING;
			end
            DECONVOLUTION : begin
				if(((matrix_size_span == 0 && counter == 11 && counter2 == 11 && counter4 == 4 && counter5 == 4) 
                || ( matrix_size_span == 1 && counter == 19 && counter2 == 19 && counter4 == 4 && counter5 == 4) 
                || ( matrix_size_span == 2 && counter == 35 && counter2 == 35 && counter4 == 4 && counter5 == 4))) next_state = OUTPUTSETTING;
				else next_state = current_state;
			end
            OUTPUTSETTING : begin
				next_state = OUTPUTLOAD_1;
			end
            OUTPUTLOAD_1 : begin
				next_state = OUTPUTLOAD_2;
			end
            OUTPUTLOAD_2 : begin
				next_state = OUTPUT;
			end
            OUTPUT : begin
				if(mode_span == 0 && counter4 == 19 && matrix_size_span == 0 && counter2 ==  2) next_state = IDLE ;
                else if(mode_span == 0 && counter4 == 19 && matrix_size_span == 1 && counter2 ==  6) next_state = IDLE ;
                else if(mode_span == 0 && counter4 == 19 && matrix_size_span == 2 && counter2 == 14) next_state = IDLE ;
                else if(matrix_size_span == 0 && (counter2 == 12) && mode_span == 1 && counter4 == 19) next_state = IDLE ;
                else if(matrix_size_span == 1 && (counter2 == 20) && mode_span == 1 && counter4 == 19) next_state = IDLE ;
                else if(matrix_size_span == 2 && (counter2 == 36) && mode_span == 1 && counter4 == 19) next_state = IDLE ;
                else next_state = current_state;
			end
			default : next_state = current_state;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter <= 0;
    //img_ input sram
    else if((in_valid || current_state == LOADIMG) && 
    ((matrix_size_span == 0 && counter < (1023)) //64*16 - 1 = 1023
    || (matrix_size_span == 1 && counter < (4095)) //256*16 - 1 = 4095
    || (matrix_size_span == 2 && counter < (16383)))) //1024*16 - 1 = 16383
        counter <= counter + 1;
    else if((in_valid || current_state == LOADIMG) &&
    ((matrix_size_span == 0 && counter == (1023)) 
    || (matrix_size_span == 1 && counter == (4095)) 
    || (matrix_size_span == 2 && counter == (16383))))
        counter <= 0;
    //ker_innel input sram
    else if(current_state == LOADKERNEL & counter <= 398) counter <= counter + 1;
    else if(current_state == LOADKERNEL & counter == 399) counter <= 0;
    //take img from sram
    else if((in_valid2 || current_state == INPUT_CON) && (counter3 > 4)
    && ((counter < 7 && matrix_size_span == 0) 
    || (counter < 15 && matrix_size_span == 1) 
    || (counter < 31 && matrix_size_span == 2))) counter <= counter + 1;
    else if(current_state == INPUT_CON && (counter3 > 4)
    && ((counter == 7 && matrix_size_span == 0) 
    || (counter == 15 && matrix_size_span == 1) 
    || (counter == 31 && matrix_size_span == 2))) counter <= 0;

    //convolution
    else if((current_state == CONVOLUTION) && (!(counter4 == 4 && counter5 == 4)))
        counter <= counter;
    else if((current_state == CONVOLUTION) && (counter4 == 4 && counter5 == 4)
    && ((matrix_size_span == 0 && counter == 3) 
    || (matrix_size_span == 1 && counter == 11) 
    || (matrix_size_span == 2 && counter == 27))) counter <= 0;
    else if((current_state == CONVOLUTION) && (counter4 == 4 && counter5 == 4)
    && ((matrix_size_span == 0 && counter < 3)
    || (matrix_size_span == 1 && counter < 11) 
    || (matrix_size_span == 2 && counter < 27))) counter <= counter + 1;

    
    //deconvolution input
    else if(current_state == INPUT_DECON
    && ((matrix_size_span == 0 && counter == 15) 
    || ( matrix_size_span == 1 && counter == 23) 
    || ( matrix_size_span == 2 && counter == 39))) counter <= 0;
    else if(current_state == INPUT_DECON
    && ((matrix_size_span == 0 && counter < 15)
    || ( matrix_size_span == 1 && counter < 23) 
    || ( matrix_size_span == 2 && counter < 39))) counter <= counter + 1;

     //deconvolution
    else if(current_state == DECONVOLUTION && (!(counter4 == 4 && counter5 == 4))) 
        counter <= counter;
    else if(current_state == DECONVOLUTION && (counter4 == 4 && counter5 == 4)
    && ((matrix_size_span == 0 && counter == 11) 
    || (matrix_size_span == 1 && counter == 19) 
    || (matrix_size_span == 2 && counter == 35))) counter <= 0;
    else if(current_state == DECONVOLUTION && (counter4 == 4 && counter5 == 4)
    && ((matrix_size_span == 0 && counter < 11)
    || (matrix_size_span == 1 && counter < 19) 
    || (matrix_size_span == 2 && counter < 35))) counter <= counter + 1;

    //output
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && !(counter3 == 19)) counter <= counter ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 0 && counter <  1) counter <= counter + 1;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 1 && counter <  5) counter <= counter + 1;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 2 && counter < 13) counter <= counter + 1;

    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 0 && counter ==  1) counter <= 0 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 1 && counter ==  5) counter <= 0 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 2 && counter == 13) counter <= 0 ;
    
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && !(counter3 == 19)) counter <= counter ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 0 && counter < 11) counter <= counter + 1;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 1 && counter < 19) counter <= counter + 1;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 2 && counter < 35) counter <= counter + 1;

    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 0 && counter == 11) counter <= 0 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 1 && counter == 19) counter <= 0 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 2 && counter == 35) counter <= 0 ;

    else counter <= 0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter2 <= 0;
    end
    //take img from sram
    else if(current_state == INPUT_CON 
    && ((counter != 7 && matrix_size_span == 0) 
    || (counter != 15 && matrix_size_span == 1) 
    || (counter != 31 && matrix_size_span == 2)))
        counter2 <= counter2;
    else if(current_state == INPUT_CON 
    && ((counter == 7 && counter2 ==  7 && matrix_size_span == 0) 
    || (counter == 15 && counter2 == 15 && matrix_size_span == 1) 
    || (counter == 31 && counter2 == 31 && matrix_size_span == 2)))
        counter2 <= 0;
    else if(current_state == INPUT_CON 
    && ((counter == 7 && counter2 < 8 && matrix_size_span == 0) 
    || (counter == 15 && counter2 < 16 && matrix_size_span == 1) 
    || (counter == 31 && counter2 < 32 && matrix_size_span == 2)))
        counter2 <= counter2 + 1;

    //convolution
    else if((current_state == CONVOLUTION) && (!(counter4 == 4 && counter5 == 4)))
        counter2 <= counter2;
    else if((current_state == CONVOLUTION) && ((counter4 == 4 && counter5 == 4))
    && ((counter <  3 && matrix_size_span == 0) 
    || (counter  < 11 && matrix_size_span == 1) 
    || (counter  < 27 && matrix_size_span == 2)))
        counter2 <= counter2;
    else if((current_state == CONVOLUTION) && (counter4 == 4 && counter5 == 4)
    && ((counter ==  3 && counter2 <  3 && matrix_size_span == 0) 
    || (counter  == 11 && counter2 < 11 && matrix_size_span == 1) 
    || (counter  == 27 && counter2 < 27 && matrix_size_span == 2)))
        counter2 <= counter2 + 1;
    else if((current_state == CONVOLUTION) && (counter4 == 4 && counter5 == 4)
    && ((counter == 3 && counter2 ==  3 && matrix_size_span == 0) 
    || (counter == 11 && counter2 == 11 && matrix_size_span == 1) 
    || (counter == 27 && counter2 == 27 && matrix_size_span == 2)))
        counter2 <= 0;

    //deconvolution input
    else if(current_state == INPUT_DECON
    && ((matrix_size_span == 0 && counter < 15) 
    || ( matrix_size_span == 1 && counter < 23) 
    || ( matrix_size_span == 2 && counter < 39))) counter2 <= counter2;
    else if(current_state == INPUT_DECON
    && ((matrix_size_span == 0 && counter == 15 && counter2 < 15)
    || ( matrix_size_span == 1 && counter == 23 && counter2 < 23) 
    || ( matrix_size_span == 2 && counter == 39 && counter2 < 39))) counter2 <= counter2 + 1;
    else if(current_state == INPUT_DECON
    && ((matrix_size_span == 0 && counter == 15 && counter2 == 15)
    || ( matrix_size_span == 1 && counter == 23 && counter2 == 23) 
    || ( matrix_size_span == 2 && counter == 39 && counter2 == 39))) counter2 <= 0;

    //deconvolution
    else if(current_state == DECONVOLUTION && (!(counter4 == 4 && counter5 == 4)))
        counter2 <= counter2;
    else if(current_state == DECONVOLUTION && ((counter4 == 4 && counter5 == 4))
    && ((counter < 11 && matrix_size_span == 0) 
    || (counter  < 19 && matrix_size_span == 1) 
    || (counter  < 35 && matrix_size_span == 2)))
        counter2 <= counter2;
    else if(current_state == DECONVOLUTION && (counter4 == 4 && counter5 == 4)
    && ((counter == 11 && counter2 < 11 && matrix_size_span == 0) 
    || (counter  == 19 && counter2 < 19 && matrix_size_span == 1) 
    || (counter  == 35 && counter2 < 35 && matrix_size_span == 2)))
        counter2 <= counter2 + 1;
    else if(current_state == DECONVOLUTION && (counter4 == 4 && counter5 == 4)
    && ((counter == 11 && counter2 == 11 && matrix_size_span == 0) 
    || ( counter == 19 && counter2 == 19 && matrix_size_span == 1) 
    || ( counter == 35 && counter2 == 35 && matrix_size_span == 2)))
        counter2 <= 0;

    //output
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && !(counter3 == 19)) counter2 <= counter2 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 0 && counter !=  1) counter2 <= counter2 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 1 && counter !=  5) counter2 <= counter2 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 2 && counter != 13) counter2 <= counter2 ;
    
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 0 && counter ==  1 && counter2 <  2) counter2 <= counter2 +1 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 1 && counter ==  5 && counter2 <  6) counter2 <= counter2 +1 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 2 && counter == 13 && counter2 < 14) counter2 <= counter2 +1 ;
    
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 0 && counter ==  1 && counter2 ==  2) counter2 <= 0 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 1 && counter ==  5 && counter2 ==  6) counter2 <= 0 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 0 && counter3 == 19 && matrix_size_span == 2 && counter == 13 && counter2 == 14) counter2 <= 0 ;

    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && !(counter3 == 19)) counter2 <= counter2 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 0 && counter != 11) counter2 <= counter2 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 1 && counter != 19) counter2 <= counter2 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 2 && counter != 35) counter2 <= counter2 ;
    
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 0 && counter == 11 && counter2 < 12) counter2 <= counter2 +1 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 1 && counter == 19 && counter2 < 20) counter2 <= counter2 +1 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 2 && counter == 35 && counter2 < 36) counter2 <= counter2 +1 ;
    
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 0 && counter == 11 && counter2 == 12) counter2 <= 0 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 1 && counter == 19 && counter2 == 20) counter2 <= 0 ;
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && mode_span == 1 && counter3 == 19 && matrix_size_span == 2 && counter == 35 && counter2 == 36) counter2 <= 0 ;
    else begin
        counter2 <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter3 <= 0;
    end
    //take img from sram
    else if(current_state == INPUT_CON &&
    (( counter3 <   68 && matrix_size_span == 0) 
    ||(counter3 <  260 && matrix_size_span == 1) 
    ||(counter3 < 1028 && matrix_size_span == 2)))
        counter3 <= counter3 + 1;
    else if(current_state == INPUT_CON && 
    (( counter3 ==   68 && matrix_size_span == 0) 
    ||(counter3 ==  260 && matrix_size_span == 1) 
    ||(counter3 == 1028 && matrix_size_span == 2)))
        counter3 <= 0;
    //output
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && counter3 == 19) begin
        counter3 <= 0;
    end
    else if((current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) && counter3 != 19) begin
        counter3 <= counter3 + 1;
    end

    //deconvolution input
    else if(current_state == INPUT_DECON) begin
        if(((matrix_size_span == 0 && counter3 ==   68)
              || (matrix_size_span == 1 && counter3 ==  260) 
              || (matrix_size_span == 2 && counter3 == 1028))) counter3 <= 0;
        else if(((matrix_size_span == 0 && counter3 <   68 && (counter >= 2 && counter <=  9 && counter2 >= 4 && counter2 <= 11))
              || (matrix_size_span == 1 && counter3 <  260 && (counter >= 2 && counter <= 17 && counter2 >= 4 && counter2 <= 19)) 
              || (matrix_size_span == 2 && counter3 < 1028 && (counter >= 2 && counter <= 33 && counter2 >= 4 && counter2 <= 35)))) counter3 <= counter3 + 1;
        else counter3 <= counter3;
    end
    else begin
        counter3 <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter4 <= 0;
    //convolution
    else if(((current_state == CONVOLUTION || current_state == MAX_POOLING) || current_state == DECONVOLUTION) && (counter5 != 4))
        counter4 <= counter4 ;
    else if(((current_state == CONVOLUTION || current_state == MAX_POOLING) ||current_state == DECONVOLUTION) && counter4 < 4 && counter5 == 4)
        counter4 <= counter4 + 1;
    else if(((current_state == CONVOLUTION || current_state == MAX_POOLING) || current_state == DECONVOLUTION) && counter4 == 4 && counter5 == 4)
        counter4 <= 0;

    //deconvolution input
    else if((next_state == DECONVOLUTION) || (next_state == CONVOLUTION) || (current_state == INPUT_DECON
    && ((matrix_size_span == 0 && counter4 ==  7)
    || ( matrix_size_span == 1 && counter4 == 15)
    || ( matrix_size_span == 2 && counter4 == 31)))) counter4 <= 0;

    else if(((matrix_size_span == 0 && counter == 15 && counter2 == 15) 
    || ( matrix_size_span == 1 && counter == 23 && counter2 == 23) 
    || ( matrix_size_span == 2 && counter == 39 && counter2 == 39))) counter4 <= 4;

    else if(current_state == INPUT_DECON
    && ((matrix_size_span == 0 && (counter < 2 || counter >  9 || counter2 < 2 || counter2 >  9)) 
    || ( matrix_size_span == 1 && (counter < 2 || counter > 17 || counter2 < 2 || counter2 > 17)) 
    || ( matrix_size_span == 2 && (counter < 2 || counter > 33 || counter2 < 2 || counter2 > 33)))) counter4 <= counter4;
    
    else if(current_state == INPUT_DECON
    && ((matrix_size_span == 0 && counter4 <  7 && (counter >= 2 && counter <=  9 && counter2 >= 2 && counter2 <=  9))
    || ( matrix_size_span == 1 && counter4 < 15 && (counter >= 2 && counter <= 17 && counter2 >= 2 && counter2 <= 17)) 
    || ( matrix_size_span == 2 && counter4 < 31 && (counter >= 2 && counter <= 33 && counter2 >= 2 && counter2 <= 33)))) counter4 <= counter4 + 1;

    //output
    else if((current_state == OUTPUT) && counter4 == 19) begin
        counter4 <= 0;
    end
    else if((current_state == OUTPUT) && counter4 != 19) begin
        counter4 <= counter4 + 1;
    end


    else counter4 <= 0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter5 <= 0;
    end
    //convolution_and_deconvolution
    else if(((current_state == CONVOLUTION || current_state == MAX_POOLING) || current_state == DECONVOLUTION) && counter5 == 4)
        counter5 <= 0;
    else if(((current_state == CONVOLUTION || current_state == MAX_POOLING) ||current_state == DECONVOLUTION) && counter5 < 4)
        counter5 <= counter5 + 1;

    //deconvolution input
    else if(current_state == INPUT_DECON
    && ((matrix_size_span == 0 && (counter4 <  7 || counter < 2 || counter >  9 || counter2 < 2 || counter2 >  9)) 
    || ( matrix_size_span == 1 && (counter4 < 15 || counter < 2 || counter > 17 || counter2 < 2 || counter2 > 17)) 
    || ( matrix_size_span == 2 && (counter4 < 31 || counter < 2 || counter > 33 || counter2 < 2 || counter2 > 33)))) counter5 <= counter5;

    else if(current_state == INPUT_DECON
    && ((matrix_size_span == 0 && counter4 ==  7 && counter5 ==  7)
    || ( matrix_size_span == 1 && counter4 == 15 && counter5 == 15)
    || ( matrix_size_span == 2 && counter4 == 31 && counter5 == 31))) counter5 <= 0;
    
    else if(current_state == INPUT_DECON
    && ((matrix_size_span == 0 && counter4 ==  7 && counter5 ==  7 && (counter >= 2 && counter <=  9 && counter2 >= 2 && counter2 <=  9))
    || ( matrix_size_span == 1 && counter4 == 15 && counter5 == 15 && (counter >= 2 && counter <= 17 && counter2 >= 2 && counter2 <= 17)) 
    || ( matrix_size_span == 2 && counter4 == 31 && counter5 == 31 && (counter >= 2 && counter <= 33 && counter2 >= 2 && counter2 <= 33)))) counter5 <= counter5 + 1;
    
    else begin
        counter5 <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter6 <= 0;
    //take ker_in from sram
    else if((current_state == INPUT_CON) && (counter3 > 4) && (counter3 < 30) && (counter6 < 4)) counter6 <= counter6 + 1;
    //convolution input
    else if(current_state == INPUT && mode_span == 1) counter6 <= 4;
    //max-pooling
    else if((current_state == CONVOLUTION || current_state == MAX_POOLING) && ((counter[0] != 0 || counter2[0] != 1 || counter5 != 0 || counter4 != 0))) counter6 <= counter6;
    else if((current_state == CONVOLUTION || current_state == MAX_POOLING) && counter != 0
    && ((counter6 < 1 && matrix_size_span == 0) 
    || (counter6 <  5 && matrix_size_span == 1) 
    || (counter6 < 13 && matrix_size_span == 2))) counter6 <= counter6 + 1;
    else if((current_state == CONVOLUTION || current_state == MAX_POOLING)
    && ((counter6 == 1 && matrix_size_span == 0) 
    || (counter6 ==  5 && matrix_size_span == 1) 
    || (counter6 == 13 && matrix_size_span == 2))) counter6 <= 0;
    //deconvolution input
    else if((current_state == INPUT_DECON) && (counter3 < 27)) begin
    if(((matrix_size_span == 0 && counter3 ==   68)
            || (matrix_size_span == 1 && counter3 ==  260) 
            || (matrix_size_span == 2 && counter3 == 1028))) counter6 <= 0;
    else if(((matrix_size_span == 0 && counter3 <   68 && (counter >= 4 && counter <= 11 && counter2 >= 4 && counter2 <= 11))
            || (matrix_size_span == 1 && counter3 <  260 && (counter >= 4 && counter <= 19 && counter2 >= 4 && counter2 <= 19)) 
            || (matrix_size_span == 2 && counter3 < 1028 && (counter >= 4 && counter <= 35 && counter2 >= 4 && counter2 <= 35)))) begin
        if(counter6 > 0) counter6 <= counter6 - 1;
        else if(counter6 == 0) counter6 <= 4;
    end
    else counter6 <= counter6;
    end
    else begin
        counter6 <= 0;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter7 <= 0;
    //take ker_in from sram
    else if((current_state == INPUT_CON) && (counter6 != 4)) counter7 <= counter7;
    else if((current_state == INPUT_CON) && (counter6 == 4) && (counter7 < 4) && (counter3 > 4) && (counter3 < 30)) counter7 <= counter7 + 1;
    //convolution input
    else if(current_state == INPUT && mode_span == 1) counter7 <= 4;
    //max-pooling
    else if((current_state == CONVOLUTION || current_state == MAX_POOLING) && ((counter[0] != 0 || counter2[0] != 1 || counter5 != 0 || counter4 != 0))) counter7 <= counter7;
    else if((current_state == CONVOLUTION || current_state == MAX_POOLING)
    && ((counter6 <  1 && matrix_size_span == 0) 
    || (counter6  <  5 && matrix_size_span == 1) 
    || (counter6  < 13 && matrix_size_span == 2)))
        counter7 <= counter7;
    else if((current_state == CONVOLUTION || current_state == MAX_POOLING)
    && ((counter6 == 1 && counter7 ==  1 && matrix_size_span == 0) 
    || (counter6 ==  5 && counter7 ==  5 && matrix_size_span == 1) 
    || (counter6 == 13 && counter7 == 13 && matrix_size_span == 2)))
        counter7 <= 0;
    else if((current_state == CONVOLUTION || current_state == MAX_POOLING) 
    && ((counter6 ==  1 && counter7 <  1 && matrix_size_span == 0) 
    || ( counter6 ==  5 && counter7 <  5 && matrix_size_span == 1) 
    || ( counter6 == 13 && counter7 < 13 && matrix_size_span == 2)))
        counter7 <= counter7 + 1;
    //deconvolution input
    else if((current_state == INPUT_DECON) && (counter6 != 0)) counter7 <= counter7;
    else if((current_state == INPUT_DECON) && (counter6 == 0) && (counter3 < 27)) begin
        if(((matrix_size_span == 0 && counter3 ==   68)
              || (matrix_size_span == 1 && counter3 ==  260) 
              || (matrix_size_span == 2 && counter3 == 1028))) counter7 <= 0;
        else if(((matrix_size_span == 0 && counter3 <   68 && (counter >= 4 && counter <= 11 && counter2 >= 4 && counter2 <= 11))
              || (matrix_size_span == 1 && counter3 <  260 && (counter >= 4 && counter <= 19 && counter2 >= 4 && counter2 <= 19)) 
              || (matrix_size_span == 2 && counter3 < 1028 && (counter >= 4 && counter <= 35 && counter2 >= 4 && counter2 <= 35)))) begin
        if(counter6 != 0) counter7 <= counter7;
        else if(counter6 == 0 && counter7 > 0) counter7 <= counter7 - 1;
        else if(counter6 == 0 && counter7 == 0) counter7 <= 0; 
        end
        else counter7 <= counter7;
    end
    else begin
        counter7 <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter8 <= 0;
    //max-pooling
    else if((current_state == CONVOLUTION || current_state == MAX_POOLING) && ((counter[0] != 0 || counter2[0] != 1 || counter5 != 0 || counter4 != 0))) counter8 <= counter8;
    else if((current_state == CONVOLUTION || current_state == MAX_POOLING) && counter != 0
    && ((counter8 <  2 && matrix_size_span == 0) 
    || ( counter8 < 10 && matrix_size_span == 1) 
    || ( counter8 < 26 && matrix_size_span == 2))) counter8 <= counter8 + 2;
    else if((current_state == CONVOLUTION || current_state == MAX_POOLING)
    && ((counter8 ==  2 && matrix_size_span == 0) 
    || ( counter8 == 10 && matrix_size_span == 1) 
    || ( counter8 == 26 && matrix_size_span == 2))) counter8 <= 0;
    else counter8 <= 0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter9 <= 0;
    end
    //max-pooling
    else if((current_state == CONVOLUTION || current_state == MAX_POOLING) && ((counter[0] != 0 || counter2[0] != 1 || counter5 != 0 || counter4 != 0))) counter9 <= counter9;
    else if((current_state == CONVOLUTION || current_state == MAX_POOLING)
    && ((counter8 <  2 && matrix_size_span == 0) 
    || (counter8  < 10 && matrix_size_span == 1) 
    || (counter8  < 26 && matrix_size_span == 2)))
        counter9 <= counter9;
    else if((current_state == CONVOLUTION || current_state == MAX_POOLING)
    && ((counter8 ==  2 && counter9 ==  2 && matrix_size_span == 0) 
    || ( counter8 == 10 && counter9 == 10 && matrix_size_span == 1) 
    || ( counter8 == 26 && counter9 == 26 && matrix_size_span == 2)))
        counter9 <= 0;
    else if((current_state == CONVOLUTION || current_state == MAX_POOLING) 
    && ((counter8 ==   2 && counter9 <   2 && matrix_size_span == 0) 
    || ( counter8 ==  10 && counter9 <  10  && matrix_size_span == 1) 
    || ( counter8 ==  26 && counter9 <  26  && matrix_size_span == 2)))
        counter9 <= counter9 + 2;
    else begin
        counter9 <= 0;
    end
end
//=======================================================
//                  Max Polling
//=======================================================
always@(posedge clk) begin
    if(current_state == CONVOLUTION && counter2[0] == 0 && counter4 == 4 && counter5 == 4) mp_data0[counter] <= add2_out ;
    else mp_data0 <= mp_data0;
end

always@(posedge clk) begin
    if(current_state == CONVOLUTION && counter2[0] == 1 && counter4 == 4 && counter5 == 4) mp_data1[counter[0]] <= add2_out ;
    else mp_data1 <= mp_data1;
end
//=======================================================
//              Matrix SRAM Setting
//=======================================================   
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) WEN_matrix <= 1;
    else if(current_state == CONVOLUTION || current_state == CONVOLUTION 
    || next_state == DECONVOLUTION || current_state == DECONVOLUTION
    || next_state == MAX_POOLING || current_state == MAX_POOLING) begin
        WEN_matrix <= 0;
    end
    else WEN_matrix <= 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Addr_matrix <= 0 ;
    end
    else if(current_state == DECONVOLUTION) Addr_matrix <= {counter2[5:0] ,counter[5:0]} ;
    else if(current_state == CONVOLUTION || current_state == MAX_POOLING) Addr_matrix <= {counter7[5:0] ,counter6[5:0]} ;
    else if(current_state == OUTPUT || current_state == OUTPUTLOAD_1 || current_state == OUTPUTLOAD_2) Addr_matrix <= {counter2[5:0] ,counter[5:0]} ;
    else begin
        Addr_matrix <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        DI_matrix <=0 ;
    end
    else if (current_state == DECONVOLUTION && counter4 == 4 && counter5 == 4)begin
        DI_matrix <= add2_out;
    end
    else if (current_state == CONVOLUTION) begin 
        //Img[counter2][counter] <= add2_out ;
        if (((counter[0] == 0 && counter2[0] == 1 && ((counter6 != 1 && matrix_size_span == 0) || (counter6 != 5 && matrix_size_span == 1) || (counter6 != 13 && matrix_size_span == 2))) 
        || (counter[0] == 0 && counter2[0] == 0 && ((counter6 == 1 && matrix_size_span == 0) || (counter6 == 5 && matrix_size_span == 1) || (counter6 == 13 && matrix_size_span == 2)))) 
        && counter5 == 0 && counter4 == 0) begin
            if((mp_data0[counter8] >= mp_data1[0]) && (mp_data0[counter8] >= mp_data0[counter8 + 1]) && (mp_data0[counter8] >= mp_data1[1])) DI_matrix <= mp_data0[counter8];
            else if((mp_data1[0] >= mp_data0[counter8]) && (mp_data1[0] >= mp_data0[counter8 + 1]) && (mp_data1[0] >= mp_data1[1])) DI_matrix <= mp_data1[0];
            else if((mp_data0[counter8 + 1] >= mp_data1[0]) && (mp_data0[counter8 + 1] >= mp_data0[counter8]) && (mp_data0[counter8 + 1] >= mp_data1[1])) DI_matrix <= mp_data0[counter8 + 1];
            else DI_matrix <= mp_data1[1];
        end
    end
    else if (current_state == MAX_POOLING && (((counter[0] == 0 && counter2[0] == 1 && ((counter6 != 1 && matrix_size_span == 0) || (counter6 != 5 && matrix_size_span == 1) || (counter6 != 13 && matrix_size_span == 2))) 
    || (counter[0] == 0 && counter2[0] == 0 && ((counter6 == 1 && matrix_size_span == 0) || (counter6 == 5 && matrix_size_span == 1) || (counter6 == 13 && matrix_size_span == 2)))) 
    && counter5 == 0 && counter4 == 0)) begin
        if((mp_data0[counter8] >= mp_data1[0]) && (mp_data0[counter8] >= mp_data0[counter8 + 1]) && (mp_data0[counter8] >= mp_data1[1])) DI_matrix <= mp_data0[counter8];
        else if((mp_data1[0] >= mp_data0[counter8]) && (mp_data1[0] >= mp_data0[counter8 + 1]) && (mp_data1[0] >= mp_data1[1])) DI_matrix <= mp_data1[0];
        else if((mp_data0[counter8 + 1] >= mp_data1[0]) && (mp_data0[counter8 + 1] >= mp_data0[counter8]) && (mp_data0[counter8 + 1] >= mp_data1[1])) DI_matrix <= mp_data0[counter8 + 1];
        else DI_matrix <= mp_data1[1];
    end
    else begin
        DI_matrix <= DI_matrix;
    end
end


//=======================================================
//                 Img SRAM Setting
//=======================================================   
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) WEN_Img <= 1;
    else if((current_state == LOADIMG | in_valid) & current_state <= LOADIMG) begin
        WEN_Img <= 0;
    end
    else WEN_Img <= 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Addr_Img <=0 ;
    end
    else if ((current_state == LOADIMG || in_valid) && current_state <= LOADIMG)begin
        Addr_Img <= counter;
    end
    else if(current_state == INPUT_CON && counter3 >= 3 && counter3 <= 66 && matrix_size_span == 0)begin
        Addr_Img <= {Index_Img[3:0],counter3_t1[5:0]};
    end
    else if(current_state == INPUT_CON && counter3 >= 3 && counter3 <= 258 && matrix_size_span == 1)begin
        Addr_Img <= {Index_Img[3:0],counter3_t1[7:0]};
    end
    else if(current_state == INPUT_CON && counter3 >= 3 && counter3 <= 1026 && matrix_size_span == 2)begin
        Addr_Img <= {Index_Img[3:0],counter3_t1[9:0]};
    end
    else if(current_state == INPUT_DECON && counter >= 2 && counter <=  9 && counter2 >= 4 && counter2 <= 11 && matrix_size_span == 0) Addr_Img <= {Index_Img[3:0],counter3[5:0]};
    else if(current_state == INPUT_DECON && counter >= 2 && counter <= 17 && counter2 >= 4 && counter2 <= 19 && matrix_size_span == 1) Addr_Img <= {Index_Img[3:0],counter3[7:0]};
    else if(current_state == INPUT_DECON && counter >= 2 && counter <= 33 && counter2 >= 4 && counter2 <= 35 && matrix_size_span == 2) Addr_Img <= {Index_Img[3:0],counter3[9:0]};
    else begin
        Addr_Img <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        DI_Img <=0 ;
    end
    else if (next_state == LOADIMG || current_state == LOADIMG)begin
        DI_Img <= matrix;
    end
    else begin
        DI_Img <= DI_Img;
    end
end

//=======================================================
//                Kernel SRAM Setting
//=======================================================  
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) WEN_Kernel <= 1;
    else if(current_state == LOADKERNEL) begin
        WEN_Kernel <= 0;
    end
    else WEN_Kernel <= 1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Addr_Kernel <=0 ;
    end
    else if (current_state == LOADKERNEL)begin
        Addr_Kernel <= counter;
    end
    else if((current_state == INPUT_CON) && counter3 > 2 && counter3 < 28)begin
        Addr_Kernel <= Index_Kernel * 25 + counter3_t1;
    end
    else if((current_state == INPUT_DECON) && counter3 < 25)begin
        Addr_Kernel <= Index_Kernel * 25 + counter3;
    end
    else begin
        Addr_Kernel <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        DI_Kernel <=0 ;
    end
    else if (current_state == LOADKERNEL)begin
        DI_Kernel <= matrix;
    end
    else begin
        DI_Kernel <= DI_Kernel;
    end
end

//=======================================================
//                    Input
//=======================================================   
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        matrix_size_span <= 0;
    end
    else if(next_state == LOADIMG && current_state != LOADIMG) begin
        matrix_size_span <= matrix_size[1:0];
    end
    else matrix_size_span <= matrix_size_span;
end

always@(posedge clk) begin
    if(current_state == INPUT_CON & counter3 >= 5) begin
        Img[counter2][counter] <= DO_Img;
    end
    else if(current_state == INPUT_DECON) begin
        if(((counter >= 4 && counter <= 11 && counter2 >= 4 && counter2 <= 11 && matrix_size_span == 0)|| (counter >= 4 && counter <= 19 && counter2 >= 4 && counter2 <= 19 && matrix_size_span == 1)
         || (counter >= 4 && counter <= 35 && counter2 >= 4 && counter2 <= 35 && matrix_size_span == 2))) Img[counter2][counter] <= DO_Img;
        else Img[counter2][counter] <= 0;
    end
    // else if (current_state == DECONVOLUTION) Img[counter2][counter] <= add2_out ;

    else begin
        Img <= Img;
    end
end

always@(posedge clk) begin
    if((current_state == INPUT_CON) && counter3 > 4 && counter3 < 30) begin
        Kernel[counter7][counter6] <= DO_Kernel;
    end
    else if((current_state == INPUT_DECON) && counter3 < 27) begin
        Kernel[counter7][counter6] <= DO_Kernel;
    end
    else begin
        Kernel <= Kernel;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Index_Img <= 0;
    end
    else if(in_valid2) Index_Img <= Index_Kernel;
    else begin
        Index_Img <= Index_Img;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Index_Kernel <= 0;
    end
    else if(in_valid2) Index_Kernel <= matrix_idx;
    else begin
        Index_Kernel <= Index_Kernel;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mode_span <= 0;
    end
    else if(current_state == IDLE && in_valid2) begin
        mode_span <= mode;
    end
    else begin
        mode_span <= mode_span;
    end
end
//=======================================================
//                    Output
//=======================================================   
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else if(next_state != IDLE && (current_state == OUTPUT || next_state == OUTPUT)) begin
        if(matrix_size_span == 0 && !(counter == 1 && counter2 == 1 && counter4 == 19) && mode_span == 0) begin
            out_valid <= 1;
        end 
        else if(matrix_size_span == 1 && !(counter == 5 && counter2 == 5 && counter4 == 19) && mode_span == 0) begin
            out_valid <= 1;
        end
        else if(matrix_size_span == 2 && !(counter == 13 && counter2 == 13 && counter4 == 19) && mode_span == 0) begin
            out_valid <= 1;
        end

        else if(matrix_size_span == 0 && !(counter == 11 && counter2 == 11 && counter4 == 19) && mode_span == 1) begin
            out_valid <= 1;
        end 
        else if(matrix_size_span == 1 && !(counter == 19 && counter2 == 19 && counter4 == 19) && mode_span == 1) begin
            out_valid <= 1;
        end
        else if(matrix_size_span == 2 && !(counter == 35 && counter2 == 35 && counter4 == 19) && mode_span == 1) begin
            out_valid <= 1;
        end
    end
    else begin
        out_valid <= 0;
    end
end

always@(*) begin
    if(!rst_n) begin
        out_value <= 0;
    end
    else if(out_valid) begin
        out_value <= DO_matrix[counter4];//[counter2][counter]
    end
    else begin
        out_value <= 0;
    end
end

//=======================================================
//                    SRAM
//=======================================================
MEMORY_matrix matrix_M( 
    .A0(Addr_matrix[0]),
    .A1(Addr_matrix[1]),
    .A2(Addr_matrix[2]),
    .A3(Addr_matrix[3]),
    .A4(Addr_matrix[4]),
    .A5(Addr_matrix[5]),
    .A6(Addr_matrix[6]),
    .A7(Addr_matrix[7]),
    .A8(Addr_matrix[8]),
    .A9(Addr_matrix[9]),
    .A10(Addr_matrix[10]),
    .A11(Addr_matrix[11]),
    .CK(clk),
    .CS(1'b1),
    .OE(1'b1),
    .DI0(DI_matrix[0]),
    .DI1(DI_matrix[1]),
    .DI2(DI_matrix[2]),
    .DI3(DI_matrix[3]),
    .DI4(DI_matrix[4]),
    .DI5(DI_matrix[5]),
    .DI6(DI_matrix[6]),
    .DI7(DI_matrix[7]),
    .DI8(DI_matrix[8]),
    .DI9(DI_matrix[9]),
    .DI10(DI_matrix[10]),
    .DI11(DI_matrix[11]),
    .DI12(DI_matrix[12]),
    .DI13(DI_matrix[13]),
    .DI14(DI_matrix[14]),
    .DI15(DI_matrix[15]),
    .DI16(DI_matrix[16]),
    .DI17(DI_matrix[17]),
    .DI18(DI_matrix[18]),
    .DI19(DI_matrix[19]),
    .DO0(DO_matrix[0]),
    .DO1(DO_matrix[1]),
    .DO2(DO_matrix[2]),
    .DO3(DO_matrix[3]),
    .DO4(DO_matrix[4]),
    .DO5(DO_matrix[5]),
    .DO6(DO_matrix[6]),
    .DO7(DO_matrix[7]),
    .DO8(DO_matrix[8]),
    .DO9(DO_matrix[9]),
    .DO10(DO_matrix[10]),
    .DO11(DO_matrix[11]),
    .DO12(DO_matrix[12]),
    .DO13(DO_matrix[13]),
    .DO14(DO_matrix[14]),
    .DO15(DO_matrix[15]),
    .DO16(DO_matrix[16]),
    .DO17(DO_matrix[17]),
    .DO18(DO_matrix[18]),
    .DO19(DO_matrix[19]),
    .WEB(WEN_matrix)
 );


MEMORY_img img( 
    .A0(Addr_Img[0]),
    .A1(Addr_Img[1]),
    .A2(Addr_Img[2]),
    .A3(Addr_Img[3]),
    .A4(Addr_Img[4]),
    .A5(Addr_Img[5]),
    .A6(Addr_Img[6]),
    .A7(Addr_Img[7]),
    .A8(Addr_Img[8]),
    .A9(Addr_Img[9]),
    .A10(Addr_Img[10]),
    .A11(Addr_Img[11]),
    .A12(Addr_Img[12]),
    .A13(Addr_Img[13]),
    .CK(clk),
    .CS(1'b1),
    .OE(1'b1),
    .DI0(DI_Img[0]),
    .DI1(DI_Img[1]),
    .DI2(DI_Img[2]),
    .DI3(DI_Img[3]),
    .DI4(DI_Img[4]),
    .DI5(DI_Img[5]),
    .DI6(DI_Img[6]),
    .DI7(DI_Img[7]),
    .DO0(DO_Img[0]),
    .DO1(DO_Img[1]),
    .DO2(DO_Img[2]),
    .DO3(DO_Img[3]),
    .DO4(DO_Img[4]),
    .DO5(DO_Img[5]),
    .DO6(DO_Img[6]),
    .DO7(DO_Img[7]),
    .WEB(WEN_Img)
 );

MEMORY_kernel kernel( 
    .A0(Addr_Kernel[0]),
    .A1(Addr_Kernel[1]),
    .A2(Addr_Kernel[2]),
    .A3(Addr_Kernel[3]),
    .A4(Addr_Kernel[4]),
    .A5(Addr_Kernel[5]),
    .A6(Addr_Kernel[6]),
    .A7(Addr_Kernel[7]),
    .A8(Addr_Kernel[8]),
    .CK(clk),
    .CS(1'b1),
    .OE(1'b1),
    .DI0(DI_Kernel[0]),
    .DI1(DI_Kernel[1]),
    .DI2(DI_Kernel[2]),
    .DI3(DI_Kernel[3]),
    .DI4(DI_Kernel[4]),
    .DI5(DI_Kernel[5]),
    .DI6(DI_Kernel[6]),
    .DI7(DI_Kernel[7]),
    .DO0(DO_Kernel[0]),
    .DO1(DO_Kernel[1]),
    .DO2(DO_Kernel[2]),
    .DO3(DO_Kernel[3]),
    .DO4(DO_Kernel[4]),
    .DO5(DO_Kernel[5]),
    .DO6(DO_Kernel[6]),
    .DO7(DO_Kernel[7]),
    .WEB(WEN_Kernel)
 );



endmodule

module Mult2 (
	input  signed [7:0]  mult2_in0, 
	input  signed [7:0]  mult2_in1,
	output signed [17:0] mult2_out
	) ;

 assign mult2_out = mult2_in0 * mult2_in1 ;
endmodule

module Add2 (
	input  signed [17:0]  add2_in0, 
	input  signed [17:0]  add2_in1,
	output signed [19:0]  add2_out
	) ;

 assign add2_out = add2_in0 + add2_in1 ;
endmodule
