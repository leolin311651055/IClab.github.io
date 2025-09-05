/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2025 Spring IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: May-2025)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/
`ifdef RTL
    `define CYCLE_TIME 2.5
`endif
`ifdef GATE
    `define CYCLE_TIME 2.5
`endif
`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;
real CYCLE = `CYCLE_TIME;
// integer fp_w;

// initial begin
// fp_w = $fopen("out_valid.txt", "w");
// end

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */

class Strategy_and_mode;
    Strategy_Type f_type;
    Mode f_mode;
endclass

Strategy_and_mode fm_info = new();

Action actions ;
always_ff @ (posedge clk or negedge inf.rst_n) begin  
	if (!inf.rst_n) actions = Purchase ;
	else begin 
		if (inf.sel_action_valid)
			actions = inf.D.d_act[0] ;
	end
end

logic [2:0] counter ;

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) begin 
		counter <= 0 ;
	end
	else begin 
		if (inf.restock_valid) counter <= counter + 1 ;
		else if (counter == 4) counter <= 0 ;
	end
end


/*
    1.Each case of Strategy_Type should be select at least 100 times. 
*/
covergroup Spec1 @(posedge clk iff(inf.strategy_valid));
    option.per_instance = 1;
    option.at_least = 100;
    btype:coverpoint inf.D.d_strategy[0] {
        bins b_Strategy [] = {[Strategy_A:Strategy_H]};
    } 
endgroup

Spec1 spec1_inst = new() ;

/*
    2. Each case of Mode should be select at least 100 times.
*/
covergroup Spec2 @(posedge clk iff(inf.mode_valid));
    option.per_instance = 1;
    option.at_least = 100;
    bsize : coverpoint inf.D.d_mode[0] {
        bins b_mode [] = {[Single:Event]} ;
    }
endgroup

Spec2 spec2_inst = new() ;

/*
    3. Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 100 
       times. (Strategy_A,B,C,D,E,F,G,H) x (Single, Group_Order, Event)
*/

Strategy_Type type_span ;
always_ff @ (posedge clk or negedge inf.rst_n) begin  
	if (!inf.rst_n) type_span = Strategy_A ;
	else if (inf.strategy_valid) begin
			type_span = inf.D.d_strategy[0] ;
	end
end

covergroup Spec3 @(posedge clk iff(inf.mode_valid));
    option.per_instance = 1;
    option.at_least = 100;

    strategy_cp : coverpoint type_span {
        bins strategy_bins[] = {[Strategy_A:Strategy_H]};
    }

    mode_cp : coverpoint inf.D.d_mode[0] {
        bins mode_bins[] = {[Single:Event]};
    }

    cross_strategy_mode : cross strategy_cp, mode_cp;
endgroup

Spec3 spec3_inst = new();

// covergroup Spec3 @(negedge clk iff(inf.mode_valid));
//     option.per_instance = 1;
//     option.at_least = 100;
//     coverpoint fm_info.f_type{
//         bins b_Strategy [] = {[Strategy_A:Strategy_H]};
//     }
//     coverpoint fm_info.f_mode{
//         bins b_mode [] = {[Single:Event]};
//     }
// 	cross fm_info.f_mode, fm_info.f_type;
// endgroup

// Spec3 spec3_inst = new() ;


/*
    4. Output signal inf.warn_msg should be“No_Warn”,“Date_Warn”,“Stock_Warn“,”Restock_Warn”, 
       each at least 10 times. (Sample the value when inf.out_valid is high) 
*/
covergroup Spec4 @(negedge clk iff(inf.out_valid));
    option.per_instance = 1;
    option.at_least = 10;
	out : coverpoint inf.warn_msg {
		bins error_msg [] = {[No_Warn:Restock_Warn]} ;
	}
endgroup

Spec4 spec4_inst = new() ;


/*
    5. Create the transitions bin for the inf.D.act[0] signal from [Purchase:Check_Valid_Date] to 
       [Purchase:Check_Valid_Date]. Each transition should be hit at least 300 times. (sample the value 
       at posedge clk iff inf.sel_action_valid) 
*/
covergroup Spec5 @(posedge clk iff(inf.sel_action_valid));
    option.per_instance = 1 ;
    option.at_least = 300 ;
	act : coverpoint inf.D.d_act[0] {
		bins a_act [] = ([Purchase:Check_Valid_Date] => [Purchase:Check_Valid_Date]) ;
	}
endgroup

Spec5 spec5_inst = new() ;


/*
    6.  Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to 
        hit at least one time.
*/
covergroup Spec6 @(posedge clk iff(inf.restock_valid));
    option.per_instance = 1 ;
    option.at_least = 1 ;
	input_ing : coverpoint inf.D.d_stock[0] {
		option.auto_bin_max = 32;
	}
