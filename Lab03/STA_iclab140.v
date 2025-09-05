/**************************************************************************/
// Copyright (c) 2025, OASIS Lab
// MODULE: STA
// FILE NAME: STA.v
// VERSRION: 1.0
// DATE: 2025/02/26
// AUTHOR: Yu-Hao Cheng, NYCU IEE
// DESCRIPTION: ICLAB 2025 Spring / LAB3 / STA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module STA(
	//INPUT
	rst_n,
	clk,
	in_valid,
	delay,
	source,
	destination,
	//OUTPUT
	out_valid,
	worst_delay,
	path
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input				rst_n, clk, in_valid;
input		[3:0]	delay;
input		[3:0]	source;
input		[3:0]	destination;

output reg			out_valid;
output reg	[7:0]	worst_delay;
output reg	[3:0]	path;


//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [3:0] in_destination	[0:31];
reg [3:0] in_source			[0:31];
reg [0:0] on 				[0:31];
reg [0:0] next_on           [0:31];
reg [0:0] done  			[0:31];
reg [0:0] node_done			[0:15];


reg [7:0] Max_Value			[0:15];
reg [3:0] Self_Delay		[0:15];
reg [3:0] Path_Previous		[0:15];
reg [3:0] Priority			[0:15];

reg [5:0] current_state;
reg [5:0] next_state;
reg [8:0] counter;
// reg [8:0] counter_2;

reg [3:0] pointer;
reg [3:0] answer 			[15:0];


integer i, j;
parameter IDLE     = 0;
parameter INPUT    = 1;
parameter PATH     = 2;
parameter FINDPATH = 3;
parameter OUTPUT   = 4;



wire condition_1;
reg condition_1_span;

assign condition_1 = (on[0] == 0 && on[1] == 0 && on[2] == 0 && on[3] == 0 && on[4] == 0 && on[5] == 0 && on[6] == 0 && on[7] == 0 && on[8] == 0 && on[9] == 0 &&
 on[10] == 0 && on[11] == 0 && on[12] == 0 && on[13] == 0 && on[14] == 0 && on[15] == 0 && on[16] == 0 && on[17] == 0 && on[18] == 0 && on[19] == 0 &&
 on[20] == 0 && on[21] == 0 && on[22] == 0 && on[23] == 0 && on[24] == 0 && on[25] == 0 && on[26] == 0 && on[27] == 0 && on[28] == 0 && on[29] == 0 &&
 on[30] == 0 && on[31] == 0);

 always@(posedge clk or negedge rst_n) begin
    if(!rst_n) condition_1_span <= 0;
	else if(current_state == PATH) condition_1_span <= condition_1;
    else condition_1_span <= 0;
end

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
always@(*) begin
	if(!rst_n) next_state = IDLE;
    else if(current_state == IDLE) begin
        if(in_valid) next_state = INPUT;
        else next_state = current_state;
    end
	else if(current_state == INPUT) begin
        if(counter == 31) next_state = PATH;
        else next_state = current_state;
    end
	else if(current_state == PATH) begin
        if(condition_1 == 1 && condition_1_span == 1) next_state = FINDPATH;
        else next_state = current_state;
    end
	else if(current_state == FINDPATH) begin
        if(pointer == 0) next_state = OUTPUT;
        else next_state = current_state;
    end
	else if(current_state == OUTPUT) begin
        if(path == 1) next_state = IDLE;
        else next_state = current_state;
    end
	else next_state = current_state;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) counter <= 0;
	else if(current_state == INPUT && counter == 31) counter <= 0;
	else if(in_valid) counter <= counter + 1;
	else if(current_state == PATH && (condition_1 == 1 && condition_1_span == 1)) counter <= 2 ;
	else if(current_state == PATH && !condition_1) counter <= counter + 1 ;
	else if(current_state == FINDPATH && Path_Previous[pointer] == 0) counter <= counter ;
	else if(current_state == FINDPATH) counter <= counter + 1 ;
	else if(current_state == OUTPUT && counter == 0) counter <= counter;//Q2:sub or two counter, area is better?
	else if(current_state == OUTPUT) counter <= counter - 1;//Q2:sub or two counter, area is better?
	else counter <= counter;
end



