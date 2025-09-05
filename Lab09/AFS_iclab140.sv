//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2025/4
//		Version		: v1.0
//   	File Name   : AFS.sv
//   	Module Name : AFS
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module AFS(input clk, INF.AFS_inf inf);
import usertype::*;
//================================================================
// Logic 
//================================================================
// logic [63:0] data_reg;
logic [11:0] Rose;
logic [11:0] Lily;
logic [11:0] Carnation;
logic [11:0] Baby_Breath;
logic [11:0] Restock_Rose;
logic [11:0] Restock_Lily;
logic [11:0] Restock_Carnation;
logic [11:0] Restock_Baby_Breath;
logic [11:0] Needing_Rose;
logic [11:0] Needing_Lily;
logic [11:0] Needing_Carnation;
logic [11:0] Needing_Baby_Breath;
logic [7:0]  Month_exp;
logic [7:0]  Date_exp;
logic [3:0]  restock_count;
logic [3:0]  Month;
logic [4:0]  Date;
logic [8:0]  Data_no;
logic [2:0]  Strategy;
logic [1:0]  Mode;
logic [1:0]  prewarn;
logic        rvalid_done;

//======================================
//              FSM
//======================================
State_t current_state, next_state;
always_ff @ ( posedge clk or negedge inf.rst_n) begin //: BEV_FSM_SWITCH
    if (!inf.rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always_comb begin //: BEV_FSM
    case(current_state)
        IDLE: begin
            if(inf.sel_action_valid && inf.D.d_act[0] == Purchase) next_state = PURCHASE;
            else if(inf.sel_action_valid && inf.D.d_act[0] == Restock) next_state = RESTOCK;
            else if(inf.sel_action_valid && inf.D.d_act[0] == Check_Valid_Date) next_state = CHECK_VALID_DATE;
            else next_state = current_state;
        end
        RESTOCK: begin
            if(restock_count == 4 && (rvalid_done || inf.R_VALID)) next_state = CHECK_RESTOCK;
            else next_state = current_state;
        end
        CHECK_VALID_DATE: begin
            if(inf.R_VALID) next_state = CHECK_VALID_DATE_B;
            else next_state = current_state;
        end
        PURCHASE: begin
            if(inf.R_VALID) next_state = PURCHASE_CHECK;
            else next_state = current_state;
        end
        PURCHASE_CHECK: begin
            next_state = PURCHASE_CHECK_B;
        end
        PURCHASE_CHECK_B: begin
            if((Rose < Needing_Rose || Lily < Needing_Lily || Carnation < Needing_Carnation || Baby_Breath < Needing_Baby_Breath)) next_state = OUTPUT;
            else if(Month < Month_exp || (Month == Month_exp && Date < Date_exp)) next_state = OUTPUT;
            else next_state = WRITE_BACK;
        end
        WRITE_BACK: begin
            if(inf.W_READY) next_state = OUTPUT;
            else next_state = current_state;
        end
        CHECK_VALID_DATE_B: begin
            next_state = OUTPUT;
        end
        CHECK_RESTOCK: begin
            next_state = WRITE_BACK;
        end
        OUTPUT : begin
            next_state = IDLE;
        end
        default: next_state = current_state;
    endcase
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin //: BEV_FSM_SWITCH
    if (!inf.rst_n) rvalid_done <= IDLE;
    else if(current_state == IDLE) rvalid_done <= 0;
    else if(inf.R_VALID) rvalid_done <= 1;
    else rvalid_done <= rvalid_done;
end

//================================================================
// DRAM Data Input 
//================================================================

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) Mode <= 0;
    else if (current_state == IDLE) Mode <= 0;
    else if(current_state == PURCHASE && inf.mode_valid && inf.D.d_mode[0] == Single) Mode <= 'd1;
    else if(current_state == PURCHASE && inf.mode_valid && inf.D.d_mode[0] == Group_Order) Mode <= 'd2;
    else if(current_state == PURCHASE && inf.mode_valid && inf.D.d_mode[0] == Event) Mode <= 'd3;
    else Mode <= Mode;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) Strategy <= 0;
    else if (current_state == IDLE) Strategy <= 0;
    else if(current_state == PURCHASE && inf.strategy_valid) Strategy <= inf.D.d_strategy[0];
    else Strategy <= Strategy;
end
parameter Needing_0_0 = 120;
parameter Needing_0_1 = 480;
parameter Needing_0_2 = 960;

parameter Needing_1_0 = 60;
parameter Needing_1_1 = 240;
parameter Needing_1_2 = 480;

parameter Needing_2_0 = 30;
parameter Needing_2_1 = 120;
parameter Needing_2_2 = 240;

