//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : SORT_IP.v
//   	Module Name : SORT_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module SORT_IP #(parameter IP_WIDTH = 8) (
    // Input signals
    IN_character, IN_weight,
    // Output signals
    OUT_character
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*4-1:0]  IN_character;//[31:0] //[3:0] [7:4] [11:8] [15:12] [19:16] [23:20] [27:24] [31:28]
input [IP_WIDTH*5-1:0]  IN_weight;//[39:0] //[4:0] [9:5] [14:10] [19:15] [24:20] [29:25] [34:30] [39:35]

output [IP_WIDTH*4-1:0] OUT_character;//[31:0]

// ===============================================================
// Design
// ===============================================================

wire [3:0] Input_Character [0:7] ;
wire [4:0] Input_Weight [0:7] ;
wire [3:0] Character [8:37] ;
wire [4:0] Weight [8:37] ;
wire [3:0] Output_Character [0:7] ;
wire [4:0] Output_Weight [0:7] ;


genvar i ;
generate 
	for (i = 0 ; i < 8 ; i  = i + 1) begin 
		assign OUT_character[(IP_WIDTH-i)*4-1 -: 4] = Output_Character[i] ;
	end
endgenerate

assign Input_Weight[0] = IN_weight[4:0];
assign Input_Weight[1] = IN_weight[9:5];
assign Input_Weight[2] = IN_weight[14:10];
assign Input_Weight[3] = IN_weight[19:15];
assign Input_Weight[4] = IN_weight[24:20];
assign Input_Weight[5] = IN_weight[29:25];
assign Input_Weight[6] = IN_weight[34:30];
assign Input_Weight[7] = IN_weight[39:35];

assign Input_Character[0] = IN_character[3:0];
assign Input_Character[1] = IN_character[7:4];
assign Input_Character[2] = IN_character[11:8];
assign Input_Character[3] = IN_character[15:12];
assign Input_Character[4] = IN_character[19:16];
assign Input_Character[5] = IN_character[23:20];
assign Input_Character[6] = IN_character[27:24];
assign Input_Character[7] = IN_character[31:28];