//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0 ; i < 32 ; i++) in_destination[i] <= 0;
	end
	else if (((in_valid && current_state == IDLE) || (current_state == INPUT)) && counter < 32) in_destination[counter] <= destination;
    else begin
		for(i = 0 ; i < 32 ; i++) in_destination[i] <= in_destination[i];
	end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0 ; i < 32 ; i++) in_source[i] <= 0;
	end
	else if (((in_valid && current_state == IDLE) || (current_state == INPUT)) && counter < 32) in_source[counter] <= source;
    else begin
		for(i = 0 ; i < 32 ; i++) in_source[i] <= in_source[i];
	end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0 ; i < 16 ; i++) Self_Delay[i] <= 0;
	end
	else if (((in_valid && current_state == IDLE) || (current_state == INPUT)) && counter < 16) Self_Delay[counter] <= delay;
    else begin
		for(i = 0 ; i < 16 ; i++) Self_Delay[i] <= Self_Delay[i];
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0 ; i < 16 ; i++) Max_Value[i] <= 0;
	end
	else if(current_state == IDLE) begin
		for(i = 0 ; i < 16 ; i++) Max_Value[i] <= 0;
	end
	else if(current_state == INPUT) Max_Value[0] <= Self_Delay[0];
	else if(current_state == PATH) begin
		if(on[0] == 1) 
		begin
			if(Max_Value[in_destination[0]] <= Max_Value[in_source[0]] + Self_Delay[in_destination[0]]) Max_Value[in_destination[0]] <= Max_Value[in_source[0]] + Self_Delay[in_destination[0]]; //Q1:if two path equal?
		end
		else if(on[1] == 1)begin
			if(Max_Value[in_destination[1]] <= Max_Value[in_source[1]] + Self_Delay[in_destination[1]]) Max_Value[in_destination[1]] <= Max_Value[in_source[1]] + Self_Delay[in_destination[1]]; 
		end
		else if(on[2] == 1)begin
			if(Max_Value[in_destination[2]] <= Max_Value[in_source[2]] + Self_Delay[in_destination[2]]) Max_Value[in_destination[2]] <= Max_Value[in_source[2]] + Self_Delay[in_destination[2]]; 
		end
		else if(on[3] == 1)begin
			if(Max_Value[in_destination[3]] <= Max_Value[in_source[3]] + Self_Delay[in_destination[3]]) Max_Value[in_destination[3]] <= Max_Value[in_source[3]] + Self_Delay[in_destination[3]]; 
		end
		else if(on[4] == 1)begin
			if(Max_Value[in_destination[4]] <= Max_Value[in_source[4]] + Self_Delay[in_destination[4]]) Max_Value[in_destination[4]] <= Max_Value[in_source[4]] + Self_Delay[in_destination[4]]; 
		end
		else if(on[5] == 1)begin
			if(Max_Value[in_destination[5]] <= Max_Value[in_source[5]] + Self_Delay[in_destination[5]]) Max_Value[in_destination[5]] <= Max_Value[in_source[5]] + Self_Delay[in_destination[5]]; 
		end
		else if(on[6] == 1)begin
			if(Max_Value[in_destination[6]] <= Max_Value[in_source[6]] + Self_Delay[in_destination[6]]) Max_Value[in_destination[6]] <= Max_Value[in_source[6]] + Self_Delay[in_destination[6]]; 
		end
		else if(on[7] == 1)begin
			if(Max_Value[in_destination[7]] <= Max_Value[in_source[7]] + Self_Delay[in_destination[7]]) Max_Value[in_destination[7]] <= Max_Value[in_source[7]] + Self_Delay[in_destination[7]]; 
		end
		else if(on[8] == 1)begin
			if(Max_Value[in_destination[8]] <= Max_Value[in_source[8]] + Self_Delay[in_destination[8]]) Max_Value[in_destination[8]] <= Max_Value[in_source[8]] + Self_Delay[in_destination[8]]; 
		end
		else if(on[9] == 1)begin
			if(Max_Value[in_destination[9]] <= Max_Value[in_source[9]] + Self_Delay[in_destination[9]]) Max_Value[in_destination[9]] <= Max_Value[in_source[9]] + Self_Delay[in_destination[9]]; 
		end
		else if(on[10] == 1)begin
			if(Max_Value[in_destination[10]] <= Max_Value[in_source[10]] + Self_Delay[in_destination[10]]) Max_Value[in_destination[10]] <= Max_Value[in_source[10]] + Self_Delay[in_destination[10]]; 
		end
		else if(on[11] == 1)begin
			if(Max_Value[in_destination[11]] <= Max_Value[in_source[11]] + Self_Delay[in_destination[11]]) Max_Value[in_destination[11]] <= Max_Value[in_source[11]] + Self_Delay[in_destination[11]]; 
		end
		else if(on[12] == 1)begin
			if(Max_Value[in_destination[12]] <= Max_Value[in_source[12]] + Self_Delay[in_destination[12]]) Max_Value[in_destination[12]] <= Max_Value[in_source[12]] + Self_Delay[in_destination[12]];
		end
		else if(on[13] == 1)begin
			if(Max_Value[in_destination[13]] <= Max_Value[in_source[13]] + Self_Delay[in_destination[13]]) Max_Value[in_destination[13]] <= Max_Value[in_source[13]] + Self_Delay[in_destination[13]]; 
		end
		else if(on[14] == 1)begin
			if(Max_Value[in_destination[14]] <= Max_Value[in_source[14]] + Self_Delay[in_destination[14]]) Max_Value[in_destination[14]] <= Max_Value[in_source[14]] + Self_Delay[in_destination[14]]; 
		end
		else if(on[15] == 1)begin
			if(Max_Value[in_destination[15]] <= Max_Value[in_source[15]] + Self_Delay[in_destination[15]]) Max_Value[in_destination[15]] <= Max_Value[in_source[15]] + Self_Delay[in_destination[15]]; 
		end
		else if(on[16] == 1)begin
			if(Max_Value[in_destination[16]] <= Max_Value[in_source[16]] + Self_Delay[in_destination[16]]) Max_Value[in_destination[16]] <= Max_Value[in_source[16]] + Self_Delay[in_destination[16]]; 
		end
		else if(on[17] == 1)begin
			if(Max_Value[in_destination[17]] <= Max_Value[in_source[17]] + Self_Delay[in_destination[17]]) Max_Value[in_destination[17]] <= Max_Value[in_source[17]] + Self_Delay[in_destination[17]]; 
		end
		else if(on[18] == 1)begin
			if(Max_Value[in_destination[18]] <= Max_Value[in_source[18]] + Self_Delay[in_destination[18]]) Max_Value[in_destination[18]] <= Max_Value[in_source[18]] + Self_Delay[in_destination[18]]; 
		end
		else if(on[19] == 1)begin
			if(Max_Value[in_destination[19]] <= Max_Value[in_source[19]] + Self_Delay[in_destination[19]]) Max_Value[in_destination[19]] <= Max_Value[in_source[19]] + Self_Delay[in_destination[19]]; 
		end
		else if(on[20] == 1)begin
			if(Max_Value[in_destination[20]] <= Max_Value[in_source[20]] + Self_Delay[in_destination[20]]) Max_Value[in_destination[20]] <= Max_Value[in_source[20]] + Self_Delay[in_destination[20]]; 
		end
		else if(on[21] == 1)begin
			if(Max_Value[in_destination[21]] <= Max_Value[in_source[21]] + Self_Delay[in_destination[21]]) Max_Value[in_destination[21]] <= Max_Value[in_source[21]] + Self_Delay[in_destination[21]]; 
		end
		else if(on[22] == 1)begin
			if(Max_Value[in_destination[22]] <= Max_Value[in_source[22]] + Self_Delay[in_destination[22]]) Max_Value[in_destination[22]] <= Max_Value[in_source[22]] + Self_Delay[in_destination[22]]; 
		end
		else if(on[23] == 1)begin
			if(Max_Value[in_destination[23]] <= Max_Value[in_source[23]] + Self_Delay[in_destination[23]]) Max_Value[in_destination[23]] <= Max_Value[in_source[23]] + Self_Delay[in_destination[23]]; 
		end
		else if(on[24] == 1)begin
			if(Max_Value[in_destination[24]] <= Max_Value[in_source[24]] + Self_Delay[in_destination[24]]) Max_Value[in_destination[24]] <= Max_Value[in_source[24]] + Self_Delay[in_destination[24]]; 
		end
		else if(on[25] == 1)begin
			if(Max_Value[in_destination[25]] <= Max_Value[in_source[25]] + Self_Delay[in_destination[25]]) Max_Value[in_destination[25]] <= Max_Value[in_source[25]] + Self_Delay[in_destination[25]]; 
		end
		else if(on[26] == 1)begin
			if(Max_Value[in_destination[26]] <= Max_Value[in_source[26]] + Self_Delay[in_destination[26]]) Max_Value[in_destination[26]] <= Max_Value[in_source[26]] + Self_Delay[in_destination[26]]; 
		end
		else if(on[27] == 1)begin
			if(Max_Value[in_destination[27]] <= Max_Value[in_source[27]] + Self_Delay[in_destination[27]]) Max_Value[in_destination[27]] <= Max_Value[in_source[27]] + Self_Delay[in_destination[27]]; 
		end
		else if(on[28] == 1)begin
			if(Max_Value[in_destination[28]] <= Max_Value[in_source[28]] + Self_Delay[in_destination[28]]) Max_Value[in_destination[28]] <= Max_Value[in_source[28]] + Self_Delay[in_destination[28]]; 
		end
		else if(on[29] == 1)begin
			if(Max_Value[in_destination[29]] <= Max_Value[in_source[29]] + Self_Delay[in_destination[29]]) Max_Value[in_destination[29]] <= Max_Value[in_source[29]] + Self_Delay[in_destination[29]]; 
		end
		else if(on[30] == 1)begin
			if(Max_Value[in_destination[30]] <= Max_Value[in_source[30]] + Self_Delay[in_destination[30]]) Max_Value[in_destination[30]] <= Max_Value[in_source[30]] + Self_Delay[in_destination[30]]; 
		end
		else if(on[31] == 1)begin
			if(Max_Value[in_destination[31]] <= Max_Value[in_source[31]] + Self_Delay[in_destination[31]]) Max_Value[in_destination[31]] <= Max_Value[in_source[31]] + Self_Delay[in_destination[31]]; 
		end
	end
    else begin
		for(i = 0 ; i < 16 ; i++) Max_Value[i] <= Max_Value[i];
	end