endgroup

Spec6 spec6_inst = new() ;


always @ (negedge inf.rst_n) begin 
	#(CYCLE / 2) ;
	Assertion1 : assert (inf.out_valid === 0 && inf.warn_msg === 0 && inf.complete === 0 
    && inf.AR_VALID === 0 && inf.AR_ADDR === 0 &&inf.R_READY === 0 
    && inf.AW_VALID === 0 && inf.AW_ADDR === 0 && inf.W_VALID === 0 
    && inf.W_DATA === 0 && inf.B_READY === 0) 
    else begin 
        $display("==========================================================================") ;
        $display("                       Assertion 1 is violated                            ") ;			
        $display("==========================================================================") ;
        $fatal ;
    end
end


/*
    2.Latency should be less than 1000 cycles for each operation. 
*/

always @ (posedge clk) begin
    Asseration2_0 : assert property (@(negedge clk) (actions === 'd0 && inf.data_no_valid === 'b1) |-> (##[1:1000] inf.out_valid))
    else begin
        $display("==========================================================================") ;
        $display("                       Assertion 2 is violated                            ") ;			
        $display("==========================================================================") ;
        $fatal ;
    end
    Asseration2_1 : assert property (@(negedge clk) (actions === 'd1 && inf.restock_valid === 'b1) |-> (##[1:1000] inf.out_valid))
    else begin
        $display("==========================================================================") ;
        $display("                       Assertion 2 is violated                            ") ;			
        $display("==========================================================================") ;
        $fatal ;
    end
    Asseration2_2 : assert property (@(negedge clk) (actions === 'd2 && inf.data_no_valid === 'b1) |-> (##[1:1000] inf.out_valid))
    else begin
        $display("==========================================================================") ;
        $display("                       Assertion 2 is violated                            ") ;			
        $display("==========================================================================") ;
        $fatal ;
    end
end

/*
    3.If action is completed (complete=1), warn_msg should be 2’b0 (No_Warn)
*/
always@(posedge clk) begin
	Assertion3 : assert property (@(negedge clk) (inf.complete |-> inf.warn_msg === No_Warn))
    else begin 
        $display("==========================================================================") ;
        $display("                      Assertion 3 is violated                             ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
end


/*
    4.	Next input valid will be valid 1-4 cycles after previous input valid fall
*/
always@(posedge clk) begin
    Asseration4_0 : assert property (@(negedge clk) (inf.sel_action_valid === 1) |-> ((##[1:4] (inf.strategy_valid === 1 || inf.date_valid === 1))))
    else begin
        $display("==========================================================================") ;
        $display("                       Assertion 4 is violated                             ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
    Asseration4_1 : assert property (@(negedge clk) (actions === 2'h0 && inf.strategy_valid === 1) |-> (##[1:4] (inf.mode_valid === 1)))
    else begin
        $display("==========================================================================") ;
        $display("                       Assertion 4 is violated                             ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
    Asseration4_2 : assert property (@(negedge clk) (actions === 2'h0 && inf.mode_valid === 1) |-> (##[1:4] (inf.date_valid === 1)))
    else begin
        $display("==========================================================================") ;
        $display("                       Assertion 4 is violated                             ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
    Asseration4_3 : assert property (@(negedge clk) (inf.date_valid === 1) |-> (##[1:4] (inf.data_no_valid === 1)))
    else begin
        $display("==========================================================================") ;
        $display("                       Assertion 4 is violated                             ") ;
        $display("==========================================================================") ;
        $fatal ;
    end

    Asseration4_4 : assert property (@(negedge clk) (actions === 2'h1 && inf.data_no_valid === 1) |-> (##[1:4] (inf.restock_valid === 1)))
    else begin
        $display("==========================================================================") ;
        $display("                       Assertion 4 is violated                             ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
    Asseration4_5 : assert property (@(negedge clk) (actions === 2'h1 && counter < 4 && inf.restock_valid === 1) |-> (##[1:4] (inf.restock_valid === 1)))
    else begin
        $display("==========================================================================") ;
        $display("                       Assertion 4 is violated                             ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
end
/*
    5.All input valid signals won’t overlap with each other. 	
*/

always@(posedge clk) begin 
	Asseration5_0 : assert property (@(negedge clk) inf.sel_action_valid |-> ((inf.strategy_valid || inf.mode_valid || inf.date_valid || inf.data_no_valid || inf.restock_valid) == 0))
    else begin 
        $display("==========================================================================") ;
        $display("                        Assertion 5 is violated                           ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
	Asseration5_1   : assert property (@(negedge clk) inf.strategy_valid |-> ((inf.sel_action_valid || inf.mode_valid || inf.date_valid || inf.data_no_valid || inf.restock_valid) == 0))
    else begin 
        $display("==========================================================================") ;
        $display("                        Assertion 5 is violated                           ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
	Asseration5_2   : assert property (@(negedge clk) inf.mode_valid |-> ((inf.sel_action_valid || inf.strategy_valid || inf.date_valid || inf.data_no_valid || inf.restock_valid) == 0))
    else begin 
        $display("==========================================================================") ;
        $display("                        Assertion 5 is violated                           ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
	Asseration5_3   : assert property (@(negedge clk) inf.date_valid |-> ((inf.sel_action_valid || inf.strategy_valid || inf.mode_valid || inf.data_no_valid || inf.restock_valid) == 0))
    else begin 
        $display("==========================================================================") ;
        $display("                        Assertion 5 is violated                           ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
	Asseration5_4  : assert property (@(negedge clk) inf.data_no_valid |-> ((inf.sel_action_valid || inf.strategy_valid || inf.mode_valid || inf.date_valid || inf.restock_valid) == 0))
    else begin 
        $display("==========================================================================") ;
        $display("                        Assertion 5 is violated                           ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
	Asseration5_5 : assert property (@(negedge clk) inf.restock_valid |-> ((inf.sel_action_valid || inf.strategy_valid || inf.mode_valid || inf.date_valid || inf.data_no_valid) == 0))
    else begin 
        $display("==========================================================================") ;
        $display("                        Assertion 5 is violated                           ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
end


/*
    6. Out_valid can only be high for exactly one cycle.
*/
always @ (posedge clk)
	Asseration6 : assert property (@ (negedge clk) inf.out_valid |-> (##1 (inf.out_valid == 0)))
    else begin 
        $display("==========================================================================") ;
        $display("                        Assertion 6 is violated                           ") ;
        $display("==========================================================================") ;
        $fatal ;
    end

/*
    7. Next operation will be valid 1-4 cycles after out_valid fall.
*/
always @ (posedge clk)
	Asseration7 : assert property (@(negedge clk) (inf.out_valid) |-> ##[2:5] (inf.sel_action_valid))
else begin
    $display("==========================================================================") ;
    $display("                        Assertion 7 is violated                           ") ;
    $display("==========================================================================") ;
    $fatal ;
end

/*
    8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
*/
always @ (posedge clk) begin
	Asseration8_0 : assert property (@ (negedge clk) inf.date_valid |-> (inf.D.d_date[0].M <= 12 && inf.D.d_date[0].M >= 1))
    else begin 
        $display("==========================================================================") ;
        $display("                        Assertion 8 is violated                           ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
	Asseration8_1 : assert property (@ (negedge clk) (inf.date_valid && (inf.D.d_date[0].M == 1 || inf.D.d_date[0].M == 3 || inf.D.d_date[0].M == 5 || inf.D.d_date[0].M == 7 || inf.D.d_date[0].M == 8 || inf.D.d_date[0].M == 10 || inf.D.d_date[0].M == 12)) |-> (inf.D.d_date[0].D <= 31 && inf.D.d_date[0].D >= 1))
    else begin 
        $display("==========================================================================") ;
        $display("                        Assertion 8 is violated                           ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
	Asseration8_2 : assert property (@ (negedge clk) (inf.date_valid && (inf.D.d_date[0].M == 4 || inf.D.d_date[0].M == 6 || inf.D.d_date[0].M == 9 || inf.D.d_date[0].M == 11)) |-> (inf.D.d_date[0].D <= 30 && inf.D.d_date[0].D >= 1))
    else begin 
        $display("==========================================================================") ;
        $display("                        Assertion 8 is violated                           ") ;
        $display("==========================================================================") ;
        $fatal ;
    end					
	Asseration8_3 : assert property (@ (negedge clk) (inf.date_valid && (inf.D.d_date[0].M == 2)) |-> (inf.D.d_date[0].D <= 28 && inf.D.d_date[0].D >= 1))
    else begin 
        $display("==========================================================================") ;
        $display("                        Assertion 8 is violated                           ") ;
        $display("==========================================================================") ;
        $fatal ;
    end
end

/*
    9. The AR_VALID signal should not overlap with the AW_VALID signal.
*/
always @ (posedge clk) begin 
	Asseration9_0 : assert property (@ (negedge clk) inf.AR_VALID |-> (inf.AW_VALID == 0))
    else begin 
        $display("==========================================================================") ;
        $display("                        Assertion 9 is violated                           ") ;
        $display("==========================================================================") ;
        $fatal ;
    end			
    Asseration9_1 : assert property (@ (negedge clk) inf.AW_VALID |-> (inf.AR_VALID == 0))
    else begin 
        $display("==========================================================================") ;
        $display("                        Assertion 9 is violated                           ") ;
        $display("==========================================================================") ;
        $fatal ;
    end					
end

endmodule