//optimization : maybe combinational
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) Needing_Rose <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd0 && Mode == 1) Needing_Rose <= Needing_0_0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd0 && Mode == 2) Needing_Rose <= Needing_0_1;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd0 && Mode == 3) Needing_Rose <= Needing_0_2;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd1) Needing_Rose <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd2) Needing_Rose <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd3) Needing_Rose <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd4 && Mode == 1) Needing_Rose <= Needing_1_0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd4 && Mode == 2) Needing_Rose <= Needing_1_1;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd4 && Mode == 3) Needing_Rose <= Needing_1_2;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd5) Needing_Rose <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd6 && Mode == 1) Needing_Rose <= Needing_1_0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd6 && Mode == 2) Needing_Rose <= Needing_1_1;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd6 && Mode == 3) Needing_Rose <= Needing_1_2;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd7 && Mode == 1) Needing_Rose <= Needing_2_0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd7 && Mode == 2) Needing_Rose <= Needing_2_1;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd7 && Mode == 3) Needing_Rose <= Needing_2_2;
    else Needing_Rose <= Needing_Rose;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) Needing_Lily <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd0) Needing_Lily <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd1 && Mode == 1) Needing_Lily <= Needing_0_0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd1 && Mode == 2) Needing_Lily <= Needing_0_1;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd1 && Mode == 3) Needing_Lily <= Needing_0_2;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd2) Needing_Lily <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd3) Needing_Lily <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd4 && Mode == 1) Needing_Lily <= Needing_1_0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd4 && Mode == 2) Needing_Lily <= Needing_1_1;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd4 && Mode == 3) Needing_Lily <= Needing_1_2;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd5) Needing_Lily <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd6) Needing_Lily <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd7 && Mode == 1) Needing_Lily <= Needing_2_0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd7 && Mode == 2) Needing_Lily <= Needing_2_1;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd7 && Mode == 3) Needing_Lily <= Needing_2_2;
    else Needing_Lily <= Needing_Lily;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) Needing_Carnation <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd0) Needing_Carnation <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd1) Needing_Carnation <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd2 && Mode == 1) Needing_Carnation <= Needing_0_0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd2 && Mode == 2) Needing_Carnation <= Needing_0_1;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd2 && Mode == 3) Needing_Carnation <= Needing_0_2;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd3) Needing_Carnation <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd4) Needing_Carnation <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd5 && Mode == 1) Needing_Carnation <= Needing_1_0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd5 && Mode == 2) Needing_Carnation <= Needing_1_1;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd5 && Mode == 3) Needing_Carnation <= Needing_1_2;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd6 && Mode == 1) Needing_Carnation <= Needing_1_0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd6 && Mode == 2) Needing_Carnation <= Needing_1_1;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd6 && Mode == 3) Needing_Carnation <= Needing_1_2;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd7 && Mode == 1) Needing_Carnation <= Needing_2_0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd7 && Mode == 2) Needing_Carnation <= Needing_2_1;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd7 && Mode == 3) Needing_Carnation <= Needing_2_2;
    else Needing_Carnation <= Needing_Carnation;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) Needing_Baby_Breath <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd0) Needing_Baby_Breath <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd1) Needing_Baby_Breath <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd2) Needing_Baby_Breath <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd3 && Mode == 1) Needing_Baby_Breath <= Needing_0_0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd3 && Mode == 2) Needing_Baby_Breath <= Needing_0_1;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd3 && Mode == 3) Needing_Baby_Breath <= Needing_0_2;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd4) Needing_Baby_Breath <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd5 && Mode == 1) Needing_Baby_Breath <= Needing_1_0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd5 && Mode == 2) Needing_Baby_Breath <= Needing_1_1;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd5 && Mode == 3) Needing_Baby_Breath <= Needing_1_2;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd6) Needing_Baby_Breath <= 0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd7 && Mode == 1) Needing_Baby_Breath <= Needing_2_0;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd7 && Mode == 2) Needing_Baby_Breath <= Needing_2_1;
    else if(current_state == PURCHASE_CHECK && Strategy == 3'd7 && Mode == 3) Needing_Baby_Breath <= Needing_2_2;
    else Needing_Baby_Breath <= Needing_Baby_Breath;
end
//optimization : maybe combinational

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) Date <= 0;
    else if(inf.date_valid) Date <= inf.D.d_date[0].D[4:0];
    else Date <= Date ;
end
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) Month <= 0;
    else if(inf.date_valid) Month <= inf.D.d_date[0].M[3:0];
    else Month <= Month ;