end



always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0 ; i < 32 ; i++) on[i] <= 0;
	end
	else if(current_state == PATH && (condition_1 == 1)) begin //shift node
		for(i = 0 ; i < 32 ; i++) on[i] <= next_on[i];
	end
	else if(current_state == PATH && !(condition_1 == 1)) begin
		if(on[0] == 1) on[0] <= 0;
 		else if(on[1] == 1) on[1] <= 0;
 		else if(on[2] == 1) on[2] <= 0;
 		else if(on[3] == 1) on[3] <= 0;
 		else if(on[4] == 1) on[4] <= 0;
 		else if(on[5] == 1) on[5] <= 0;
 		else if(on[6] == 1) on[6] <= 0;
 		else if(on[7] == 1) on[7] <= 0;
 		else if(on[8] == 1) on[8] <= 0;
 		else if(on[9] == 1) on[9] <= 0;
 		else if(on[10] == 1) on[10] <= 0;
 		else if(on[11] == 1) on[11] <= 0;
 		else if(on[12] == 1) on[12] <= 0;
 		else if(on[13] == 1) on[13] <= 0;
 		else if(on[14] == 1) on[14] <= 0;
 		else if(on[15] == 1) on[15] <= 0;
 		else if(on[16] == 1) on[16] <= 0;
 		else if(on[17] == 1) on[17] <= 0;
 		else if(on[18] == 1) on[18] <= 0;
 		else if(on[19] == 1) on[19] <= 0;
 		else if(on[20] == 1) on[20] <= 0;
 		else if(on[21] == 1) on[21] <= 0;
 		else if(on[22] == 1) on[22] <= 0;
 		else if(on[23] == 1) on[23] <= 0;
 		else if(on[24] == 1) on[24] <= 0;
 		else if(on[25] == 1) on[25] <= 0;
 		else if(on[26] == 1) on[26] <= 0;
 		else if(on[27] == 1) on[27] <= 0;
 		else if(on[28] == 1) on[28] <= 0;
 		else if(on[29] == 1) on[29] <= 0;
 		else if(on[30] == 1) on[30] <= 0;
 		else if(on[31] == 1) on[31] <= 0;
	end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0 ; i < 16 ; i++) node_done[i] <= 1;
 	end
	else if(current_state == OUTPUT) begin
		for(i = 0 ; i < 16 ; i++) node_done[i] <= 1;
 	end
	// else if(((in_valid && current_state == IDLE) || (current_state == INPUT)) && counter < 32) begin
	// 	if(source == 0) node_done[destination] <= 1;
	// 	else node_done[destination] <= 0;
	// end
	else if(current_state == PATH && (condition_1)) begin
		for(i = 0 ; i < 32 ; i++) begin
			if(!(done[i])) node_done[in_destination[i]] <= 0;
		end
	end
	else if(current_state == PATH && (condition_1_span)) begin
		for(i = 0 ; i < 16 ; i++) node_done[i] <= 1;
	end
	
