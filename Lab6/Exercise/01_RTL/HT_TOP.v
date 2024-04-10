//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : HT_TOP.v
//   	Module Name : HT_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "SORT_IP.v"
//synopsys translate_on

module HT_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_weight, 
	out_mode,
    // Output signals
    out_valid, 
	out_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid, out_mode;
input [2:0] in_weight;

output reg out_valid, out_code;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================
parameter IDLE = 0;
parameter LOAD = 1;
parameter SORTIP = 2;
parameter SORT = 3;
parameter COMBINE = 4;
parameter OUTPUTSORT = 5;
parameter OUTPUT = 6;

parameter A = 0;
parameter B = 1;
parameter C = 2;
parameter E = 3;
parameter I = 4;
parameter L = 5;
parameter O = 6;
parameter V = 7;
parameter Subtree = 8;

integer  i,j;

reg out_mode_span;
reg [9:0]new_priority;
reg [7:0] new_Weight;
reg new_Weight_set;
reg [7:0][9:0]Priority;
reg [7:0][4:0]Weight;
//reg [7:0][4:0]Weight_Sort;
reg [39:0]IN_weight;
reg [7:0][3:0]Character;
reg [7:0][3:0]Character_Sort;
//reg [7:0][3:0]Character_Sort;
reg [31:0]IN_character;
reg [31:0]OUT_character;
reg [7:0][3:0]Layer;
reg [7:0][2:0]Combine_or_not;
reg [7:0][7:0]Path;
reg [15:0] current_state,next_state;
reg [15:0] counter1;
reg done;
reg [7:0]out_cnt_1,out_cnt_2;
reg [7:0][4:0]change_or_not;
// ===============================================================
// Design
// ===============================================================

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
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
				if(counter1 == 7) next_state = SORTIP;
				else next_state = current_state;
			end
            SORTIP : begin
				if(counter1 == 8) next_state = SORT;
				else next_state = current_state;
			end
            SORT : begin
				if(counter1 == 13) next_state = COMBINE;
				else next_state = current_state;
			end
            COMBINE : begin
				if(counter1 == 11 & done == 1) next_state = OUTPUTSORT;
                else if(counter1 == 11 & done != 1) next_state = SORTIP;
				else next_state = current_state;
			end
            OUTPUTSORT : begin
				if(counter1 == 5) next_state = OUTPUT;
				else next_state = current_state;
			end
            OUTPUT : begin
				if(out_cnt_1 == 0 & out_cnt_2 == 4) next_state = IDLE;
				else next_state = current_state;
			end
			default : next_state = current_state;
		endcase
	end
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter1 <= 0;
    end
    else if((in_valid | current_state == LOAD) & counter1 < 7) 
        counter1 <= counter1 + 1;
    else if(current_state == LOAD & counter1 == 7) 
        counter1 <= 0;
    else if(current_state == SORTIP & counter1 < 8) 
        counter1 <= counter1 + 1;
    else if(current_state == SORTIP & counter1 == 8) 
        counter1 <= 0;
    else if(current_state == SORT & counter1 < 13) 
        counter1 <= counter1 + 1;
    else if(current_state == SORT & counter1 == 13) 
        counter1 <= 0;
    else if(current_state == COMBINE & counter1 < 11) 
        counter1 <= counter1 + 1;
    else if(current_state == COMBINE & counter1 == 11) 
        counter1 <= 0;
    else if(current_state == OUTPUTSORT & counter1 < 5) 
        counter1 <= counter1 + 1;
    else if(current_state == OUTPUTSORT & counter1 == 5) 
        counter1 <= 0;
    else if(current_state == OUTPUT & !(out_cnt_1 == 0 & out_cnt_2 == 4)) 
        counter1 <= counter1 + 1;
    else if(current_state == OUTPUT & (out_cnt_1 == 0 & out_cnt_2 == 4)) 
        counter1 <= 0;
    else begin
        counter1 <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        new_priority <= 0;
    end
    else if(current_state == LOAD) 
        new_priority <= 8;
    else if(current_state == SORT) begin
        if(counter1 == 7) new_priority <= new_priority + 1;
    end
    else begin
        new_priority <= new_priority;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_mode_span <= 0;
    end
    else if(in_valid & counter1 == 0) begin 
        out_mode_span <= out_mode;
    end
    else begin
        out_mode_span <= out_mode_span;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        new_Weight <= 0;
    end
    // else if(current_state == SORT) 
    //     new_Weight <= 0;
    else if(current_state == COMBINE & counter1 == 0) begin 
        new_Weight <= Weight[7];
    end
    else if(current_state == COMBINE & (counter1 >= 1 & counter1 <= 8)) begin 
        for(i=6 ; i >= 0; i--)begin
            if((Priority[i] != Priority[7]) & (Priority[i+1] == Priority[7]) & new_Weight_set == 0)
                new_Weight <= Weight[7] + Weight[i];
        end
    end
    else begin
        new_Weight <= new_Weight;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        new_Weight_set <= 0;
    end
    else if(current_state == SORT) 
        new_Weight_set <= 0;
    else if(current_state == COMBINE & (counter1 >= 1 & counter1 <= 8)) begin 
        for(i=6 ; i >= 0; i--)begin
            if((Priority[i] != Priority[7]) & (Priority[i+1] == Priority[7]) & new_Weight_set == 0)
                new_Weight_set <= 1;  
        end
    end
    else begin
        new_Weight_set <= new_Weight_set;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        done <= 0;
    end
    else if(current_state == LOAD) done <= 0;
    else if(current_state == COMBINE & counter1 == 0) done <= 1;
    else  if(current_state == COMBINE & counter1 == 10)begin
        for(i=0 ; i < 7; i++) begin
            if((Priority[i] != Priority[i+1])) done <= 0; 
        end
    end
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Weight <= 0;
    end
    else if((in_valid | current_state == LOAD) & counter1 < 8) 
        Weight[counter1] <= in_weight;
    
    // else if(current_state == SORT) begin
    //     for(i=0 ; i < 7 ; i++) begin
    //         if((Weight[i+1] > Weight[i]) | ((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
    //             Weight[i+1] <= Weight[i];
    //             Weight[i] <= Weight[i+1];
    //         end
    //     end
    // end
    else if(current_state == COMBINE & counter1 == 9) begin
        for(i=0 ; i < 8 ; i++) begin
            if(Combine_or_not[i] != 0) begin
                Weight[i] <= new_Weight;
            end
        end
    end
    else if(current_state == SORTIP & counter1 == 0) begin
        IN_weight[4:0]   <= Weight[0];
        IN_weight[9:5]   <= Weight[1];
        IN_weight[14:10] <= Weight[2];
        IN_weight[19:15] <= Weight[3];
        IN_weight[24:20] <= Weight[4];
        IN_weight[29:25] <= Weight[5];
        IN_weight[34:30] <= Weight[6];
        IN_weight[39:35] <= Weight[7];
        //change_or_not <= 0;
    end
    // else if(current_state == SORTIP & counter1 == 2) begin
    //     Weight[0] <= Weight[Character_Sort[7]];
    //     Weight[1] <= Weight[Character_Sort[6]];
    //     Weight[2] <= Weight[Character_Sort[5]];
    //     Weight[3] <= Weight[Character_Sort[4]];
    //     Weight[4] <= Weight[Character_Sort[3]];
    //     Weight[5] <= Weight[Character_Sort[2]];
    //     Weight[6] <= Weight[Character_Sort[1]];
    //     Weight[7] <= Weight[Character_Sort[0]];
    // end
    else if(current_state == SORTIP & counter1 >= 2 & counter1 <= 8) begin
        //for(i=7 ; i >= j  ; i--) begin
        for(i=0 ; i < 8  ; i++) begin
            //if((Character_Sort[counter1 - 2] == Character[i]))begin((change_or_not[counter1 - 2] != change_or_not[i]) & (change_or_not[counter1 - 2] != 0)) | (change_or_not[counter1 - 2] == 0)) begin
            //if(Character_Sort[counter1 - 2] == Character[i] & change_or_not[counter1 - 2] == 0 & change_or_not[i] == 0) begin
            if(Character_Sort[counter1 - 2] == Character[i]) begin
                Weight[i] <= Weight[counter1 - 2];
                Weight[counter1 - 2] <= Weight[i];
                //change_or_not[i] <= Character_Sort[counter1 - 2];
                //change_or_not[counter1 - 2] <= Character_Sort[counter1 - 2];
            end
        end
        //end
    end
    else if(current_state == SORT & (counter1 % 2 == 0)) begin
        for(i=0 ; i < 7 ; i = i + 2) begin
            if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
                Weight[i+1] <= Weight[i];
                Weight[i] <= Weight[i+1];
            end
        end
    end
    else if(current_state == SORT & (counter1 % 2 == 1)) begin
        for(i=1 ; i < 7 ; i = i + 2) begin
            if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
                Weight[i+1] <= Weight[i];
                Weight[i] <= Weight[i+1];
            end
        end
    end
    // else if(current_state == SORT) begin
    //     for(i=0 ; i < 7 ; i++) begin
    //         if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
    //             Weight[i+1] <= Weight[i];
    //             Weight[i] <= Weight[i+1];
    //         end
    //     end
    // end
    else if(current_state == OUTPUTSORT)begin
        for(i=0 ; i<8 ; i++) begin
            if(counter1 == 0) begin
                if(out_mode_span == 0 & Character[i] == 4) begin
                    Weight[0] <= Weight[i];
                    Weight[i] <= Weight[0];
                end
                else if(out_mode_span == 1 & Character[i] == 4) begin
                    Weight[0] <= Weight[i];
                    Weight[i] <= Weight[0];
                end
            end
            else if(counter1 == 1) begin
                if(out_mode_span == 0 & Character[i] == 5) begin
                    Weight[1] <= Weight[i];
                    Weight[i] <= Weight[1];
                end
                else if(out_mode_span == 1 & Character[i] == 2) begin
                    Weight[1] <= Weight[i];
                    Weight[i] <= Weight[1];
                end
            end
            else if(counter1 == 2) begin
                if(out_mode_span == 0 & Character[i] == 6) begin
                    Weight[2] <= Weight[i];
                    Weight[i] <= Weight[2];
                end
                else if(out_mode_span == 1 & Character[i] == 5) begin
                    Weight[2] <= Weight[i];
                    Weight[i] <= Weight[2];
                end
            end
            else if(counter1 == 3) begin
                if(out_mode_span == 0 & Character[i] == 7) begin
                    Weight[3] <= Weight[i];
                    Weight[i] <= Weight[3];
                end
                else if(out_mode_span == 1 & Character[i] == 0) begin
                    Weight[3] <= Weight[i];
                    Weight[i] <= Weight[3];
                end
            end
            else if(counter1 == 4) begin
                if(out_mode_span == 0 & Character[i] == 3) begin
                    Weight[4] <= Weight[i];
                    Weight[i] <= Weight[4];
                end
                else if(out_mode_span == 1 & Character[i] == 1) begin
                    Weight[4] <= Weight[i];
                    Weight[i] <= Weight[4];
                end
            end
        end
    end
    else begin
        Weight <= Weight;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Character <= 0;
    end
    else if((in_valid | current_state == LOAD) & counter1 < 8) 
        Character[counter1] <= counter1 ;
        else if(current_state == SORTIP & counter1 == 0) begin
        IN_character[3:0]   <= Character[0];
        IN_character[7:4]   <= Character[1];
        IN_character[11:8]  <= Character[2];
        IN_character[15:12] <= Character[3];
        IN_character[19:16] <= Character[4];
        IN_character[23:20] <= Character[5];
        IN_character[27:24] <= Character[6];
        IN_character[31:28] <= Character[7];
    end
    else if(current_state == SORTIP & counter1 == 1) begin
        Character_Sort[7] <= OUT_character[3:0]  ;
        Character_Sort[6] <= OUT_character[7:4]  ;
        Character_Sort[5] <= OUT_character[11:8] ;
        Character_Sort[4] <= OUT_character[15:12];
        Character_Sort[3] <= OUT_character[19:16];
        Character_Sort[2] <= OUT_character[23:20];
        Character_Sort[1] <= OUT_character[27:24];
        Character_Sort[0] <= OUT_character[31:28];
    end
    else if(current_state == SORTIP & counter1 >= 2 & counter1 <= 8) begin
        for(i=0 ; i < 8  ; i++) begin
            if(Character_Sort[counter1 - 2] == Character[i]) begin
                Character[i] <= Character[counter1 - 2];
                Character[counter1 - 2] <= Character[i];
            end
        end
    end
    // else if(current_state == SORTIP & counter1 == 10) begin
    //     Character[0] <= Character_Sort[0];
    //     Character[1] <= Character_Sort[1];
    //     Character[2] <= Character_Sort[2];
    //     Character[3] <= Character_Sort[3];
    //     Character[4] <= Character_Sort[4];
    //     Character[5] <= Character_Sort[5];
    //     Character[6] <= Character_Sort[6];
    //     Character[7] <= Character_Sort[7];
    // end
    else if(current_state == SORT & (counter1 % 2 == 0)) begin
        for(i=0 ; i < 7 ; i = i + 2) begin
            if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
                Character[i+1] <= Character[i];
                Character[i] <= Character[i+1];
            end
        end
    end
    else if(current_state == SORT & (counter1 % 2 == 1)) begin
        for(i=1 ; i < 7 ; i = i + 2) begin
            if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
                Character[i+1] <= Character[i];
                Character[i] <= Character[i+1];
            end
        end
    end
    // else if(current_state == SORT) begin
    //     for(i=0 ; i < 7 ; i++) begin
    //         if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
    //             Character[i+1] <= Character[i];
    //             Character[i] <= Character[i+1];
    //         end
    //     end
    // end
    else if(current_state == OUTPUTSORT)begin
        for(i=0 ; i<8 ; i++) begin
            if(counter1 == 0) begin
                if(out_mode_span == 0 & Character[i] == 4) begin
                    Character[0] <= Character[i];
                    Character[i] <= Character[0];
                end
                else if(out_mode_span == 1 & Character[i] == 4) begin
                    Character[0] <= Character[i];
                    Character[i] <= Character[0];
                end
            end
            else if(counter1 == 1) begin
                if(out_mode_span == 0 & Character[i] == 5) begin
                    Character[1] <= Character[i];
                    Character[i] <= Character[1];
                end
                else if(out_mode_span == 1 & Character[i] == 2) begin
                    Character[1] <= Character[i];
                    Character[i] <= Character[1];
                end
            end
            else if(counter1 == 2) begin
                if(out_mode_span == 0 & Character[i] == 6) begin
                    Character[2] <= Character[i];
                    Character[i] <= Character[2];
                end
                else if(out_mode_span == 1 & Character[i] == 5) begin
                    Character[2] <= Character[i];
                    Character[i] <= Character[2];
                end
            end
            else if(counter1 == 3) begin
                if(out_mode_span == 0 & Character[i] == 7) begin
                    Character[3] <= Character[i];
                    Character[i] <= Character[3];
                end
                else if(out_mode_span == 1 & Character[i] == 0) begin
                    Character[3] <= Character[i];
                    Character[i] <= Character[3];
                end
            end
            else if(counter1 == 4) begin
                if(out_mode_span == 0 & Character[i] == 3) begin
                    Character[4] <= Character[i];
                    Character[i] <= Character[4];
                end
                else if(out_mode_span == 1 & Character[i] == 1) begin
                    Character[4] <= Character[i];
                    Character[i] <= Character[4];
                end
            end
        end
    end
    else begin
        Character <= Character;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Priority <= 0;
    end
    else if((in_valid | current_state == LOAD) & counter1 < 8) 
        Priority[counter1] <= counter1;
    // else if(current_state == SORTIP & counter1 >= 2 & counter1 <= 8) begin
    //     for(i=0 ; i < 8 ; i++) begin
    //         if(Character[counter1 - 2] == Character_Sort[i]) begin
    //             Priority[counter1 - 2] <= Priority[i];
    //             Priority[i] <= Priority[counter1 - 2];
    //         end
    //     end
    // end
    // else if(current_state == SORTIP & counter1 == 2) begin
    //     Priority[0] <= Priority[Character_Sort[7]];
    //     Priority[1] <= Priority[Character_Sort[6]];
    //     Priority[2] <= Priority[Character_Sort[5]];
    //     Priority[3] <= Priority[Character_Sort[4]];
    //     Priority[4] <= Priority[Character_Sort[3]];
    //     Priority[5] <= Priority[Character_Sort[2]];
    //     Priority[6] <= Priority[Character_Sort[1]];
    //     Priority[7] <= Priority[Character_Sort[0]];
    // end
    else if(current_state == SORTIP & counter1 >= 2 & counter1 <= 8) begin
        for(i=0 ; i < 8  ; i++) begin
            if(Character_Sort[counter1 - 2] == Character[i]) begin
                Priority[i] <= Priority[counter1 - 2];
                Priority[counter1 - 2] <= Priority[i];
            end
        end
    end
    else if(current_state == SORT & (counter1 % 2 == 0)) begin
        for(i=0 ; i < 7 ; i = i + 2) begin
            if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
                Priority[i+1] <= Priority[i];
                Priority[i] <= Priority[i+1];
            end
        end
    end
    else if(current_state == SORT & (counter1 % 2 == 1)) begin
        for(i=1 ; i < 7 ; i = i + 2) begin
            if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
                Priority[i+1] <= Priority[i];
                Priority[i] <= Priority[i+1];
            end
        end
    end
    // else if(current_state == SORT) begin
    //     for(i=0 ; i < 7 ; i++) begin
    //         if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
    //             Priority[i+1] <= Priority[i];
    //             Priority[i] <= Priority[i+1];
    //         end
    //     end
    // end
    else if(current_state == COMBINE & counter1 == 9) begin
        for(i=0 ; i < 8 ; i++) begin
            if(Combine_or_not[i] != 0) begin
                Priority[i] <= new_priority;
            end
        end
    end
    else if(current_state == OUTPUTSORT)begin
        for(i=0 ; i<8 ; i++) begin
            if(counter1 == 0) begin
                if(out_mode_span == 0 & Character[i] == 4) begin
                    Priority[0] <= Priority[i];
                    Priority[i] <= Priority[0];
                end
                else if(out_mode_span == 1 & Character[i] == 4) begin
                    Priority[0] <= Priority[i];
                    Priority[i] <= Priority[0];
                end
            end
            else if(counter1 == 1) begin
                if(out_mode_span == 0 & Character[i] == 5) begin
                    Priority[1] <= Priority[i];
                    Priority[i] <= Priority[1];
                end
                else if(out_mode_span == 1 & Character[i] == 2) begin
                    Priority[1] <= Priority[i];
                    Priority[i] <= Priority[1];
                end
            end
            else if(counter1 == 2) begin
                if(out_mode_span == 0 & Character[i] == 6) begin
                    Priority[2] <= Priority[i];
                    Priority[i] <= Priority[2];
                end
                else if(out_mode_span == 1 & Character[i] == 5) begin
                    Priority[2] <= Priority[i];
                    Priority[i] <= Priority[2];
                end
            end
            else if(counter1 == 3) begin
                if(out_mode_span == 0 & Character[i] == 7) begin
                    Priority[3] <= Priority[i];
                    Priority[i] <= Priority[3];
                end
                else if(out_mode_span == 1 & Character[i] == 0) begin
                    Priority[3] <= Priority[i];
                    Priority[i] <= Priority[3];
                end
            end
            else if(counter1 == 4) begin
                if(out_mode_span == 0 & Character[i] == 3) begin
                    Priority[4] <= Priority[i];
                    Priority[i] <= Priority[4];
                end
                else if(out_mode_span == 1 & Character[i] == 1) begin
                    Priority[4] <= Priority[i];
                    Priority[i] <= Priority[4];
                end
            end
        end
    end
    else begin
        Priority <= Priority;
    end