end
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) Data_no <= 0;
    else if(inf.data_no_valid) Data_no <= inf.D.d_data_no[0];
    else Data_no <= Data_no;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) Rose <= 0;
	else if (inf.R_VALID) Rose <= inf.R_DATA[63:52];
    else if(current_state == CHECK_RESTOCK && ((Restock_Rose + Rose) <= 'd4095)) Rose <= Restock_Rose + Rose;
    else if(current_state == CHECK_RESTOCK && ((Restock_Rose + Rose) > 'd4095)) Rose <= 'd4095;
    else if(current_state == PURCHASE_CHECK_B && !(Rose < Needing_Rose || Lily < Needing_Lily || Carnation < Needing_Carnation || Baby_Breath < Needing_Baby_Breath)) Rose <= Rose - Needing_Rose;
	else Rose <= Rose;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) Lily <= 0;
	else if (inf.R_VALID) Lily <= inf.R_DATA[51:40];
    else if(current_state == CHECK_RESTOCK && ((Restock_Lily + Lily) <= 'd4095)) Lily <= Restock_Lily + Lily;
    else if(current_state == CHECK_RESTOCK && ((Restock_Lily + Lily) > 'd4095)) Lily <= 'd4095;
    else if(current_state == PURCHASE_CHECK_B && !(Rose < Needing_Rose || Lily < Needing_Lily || Carnation < Needing_Carnation || Baby_Breath < Needing_Baby_Breath)) Lily <= Lily - Needing_Lily;
	else Lily <= Lily;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) Carnation <= 0;
	else if (inf.R_VALID) Carnation <= inf.R_DATA[31:20];
    else if(current_state == CHECK_RESTOCK && ((Restock_Carnation + Carnation) <= 'd4095)) Carnation <= Restock_Carnation + Carnation;
    else if(current_state == CHECK_RESTOCK && ((Restock_Carnation + Carnation) > 'd4095)) Carnation <= 'd4095;
    else if(current_state == PURCHASE_CHECK_B && !(Rose < Needing_Rose || Lily < Needing_Lily || Carnation < Needing_Carnation || Baby_Breath < Needing_Baby_Breath)) Carnation <= Carnation - Needing_Carnation;
	else Carnation <= Carnation;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) Baby_Breath <= 0;
	else if (inf.R_VALID) Baby_Breath <= inf.R_DATA[19:8];
    else if(current_state == CHECK_RESTOCK && ((Restock_Baby_Breath + Baby_Breath) <= 'd4095)) Baby_Breath <= Restock_Baby_Breath + Baby_Breath;
    else if(current_state == CHECK_RESTOCK && ((Restock_Baby_Breath + Baby_Breath) > 'd4095)) Baby_Breath <= 'd4095;
    else if(current_state == PURCHASE_CHECK_B && !(Rose < Needing_Rose || Lily < Needing_Lily || Carnation < Needing_Carnation || Baby_Breath < Needing_Baby_Breath)) Baby_Breath <= Baby_Breath - Needing_Baby_Breath;
	else Baby_Breath <= Baby_Breath;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) Restock_Rose <= 0;
	else if (current_state == RESTOCK && inf.restock_valid && restock_count == 0) Restock_Rose <= inf.D.d_stock[0];
	else Restock_Rose <= Restock_Rose;
end
always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) Restock_Lily <= 0;
	else if (current_state == RESTOCK && inf.restock_valid && restock_count == 1) Restock_Lily <= inf.D.d_stock[0];
	else Restock_Lily <= Restock_Lily;
end
always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) Restock_Carnation <= 0;
	else if (current_state == RESTOCK && inf.restock_valid && restock_count == 2) Restock_Carnation <= inf.D.d_stock[0];
	else Restock_Carnation <= Restock_Carnation;
end
always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) Restock_Baby_Breath <= 0;
	else if (current_state == RESTOCK && inf.restock_valid && restock_count == 3) Restock_Baby_Breath <= inf.D.d_stock[0];
	else Restock_Baby_Breath <= Restock_Baby_Breath;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) Month_exp <= 0;
	else if (inf.R_VALID) Month_exp <= inf.R_DATA[39:32];
    else if (current_state == CHECK_RESTOCK) Month_exp <= Month;
	else Month_exp <= Month_exp;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) Date_exp <= 0;
	else if (inf.R_VALID) Date_exp <= inf.R_DATA[7:0];
    else if (current_state == CHECK_RESTOCK) Date_exp <= Date;
	else Date_exp <= Date_exp;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) restock_count <= 0;
    else if (current_state == IDLE) restock_count <= 0;
    else if(current_state == RESTOCK && inf.restock_valid) restock_count <= restock_count + 1;
    else restock_count <= restock_count;
end


//================================================================
// AXI 
//================================================================
//(1)Read Address 
logic no_valid_in;
always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) no_valid_in <= 0;
    else if (current_state == IDLE) no_valid_in <= 0;
    else if(inf.AR_VALID) no_valid_in <= 0;
    else if(inf.data_no_valid) no_valid_in <= 1;
    else no_valid_in <= no_valid_in;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) inf.AR_VALID <= 0;
    else if(no_valid_in && inf.B_READY == 0) inf.AR_VALID <= 1;
    // else if (inf.AR_VALID) inf.AR_VALID <= 0;
    else inf.AR_VALID <= 0;
end

always_comb begin : AR_ADDR
	if(!inf.rst_n) inf.AR_ADDR = 0;
	else inf.AR_ADDR = 65536 + ({9'd0, (Data_no)} << 3);
end

//(2)Read Data
always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) inf.R_READY <= 0;
    else if (inf.AR_VALID) inf.R_READY <= 1 ;
	else if (inf.R_VALID) inf.R_READY <= 0 ;
	else inf.R_READY <= inf.R_READY;
end

//(3)Write Address 
logic AW_VALID_DOWN;
always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) AW_VALID_DOWN <= 0;
    else if(current_state == IDLE) AW_VALID_DOWN <= 0;
    else if (current_state == WRITE_BACK && inf.AW_VALID) AW_VALID_DOWN <= 1;
    else AW_VALID_DOWN <= AW_VALID_DOWN;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) inf.AW_VALID <= 0;
    else if (current_state == WRITE_BACK && !AW_VALID_DOWN) inf.AW_VALID <= 1;
    else inf.AW_VALID <= 0;
end

always_comb begin : AW_ADDR
    if(!inf.rst_n) inf.AW_ADDR = 0;
	else inf.AW_ADDR = 65536 + ({9'd0, (Data_no)} << 3);
end

//(4)Write Data
always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) inf.W_VALID <= 0;
    else if (inf.AW_READY) inf.W_VALID <= 1 ;
	else inf.W_VALID <= 0;
end

always_comb begin : W_DATA
	if(!inf.rst_n) inf.W_DATA = 0;
	else inf.W_DATA = {Rose, Lily, Month_exp, Carnation, Baby_Breath, Date_exp};
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) inf.B_READY <= 0;
    else if (inf.W_VALID) inf.B_READY <= 1 ;
	else if (inf.B_VALID) inf.B_READY <= 0 ;
	else inf.B_READY <= inf.B_READY;
end

//================================================================
// Output
//================================================================
always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) prewarn <= No_Warn;
    else if (current_state == IDLE) prewarn <= No_Warn;
    else if(current_state == CHECK_VALID_DATE_B && (Month < Month_exp || (Month == Month_exp && Date < Date_exp))) prewarn <= Date_Warn;
    else if(current_state == PURCHASE_CHECK_B && (Month < Month_exp || (Month == Month_exp && Date < Date_exp))) prewarn <= Date_Warn;
    else if(current_state == PURCHASE_CHECK_B && (Rose < Needing_Rose || Lily < Needing_Lily || Carnation < Needing_Carnation || Baby_Breath < Needing_Baby_Breath)) prewarn <= Stock_Warn;
    else if(current_state == CHECK_RESTOCK && (Restock_Rose + Rose > 'd4095)) prewarn <= Restock_Warn;
    else if(current_state == CHECK_RESTOCK && (Restock_Lily + Lily > 'd4095)) prewarn <= Restock_Warn;
    else if(current_state == CHECK_RESTOCK && (Restock_Carnation + Carnation > 'd4095)) prewarn <= Restock_Warn;
    else if(current_state == CHECK_RESTOCK && (Restock_Baby_Breath + Baby_Breath > 'd4095)) prewarn <= Restock_Warn;
    else prewarn <= prewarn;
end

always_comb begin
	if(!inf.rst_n) inf.out_valid = 0;
    else if(current_state == OUTPUT) inf.out_valid = 1;
	else inf.out_valid = 0;
end

always_comb begin
    if (!inf.rst_n) inf.complete = 0;
    else if(current_state == OUTPUT && prewarn != No_Warn) inf.complete = 0;
    else if(current_state == OUTPUT && prewarn == No_Warn) inf.complete = 1;
    else inf.complete = 0;
end
       
always_comb begin
    if (!inf.rst_n) inf.warn_msg  = No_Warn;
    else if(inf.out_valid == 1) inf.warn_msg = prewarn;
    else inf.warn_msg = No_Warn;
end

endmodule