end

 always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0 ; i < 32 ; i++) done[i] <= 0;
 	end
	else if(current_state == OUTPUT) begin
		for(i = 0 ; i < 32 ; i++) done[i] <= 0;
 	end
	else if(((in_valid && current_state == IDLE) || (current_state == INPUT)) && counter < 32) begin
		if(source == 0) done[counter] <= 1;
		else done[counter] <= 0;
	end
	else if(current_state == PATH && !(condition_1 == 1) && (condition_1_span == 1)) begin //shift node
		for(i = 0 ; i < 32 ; i ++) begin
			for(j = 0 ; j < 32 ; j ++) begin
				if(on[i] == 1 && (in_source[j] == in_destination[i]) && node_done[in_source[j]] == 1) done[j] <= 1;
			end
		end
	end
end

 always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(i = 0 ; i < 32 ; i++) next_on[i] <= 0;
 	end
	else if(current_state == OUTPUT) begin
		for(i = 0 ; i < 32 ; i++) next_on[i] <= 0;
 	end
	else if(((in_valid && current_state == IDLE) || (current_state == INPUT)) && counter < 32) begin
		if(source == 0) next_on[counter] <= 1;
		else next_on[counter] <= 0;
	end
	else if(current_state == PATH && (condition_1 == 1)) begin //shift node
		for(i = 0 ; i < 32 ; i++) next_on[i] <= 0;
	end
	// else if(current_state == PATH && (condition_1 == 1) && !(condition_1_span == 1)) begin //shift node
	else if(current_state == PATH && !(condition_1 == 1) && (condition_1_span == 1)) begin //shift node
		for(i = 0 ; i < 32 ; i ++) begin
			for(j = 0 ; j < 32 ; j ++) begin
				if(on[i] == 1 && (in_source[j] == in_destination[i]) && node_done[in_source[j]] == 1) next_on[j] <= 1;
			end
		end
	end
	// else next_on[i] <= next_on[i];