end



always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Combine_or_not <= 0;
    end
    // else if(current_state == SORTIP & counter1 >= 2 & counter1 <= 8) begin
    //     for(i=0 ; i < 8 ; i++) begin
    //         if(Character[counter1 - 2] == Character_Sort[i]) begin
    //             Combine_or_not[counter1 - 2] <= Combine_or_not[i];
    //             Combine_or_not[i] <= Combine_or_not[counter1 - 2];
    //         end
    //     end
    // end
    // else if(current_state == SORTIP & counter1 == 2) begin
    //     Combine_or_not[0] <= Combine_or_not[Character_Sort[7]];
    //     Combine_or_not[1] <= Combine_or_not[Character_Sort[6]];
    //     Combine_or_not[2] <= Combine_or_not[Character_Sort[5]];
    //     Combine_or_not[3] <= Combine_or_not[Character_Sort[4]];
    //     Combine_or_not[4] <= Combine_or_not[Character_Sort[3]];
    //     Combine_or_not[5] <= Combine_or_not[Character_Sort[2]];
    //     Combine_or_not[6] <= Combine_or_not[Character_Sort[1]];
    //     Combine_or_not[7] <= Combine_or_not[Character_Sort[0]];
    // end
    else if(current_state == SORTIP & counter1 >= 2 & counter1 <= 8) begin
        for(i=0 ; i < 8  ; i++) begin
            if(Character_Sort[counter1 - 2] == Character[i]) begin
                Combine_or_not[i] <= Combine_or_not[counter1 - 2];
                Combine_or_not[counter1 - 2] <= Combine_or_not[i];
            end
        end
    end
    else if(current_state == SORT & (counter1 % 2 == 0)) begin
        for(i=0 ; i < 7 ; i = i + 2) begin
            if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
                Combine_or_not[i+1] <= Combine_or_not[i];
                Combine_or_not[i] <= Combine_or_not[i+1];
            end
        end
    end
    else if(current_state == SORT & (counter1 % 2 == 1)) begin
        for(i=1 ; i < 7 ; i = i + 2) begin
            if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
                Combine_or_not[i+1] <= Combine_or_not[i];
                Combine_or_not[i] <= Combine_or_not[i+1];
            end
        end
    end
    // else if(current_state == SORT) begin
    //     Combine_or_not <= 0;
    //     for(i=0 ; i < 7 ; i++) begin
    //         if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
    //             Combine_or_not[i+1] <= Combine_or_not[i];
    //             Combine_or_not[i] <= Combine_or_not[i+1];
    //         end
    //     end
    // end
    else if(current_state == COMBINE & counter1 == 0) begin 
    Combine_or_not[7] <= 2;
        for(i=0 ; i < 7 ; i++)begin
            if((Priority[i] == Priority[7]) & (Weight[i] == Weight[7]))
                Combine_or_not[i] <= 2; 
        end
    end
    else if(current_state == COMBINE & (counter1 >= 1 & counter1 <= 8)) begin 
        for(i=6 ; i >= 0 ; i--)begin
            if((Priority[i] != Priority[7]) & (Priority[i+1] == Priority[7]) & new_Weight_set == 0)
                Combine_or_not[i] <= 1; 
            else if((Priority[i] != Priority[7]) & (Priority[i] == Priority[i+1]) & (Combine_or_not[i+1] == 1) & new_Weight_set == 1)
                Combine_or_not[i] <= 1;
        end
    end
    else if(current_state == OUTPUTSORT)begin
        for(i=0 ; i<8 ; i++) begin
            if(counter1 == 0) begin
                if(out_mode_span == 0 & Combine_or_not[i] == 4) begin
                    Combine_or_not[0] <= Combine_or_not[i];
                    Combine_or_not[i] <= Combine_or_not[0];
                end
                else if(out_mode_span == 1 & Combine_or_not[i] == 4) begin
                    Combine_or_not[0] <= Combine_or_not[i];
                    Combine_or_not[i] <= Combine_or_not[0];
                end
            end
            else if(counter1 == 1) begin
                if(out_mode_span == 0 & Combine_or_not[i] == 5) begin
                    Combine_or_not[1] <= Combine_or_not[i];
                    Combine_or_not[i] <= Combine_or_not[1];
                end
                else if(out_mode_span == 1 & Combine_or_not[i] == 2) begin
                    Combine_or_not[1] <= Combine_or_not[i];
                    Combine_or_not[i] <= Combine_or_not[1];
                end
            end
            else if(counter1 == 2) begin
                if(out_mode_span == 0 & Combine_or_not[i] == 6) begin
                    Combine_or_not[2] <= Combine_or_not[i];
                    Combine_or_not[i] <= Combine_or_not[2];
                end
                else if(out_mode_span == 1 & Combine_or_not[i] == 5) begin
                    Combine_or_not[2] <= Combine_or_not[i];
                    Combine_or_not[i] <= Combine_or_not[2];
                end
            end
            else if(counter1 == 3) begin
                if(out_mode_span == 0 & Combine_or_not[i] == 7) begin
                    Combine_or_not[3] <= Combine_or_not[i];
                    Combine_or_not[i] <= Combine_or_not[3];
                end
                else if(out_mode_span == 1 & Combine_or_not[i] == 0) begin
                    Combine_or_not[3] <= Combine_or_not[i];
                    Combine_or_not[i] <= Combine_or_not[3];
                end
            end
            else if(counter1 == 4) begin
                if(out_mode_span == 0 & Combine_or_not[i] == 3) begin
                    Combine_or_not[4] <= Combine_or_not[i];
                    Combine_or_not[i] <= Combine_or_not[4];
                end
                else if(out_mode_span == 1 & Combine_or_not[i] == 1) begin
                    Combine_or_not[4] <= Combine_or_not[i];
                    Combine_or_not[i] <= Combine_or_not[4];
                end
            end
        end
    end
    else begin
        Combine_or_not <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Layer <= 0;
    end
    else if(current_state == LOAD) 
        Layer <= 0;
    // else if(current_state == SORTIP & counter1 >= 2 & counter1 <= 8) begin
    //     for(i=0 ; i < 8 ; i++) begin
    //         if(Character[counter1 - 2] == Character_Sort[i]) begin
    //             Layer[counter1 - 2] <= Layer[i];
    //             Layer[i] <= Layer[counter1 - 2];
    //         end
    //     end
    // end
    // else if(current_state == SORTIP & counter1 == 2) begin
    //     Layer[0] <= Layer[Character_Sort[7]];
    //     Layer[1] <= Layer[Character_Sort[6]];
    //     Layer[2] <= Layer[Character_Sort[5]];
    //     Layer[3] <= Layer[Character_Sort[4]];
    //     Layer[4] <= Layer[Character_Sort[3]];
    //     Layer[5] <= Layer[Character_Sort[2]];
    //     Layer[6] <= Layer[Character_Sort[1]];
    //     Layer[7] <= Layer[Character_Sort[0]];
    // end
    else if(current_state == SORTIP & counter1 >= 2 & counter1 <= 8) begin
        for(i=0 ; i < 8  ; i++) begin
            if(Character_Sort[counter1 - 2] == Character[i]) begin
                Layer[i] <= Layer[counter1 - 2];
                Layer[counter1 - 2] <= Layer[i];
            end
        end
    end
    // else if(current_state == SORTIP & counter1 >= 2 & counter1 <= 8) begin
    //     for(i=0 ; i < 8 ; i++) begin
    //         if(Character_Sort[i] == Character[counter1 - 2]) Layer[counter1 - 2] <= Layer[i];
    //     end
    // end
    else if(current_state == SORT & (counter1 % 2 == 0)) begin
        for(i=0 ; i < 7 ; i = i + 2) begin
            if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
                Layer[i+1] <= Layer[i];
                Layer[i] <= Layer[i+1];
            end
        end
    end
    else if(current_state == SORT & (counter1 % 2 == 1)) begin
        for(i=1 ; i < 7 ; i = i + 2) begin
            if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
                Layer[i+1] <= Layer[i];
                Layer[i] <= Layer[i+1];
            end
        end
    end
    // else if(current_state == SORT) begin
    //     for(i=0 ; i < 7 ; i++) begin
    //         if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
    //             Layer[i+1] <= Layer[i];
    //             Layer[i] <= Layer[i+1];
    //         end
    //     end
    // end
    else if(current_state == COMBINE & counter1 == 9) begin
        for(i=0 ; i < 8 ; i++) begin
            if(Combine_or_not[i] != 0) begin
                Layer[i] <= Layer[i] + 1;
            end
        end
    end
    else if(current_state == OUTPUTSORT)begin
        for(i=0 ; i<8 ; i++) begin
            if(counter1 == 0) begin
                if(out_mode_span == 0 & Character[i] == 4) begin
                    Layer[0] <= Layer[i];
                    Layer[i] <= Layer[0];
                end
                else if(out_mode_span == 1 & Character[i] == 4) begin
                    Layer[0] <= Layer[i];
                    Layer[i] <= Layer[0];
                end
            end
            else if(counter1 == 1) begin
                if(out_mode_span == 0 & Character[i] == 5) begin
                    Layer[1] <= Layer[i];
                    Layer[i] <= Layer[1];
                end
                else if(out_mode_span == 1 & Character[i] == 2) begin
                    Layer[1] <= Layer[i];
                    Layer[i] <= Layer[1];
                end
            end
            else if(counter1 == 2) begin
                if(out_mode_span == 0 & Character[i] == 6) begin
                    Layer[2] <= Layer[i];
                    Layer[i] <= Layer[2];
                end
                else if(out_mode_span == 1 & Character[i] == 5) begin
                    Layer[2] <= Layer[i];
                    Layer[i] <= Layer[2];
                end
            end
            else if(counter1 == 3) begin
                if(out_mode_span == 0 & Character[i] == 7) begin
                    Layer[3] <= Layer[i];
                    Layer[i] <= Layer[3];
                end
                else if(out_mode_span == 1 & Character[i] == 0) begin
                    Layer[3] <= Layer[i];
                    Layer[i] <= Layer[3];
                end
            end
            else if(counter1 == 4) begin
                if(out_mode_span == 0 & Character[i] == 3) begin
                    Layer[4] <= Layer[i];
                    Layer[i] <= Layer[4];
                end
                else if(out_mode_span == 1 & Character[i] == 1) begin
                    Layer[4] <= Layer[i];
                    Layer[i] <= Layer[4];
                end
            end
        end
    end
    else begin
        Layer <= Layer;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Path <= 0;
    end
    else if(current_state == LOAD) 
        Path <= 0;
    // else if(current_state == SORTIP & counter1 >= 2 & counter1 <= 8) begin
    //     for(i=0 ; i < 8 ; i++) begin
    //         if(Character[counter1 - 2] == Character_Sort[i]) begin
    //             Path[counter1 - 2] <= Path[i];
    //             Path[i] <= Path[counter1 - 2];
    //         end
    //     end
    // end
    // else if(current_state == SORTIP & counter1 == 2) begin
    //     Path[0] <= Path[Character_Sort[7]];
    //     Path[1] <= Path[Character_Sort[6]];
    //     Path[2] <= Path[Character_Sort[5]];
    //     Path[3] <= Path[Character_Sort[4]];
    //     Path[4] <= Path[Character_Sort[3]];
    //     Path[5] <= Path[Character_Sort[2]];
    //     Path[6] <= Path[Character_Sort[1]];
    //     Path[7] <= Path[Character_Sort[0]];
    // end
    else if(current_state == SORTIP & counter1 >= 2 & counter1 <= 8) begin
        for(i=0 ; i < 8  ; i++) begin
            if(Character_Sort[counter1 - 2] == Character[i]) begin
                Path[i] <= Path[counter1 - 2];
                Path[counter1 - 2] <= Path[i];
            end
        end
    end
    else if(current_state == SORT & (counter1 % 2 == 0)) begin
        for(i=0 ; i < 7 ; i = i + 2) begin
            if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
                Path[i+1] <= Path[i];
                Path[i] <= Path[i+1];
            end
        end
    end
    else if(current_state == SORT & (counter1 % 2 == 1)) begin
        for(i=1 ; i < 7 ; i = i + 2) begin
            if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
                Path[i+1] <= Path[i];
                Path[i] <= Path[i+1];
            end
        end
    end
    // else if(current_state == SORT) begin
    //     for(i=0 ; i < 7 ; i++) begin
    //         if(((Weight[i+1] == Weight[i]) & (Priority[i+1] < Priority[i]))) begin
    //             Path[i+1] <= Path[i];
    //             Path[i] <= Path[i+1];
    //         end
    //     end
    // end
    else if(current_state == COMBINE & counter1 == 9) begin
        for(i=0 ; i < 8 ; i++) begin
            if(Combine_or_not[i] == 1) begin
                Path[i][Layer[i]] <= 0;
            end
            else if(Combine_or_not[i] == 2) begin
                Path[i][Layer[i]] <= 1;
            end
        end
    end
    else if(current_state == OUTPUTSORT)begin
        for(i=0 ; i<8 ; i++) begin
            if(counter1 == 0) begin
                if(out_mode_span == 0 & Character[i] == 4) begin
                    Path[0] <= Path[i];
                    Path[i] <= Path[0];
                end
                else if(out_mode_span == 1 & Character[i] == 4) begin
                    Path[0] <= Path[i];
                    Path[i] <= Path[0];
                end
            end
            else if(counter1 == 1) begin
                if(out_mode_span == 0 & Character[i] == 5) begin
                    Path[1] <= Path[i];
                    Path[i] <= Path[1];
                end
                else if(out_mode_span == 1 & Character[i] == 2) begin
                    Path[1] <= Path[i];
                    Path[i] <= Path[1];
                end
            end
            else if(counter1 == 2) begin
                if(out_mode_span == 0 & Character[i] == 6) begin
                    Path[2] <= Path[i];
                    Path[i] <= Path[2];
                end
                else if(out_mode_span == 1 & Character[i] == 5) begin
                    Path[2] <= Path[i];
                    Path[i] <= Path[2];
                end
            end
            else if(counter1 == 3) begin
                if(out_mode_span == 0 & Character[i] == 7) begin
                    Path[3] <= Path[i];
                    Path[i] <= Path[3];
                end
                else if(out_mode_span == 1 & Character[i] == 0) begin
                    Path[3] <= Path[i];
                    Path[i] <= Path[3];
                end
            end
            else if(counter1 == 4) begin
                if(out_mode_span == 0 & Character[i] == 3) begin
                    Path[4] <= Path[i];
                    Path[i] <= Path[4];
                end
                else if(out_mode_span == 1 & Character[i] == 1) begin
                    Path[4] <= Path[i];
                    Path[i] <= Path[4];
                end
            end
        end
    end
    else begin
        Path <= Path;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else if(current_state == OUTPUT) begin
        out_valid <= 1;
    end
    else begin
        out_valid <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_code <= 0;
        out_cnt_1 <= 0;
        out_cnt_2 <= 0;
    end
    else if(current_state == OUTPUTSORT) begin
        out_cnt_1 <= (Layer[0] - 1);
        out_cnt_2 <= 0;
    end
    else if(current_state == OUTPUT) begin
        if(out_cnt_1 == 0) begin
            out_cnt_1 <= (Layer[out_cnt_2 + 1] - 1);
            out_cnt_2 <= out_cnt_2 + 1;
            //out_cnt_1 <= out_cnt_1 - 1;
            out_code <= Path[out_cnt_2][out_cnt_1];
        end
        else if(out_cnt_1 > 0) begin
            out_cnt_1 <= out_cnt_1 - 1;
            out_code <= Path[out_cnt_2][out_cnt_1];
        end
        else out_code <= 0;
    end
    else begin
        out_code <= 0;
        out_cnt_1 <= 0;
        out_cnt_2 <= 0;
    end
end

SORT_IP SORT_IP(
	.IN_character(IN_character),
    .IN_weight(IN_weight), 
	.OUT_character(OUT_character)
);


endmodule