SORT SORT0  (.char_in0(Input_Character[0]),  .char_in1(Input_Character[1]), .Weig_in0(Input_Weight[0]), .Weig_in1(Input_Weight[1]), .Char_larger(Character[30]), .Char_smaller(Character[31]), .Weight_biger(Weight[30]), .Weight_smaller(Weight[31])) ;
SORT SORT1  (.char_in0(Input_Character[2]),  .char_in1(Input_Character[3]), .Weig_in0(Input_Weight[2]), .Weig_in1(Input_Weight[3]), .Char_larger(Character[32]), .Char_smaller(Character[33]), .Weight_biger(Weight[32]), .Weight_smaller(Weight[33])) ;
SORT SORT2  (.char_in0(Input_Character[4]),  .char_in1(Input_Character[5]), .Weig_in0(Input_Weight[4]), .Weig_in1(Input_Weight[5]), .Char_larger(Character[34]), .Char_smaller(Character[35]), .Weight_biger(Weight[34]), .Weight_smaller(Weight[35])) ;
SORT SORT3  (.char_in0(Input_Character[6]),  .char_in1(Input_Character[7]), .Weig_in0(Input_Weight[6]), .Weig_in1(Input_Weight[7]), .Char_larger(Character[36]), .Char_smaller(Character[37]), .Weight_biger(Weight[36]), .Weight_smaller(Weight[37])) ;
SORT SORT4  (.char_in0(Character[30]),       .char_in1(Character[32]),      .Weig_in0(Weight[30]),      .Weig_in1(Weight[32]),      .Char_larger(Character[22]), .Char_smaller(Character[23]), .Weight_biger(Weight[22]), .Weight_smaller(Weight[23])) ;
SORT SORT5  (.char_in0(Character[31]),       .char_in1(Character[33]),      .Weig_in0(Weight[31]),      .Weig_in1(Weight[33]),      .Char_larger(Character[24]), .Char_smaller(Character[25]), .Weight_biger(Weight[24]), .Weight_smaller(Weight[25])) ;
SORT SORT6  (.char_in0(Character[34]),       .char_in1(Character[36]),      .Weig_in0(Weight[34]),      .Weig_in1(Weight[36]),      .Char_larger(Character[26]), .Char_smaller(Character[27]), .Weight_biger(Weight[26]), .Weight_smaller(Weight[27])) ;
SORT SORT7  (.char_in0(Character[35]),       .char_in1(Character[37]),      .Weig_in0(Weight[35]),      .Weig_in1(Weight[37]),      .Char_larger(Character[28]), .Char_smaller(Character[29]), .Weight_biger(Weight[28]), .Weight_smaller(Weight[29])) ;
SORT SORT8  (.char_in0(Character[22]),       .char_in1(Character[26]),      .Weig_in0(Weight[22]),      .Weig_in1(Weight[26]),      .Char_larger(Output_Character[0]),  .Char_smaller(Character[16]), .Weight_biger(Output_Weight[0]),  .Weight_smaller(Weight[16])) ;
SORT SORT9  (.char_in0(Character[23]),       .char_in1(Character[24]),      .Weig_in0(Weight[23]),      .Weig_in1(Weight[24]),      .Char_larger(Character[17]), .Char_smaller(Character[18]), .Weight_biger(Weight[17]), .Weight_smaller(Weight[18])) ;
SORT SORT10 (.char_in0(Character[27]),      .char_in1(Character[28]),       .Weig_in0(Weight[27]),      .Weig_in1(Weight[28]),      .Char_larger(Character[19]), .Char_smaller(Character[20]), .Weight_biger(Weight[19]), .Weight_smaller(Weight[20])) ;
SORT SORT11 (.char_in0(Character[25]),      .char_in1(Character[29]),       .Weig_in0(Weight[25]),      .Weig_in1(Weight[29]),      .Char_larger(Character[21]), .Char_smaller(Output_Character[7]),  .Weight_biger(Weight[21]), .Weight_smaller(Output_Weight[7])) ;
SORT SORT12 (.char_in0(Character[18]),      .char_in1(Character[20]),       .Weig_in0(Weight[18]),      .Weig_in1(Weight[20]),      .Char_larger(Character[12]), .Char_smaller(Character[13]), .Weight_biger(Weight[12]), .Weight_smaller(Weight[13])) ;
SORT SORT13 (.char_in0(Character[17]),      .char_in1(Character[19]),       .Weig_in0(Weight[17]),      .Weig_in1(Weight[19]),      .Char_larger(Character[14]), .Char_smaller(Character[15]), .Weight_biger(Weight[14]), .Weight_smaller(Weight[15])) ;
SORT SORT14 (.char_in0(Character[16]),      .char_in1(Character[12]),       .Weig_in0(Weight[16]),      .Weig_in1(Weight[12]),      .Char_larger(Character[8]),  .Char_smaller(Character[9]),  .Weight_biger(Weight[8]),  .Weight_smaller(Weight[9])) ;
SORT SORT15 (.char_in0(Character[15]),      .char_in1(Character[21]),       .Weig_in0(Weight[15]),      .Weig_in1(Weight[21]),      .Char_larger(Character[10]), .Char_smaller(Character[11]), .Weight_biger(Weight[10]), .Weight_smaller(Weight[11])) ;
SORT SORT16 (.char_in0(Character[8]),       .char_in1(Character[14]),       .Weig_in0(Weight[8]),       .Weig_in1(Weight[14]),      .Char_larger(Output_Character[1]),  .Char_smaller(Output_Character[2]),  .Weight_biger(Output_Weight[1]),  .Weight_smaller(Output_Weight[2])) ;
SORT SORT17 (.char_in0(Character[9]),       .char_in1(Character[10]),       .Weig_in0(Weight[9]),       .Weig_in1(Weight[10]),      .Char_larger(Output_Character[3]),  .Char_smaller(Output_Character[4]),  .Weight_biger(Output_Weight[3]),  .Weight_smaller(Output_Weight[4])) ;
SORT SORT18 (.char_in0(Character[13]),      .char_in1(Character[11]),       .Weig_in0(Weight[13]),      .Weig_in1(Weight[11]),      .Char_larger(Output_Character[5]),  .Char_smaller(Output_Character[6]),  .Weight_biger(Output_Weight[5]),  .Weight_smaller(Output_Weight[6])) ;
endmodule

module SORT (
    input [3:0] char_in0, char_in1,
    input [4:0] Weig_in0, Weig_in1,
    output wire[3:0] Char_larger, Char_smaller,
    output wire[4:0] Weight_biger, Weight_smaller
);

wire is_bigger;

assign is_bigger = (Weig_in0 > Weig_in1) || ((Weig_in0 == Weig_in1) && (char_in0 > char_in1));

assign Char_larger     = is_bigger ? char_in0 : char_in1;
assign Weight_biger    = is_bigger ? Weig_in0 : Weig_in1;
assign Char_smaller    = is_bigger ? char_in1 : char_in0;
assign Weight_smaller  = is_bigger ? Weig_in1 : Weig_in0;

endmodule