end




always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0 ; i < 16 ; i++) Path_Previous[i] <= 0;
	end
	else if(current_state == IDLE) begin
		for(i = 0 ; i < 16 ; i++) Path_Previous[i] <= 0;
	end
	else if(current_state == PATH && !condition_1) begin
		if(on[0] == 1) 
		begin
			if(Max_Value[in_destination[0]] <= Max_Value[in_source[0]] + Self_Delay[in_destination[0]]) Path_Previous[in_destination[0]] <= in_source[0]; 
		end
		else if(on[1] == 1) 
		begin
			if(Max_Value[in_destination[1]] <= Max_Value[in_source[1]] + Self_Delay[in_destination[1]]) Path_Previous[in_destination[1]] <= in_source[1]; 
		end
		else if(on[2] == 1) 
		begin
			if(Max_Value[in_destination[2]] <= Max_Value[in_source[2]] + Self_Delay[in_destination[2]]) Path_Previous[in_destination[2]] <= in_source[2]; 
		end
		else if(on[3] == 1) 
		begin
			if(Max_Value[in_destination[3]] <= Max_Value[in_source[3]] + Self_Delay[in_destination[3]]) Path_Previous[in_destination[3]] <= in_source[3]; 
		end
		else if(on[4] == 1) 
		begin
			if(Max_Value[in_destination[4]] <= Max_Value[in_source[4]] + Self_Delay[in_destination[4]]) Path_Previous[in_destination[4]] <= in_source[4]; 
		end
		else if(on[5] == 1) 
		begin
			if(Max_Value[in_destination[5]] <= Max_Value[in_source[5]] + Self_Delay[in_destination[5]]) Path_Previous[in_destination[5]] <= in_source[5]; 
		end
		else if(on[6] == 1) 
		begin
			if(Max_Value[in_destination[6]] <= Max_Value[in_source[6]] + Self_Delay[in_destination[6]]) Path_Previous[in_destination[6]] <= in_source[6]; 
		end
		else if(on[7] == 1) 
		begin
			if(Max_Value[in_destination[7]] <= Max_Value[in_source[7]] + Self_Delay[in_destination[7]]) Path_Previous[in_destination[7]] <= in_source[7]; 
		end
		else if(on[8] == 1) 
		begin
			if(Max_Value[in_destination[8]] <= Max_Value[in_source[8]] + Self_Delay[in_destination[8]]) Path_Previous[in_destination[8]] <= in_source[8]; 
		end
		else if(on[9] == 1) 
		begin
			if(Max_Value[in_destination[9]] <= Max_Value[in_source[9]] + Self_Delay[in_destination[9]]) Path_Previous[in_destination[9]] <= in_source[9]; 
		end
		else if(on[10] == 1) 
		begin
			if(Max_Value[in_destination[10]] <= Max_Value[in_source[10]] + Self_Delay[in_destination[10]]) Path_Previous[in_destination[10]] <= in_source[10]; 
		end
		else if(on[11] == 1) 
		begin
			if(Max_Value[in_destination[11]] <= Max_Value[in_source[11]] + Self_Delay[in_destination[11]]) Path_Previous[in_destination[11]] <= in_source[11]; 
		end
		else if(on[12] == 1) 
		begin
			if(Max_Value[in_destination[12]] <= Max_Value[in_source[12]] + Self_Delay[in_destination[12]]) Path_Previous[in_destination[12]] <= in_source[12]; 
		end
		else if(on[13] == 1) 
		begin
			if(Max_Value[in_destination[13]] <= Max_Value[in_source[13]] + Self_Delay[in_destination[13]]) Path_Previous[in_destination[13]] <= in_source[13]; 
		end
		else if(on[14] == 1) 
		begin
			if(Max_Value[in_destination[14]] <= Max_Value[in_source[14]] + Self_Delay[in_destination[14]]) Path_Previous[in_destination[14]] <= in_source[14]; 
		end
		else if(on[15] == 1) 
		begin
			if(Max_Value[in_destination[15]] <= Max_Value[in_source[15]] + Self_Delay[in_destination[15]]) Path_Previous[in_destination[15]] <= in_source[15]; 
		end
		else if(on[16] == 1) 
		begin
			if(Max_Value[in_destination[16]] <= Max_Value[in_source[16]] + Self_Delay[in_destination[16]]) Path_Previous[in_destination[16]] <= in_source[16]; 
		end
		else if(on[17] == 1) 
		begin
			if(Max_Value[in_destination[17]] <= Max_Value[in_source[17]] + Self_Delay[in_destination[17]]) Path_Previous[in_destination[17]] <= in_source[17]; 
		end
		else if(on[18] == 1) 
		begin
			if(Max_Value[in_destination[18]] <= Max_Value[in_source[18]] + Self_Delay[in_destination[18]]) Path_Previous[in_destination[18]] <= in_source[18]; 
		end
		else if(on[19] == 1) 
		begin
			if(Max_Value[in_destination[19]] <= Max_Value[in_source[19]] + Self_Delay[in_destination[19]]) Path_Previous[in_destination[19]] <= in_source[19]; 
		end
		else if(on[20] == 1) 
		begin
			if(Max_Value[in_destination[20]] <= Max_Value[in_source[20]] + Self_Delay[in_destination[20]]) Path_Previous[in_destination[20]] <= in_source[20]; 
		end
		else if(on[21] == 1) 
		begin
			if(Max_Value[in_destination[21]] <= Max_Value[in_source[21]] + Self_Delay[in_destination[21]]) Path_Previous[in_destination[21]] <= in_source[21]; 
		end
		else if(on[22] == 1) 
		begin
			if(Max_Value[in_destination[22]] <= Max_Value[in_source[22]] + Self_Delay[in_destination[22]]) Path_Previous[in_destination[22]] <= in_source[22]; 
		end
		else if(on[23] == 1) 
		begin
			if(Max_Value[in_destination[23]] <= Max_Value[in_source[23]] + Self_Delay[in_destination[23]]) Path_Previous[in_destination[23]] <= in_source[23]; 
		end
		else if(on[24] == 1) 
		begin
			if(Max_Value[in_destination[24]] <= Max_Value[in_source[24]] + Self_Delay[in_destination[24]]) Path_Previous[in_destination[24]] <= in_source[24]; 
		end
		else if(on[25] == 1) 
		begin
			if(Max_Value[in_destination[25]] <= Max_Value[in_source[25]] + Self_Delay[in_destination[25]]) Path_Previous[in_destination[25]] <= in_source[25]; 
		end
		else if(on[26] == 1) 
		begin
			if(Max_Value[in_destination[26]] <= Max_Value[in_source[26]] + Self_Delay[in_destination[26]]) Path_Previous[in_destination[26]] <= in_source[26]; 
		end
		else if(on[27] == 1) 
		begin
			if(Max_Value[in_destination[27]] <= Max_Value[in_source[27]] + Self_Delay[in_destination[27]]) Path_Previous[in_destination[27]] <= in_source[27]; 
		end
		else if(on[28] == 1) 
		begin
			if(Max_Value[in_destination[28]] <= Max_Value[in_source[28]] + Self_Delay[in_destination[28]]) Path_Previous[in_destination[28]] <= in_source[28]; 
		end
		else if(on[29] == 1) 
		begin
			if(Max_Value[in_destination[29]] <= Max_Value[in_source[29]] + Self_Delay[in_destination[29]]) Path_Previous[in_destination[29]] <= in_source[29]; 
		end
		else if(on[30] == 1) 
		begin
			if(Max_Value[in_destination[30]] <= Max_Value[in_source[30]] + Self_Delay[in_destination[30]]) Path_Previous[in_destination[30]] <= in_source[30]; 
		end
		else if(on[31] == 1) 
		begin
			if(Max_Value[in_destination[31]] <= Max_Value[in_source[31]] + Self_Delay[in_destination[31]]) Path_Previous[in_destination[31]] <= in_source[31]; 
		end

	end
    else begin
		for(i = 0 ; i < 16 ; i++) Path_Previous[i] <= Path_Previous[i];
	end
end


//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) pointer <= 0;
	else if(current_state == PATH) begin
		if(condition_1 == 1 && condition_1_span == 1) pointer <= Path_Previous[1];
	end
	else if(current_state == FINDPATH) begin
		pointer <= Path_Previous[pointer];
	end
	else pointer <= 1;
end


always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0 ; i < 16 ; i++) answer[i] <= 0;
	end
	else if(current_state == IDLE) begin
		for(i = 0 ; i < 16 ; i++) answer[i] <= 0;
	end
	else if(current_state == PATH) begin
		if(condition_1 == 1 && condition_1_span == 1) begin
			answer[0] <= 1;
			answer[1] <= Path_Previous[1];
		end
	end
	else if(current_state == FINDPATH) begin
		answer[counter] <= Path_Previous[pointer];
	end
	else begin
		for(i = 0 ; i < 16 ; i++) answer[i] <= answer[i];
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 0;
	else if(current_state == OUTPUT && path == 1) out_valid <= 0;
	else if(current_state == OUTPUT && counter != 0) out_valid <= 1;
	else out_valid <= out_valid;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) worst_delay <= 0;
	else if(current_state == OUTPUT && out_valid != 0) worst_delay <= 0;
	else if(current_state == OUTPUT && out_valid == 0) worst_delay <= Max_Value[1];
	else worst_delay <= 0;
end
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) path <= 0;
	else if(current_state == OUTPUT && path == 1) path <= 0;
	else if(current_state == OUTPUT) path <= answer[counter];
	else if(current_state == FINDPATH && pointer == 0) path <= answer[counter];
	else path <= 0;
end
endmodule