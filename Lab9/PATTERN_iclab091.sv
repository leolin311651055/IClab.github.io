/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype_BEV.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter PAT_NUM = 15000 ;
parameter LIMIT_LAT = 1000 ;
parameter OUT_NUM = 1 ;
//parameter ACTION_SEED = 48756 ;
parameter TYPE_SEED   = 48756 ;
parameter SIZE_SEED   = 48756 ;
parameter DATE_SEED   = 48756 ;
//parameter BOXID_SEED  = 45879 ;
parameter INGFR_SEED  = 48812 ;
parameter INGRA_SEED  = 47849 ;

integer SEED        = 1253761253 ;
integer CYCLE_SEED  = 48756 ;
integer i_pat ;
//integer catch ;
integer exe_lat ;
integer out_lat ;
integer i, j, latency, total_latency, t;
//================================================================
// wire & registers 
//================================================================
logic [11:0] supply_black;
logic [11:0] supply_green;
logic [11:0] supply_milk;
logic [11:0] supply_pineapple;
logic [1:0]  golden_err_msg;
logic golden_complete;
logic [12:0] golden_black;
logic [12:0] golden_green;
logic [12:0] golden_milk;
logic [12:0] golden_pineapple;
logic [12:0] golden_month;
logic [12:0] golden_day;
logic [11:0] golden_black_need;
logic [11:0] golden_green_need;
logic [11:0] golden_milk_need;
logic [11:0] golden_pineapple_need;
logic [10:0] count ;
Date date,today;
logic [7:0]  golden_DRAM [((65536+8*256)-1):(65536+0)];  // 256 box
logic [63:0] barrel_data ;
logic no_pass_expired, enough_ing, bt_overflow, gt_overflow, milk_overflow, pine_overflow ;
logic pattern_complete ;
logic [11:0] need_bt, need_gt, need_milk, need_pine ;
logic [20:0] global_count ;
Error_Msg pattern_err_msg ;

//================================================================
// class random
//================================================================

// input action
// class random_act ;
// 	randc  Action act_id ;
// 	function new (int seed) ;
// 		this.srandom(seed) ;
// 	endfunction
// 	constraint range {
// 		act_id inside {[1:14]} ;
// 	}
// endclass
class random_act;
    randc Action act_id;
    constraint range{
        act_id inside{Make_drink, Supply, Check_Valid_Date};
    }
endclass
//logic [3:0] action_num ;
Action input_action ;


// input Box No.
class random_box ;
	randc Barrel_No box_id ;
	// function new (int seed) ;
	// 	this.srandom(seed) ;
	// endfunction
	constraint range {
		box_id inside {[0:255]} ;
	}
endclass


class random_bev;
    randc Bev_Type bev;
    constraint range{
        bev inside{ Black_Tea      	         ,
                    Milk_Tea	             ,
                    Extra_Milk_Tea           ,
                    Green_Tea 	             ,
                    Green_Milk_Tea           ,
                    Pineapple_Juice          ,
                    Super_Pineapple_Tea      ,
                    Super_Pineapple_Milk_Tea };
    }
endclass

class random_size;
    randc Bev_Size size;
    constraint range{
        size inside{ L ,
                     M ,
                     S  };
    }
endclass

// input today 
// class random_today ;
// 	randc Day   today_day ;
// 	randc Month today_mon ;
// 	function new (int seed) ;
// 		this.srandom(seed) ;
// 	endfunction
// 	constraint range {
// 		today_mon inside {[1:12]} ;
// 		today_day inside {[1:31]} ;
// 		if (today_mon == 2) {
// 			today_day inside {[1:28]} ;
// 		}
// 		else if (today_mon == 4 || today_mon == 6 || today_mon == 9 || today_mon == 11) { 
// 			today_day inside {[1:30]} ;
// 		}
// 	}
// endclass

// Day   input_day ;
// Month input_month ;
// random_today today_rand = new(DATE_SEED) ;



// input Ing
// class random_ing_front ;
// 	randc bit [4:0] ingredient_front ;
// 	function new (int seed) ;
// 		this.srandom(seed) ;
// 	endfunction
// endclass

// class random_ing_rare ;
// 	randc bit [6:0] ingredient_rare ;
// 	function new (int seed) ;
// 		this.srandom(seed) ;
// 	endfunction
// endclass

// ING input_bt, input_gt, input_m, input_p ;
// bit [4:0] ing_front ;
// bit [6:0] ing_rare  ;
// random_ing_front ing_front_rand = new(INGFR_SEED) ;
// random_ing_rare  ing_rare_rand  = new(INGRA_SEED) ;



//================================================================
// initial
//================================================================
random_act act_rand ;
random_box box_rand ;
random_bev  bev_type_rand;
random_size bev_size_rand;
initial begin 
	$readmemh (DRAM_p_r, golden_DRAM) ;
    act_rand = new();
    box_rand = new();
    bev_type_rand = new();
    bev_size_rand = new();
    total_latency = 0;
    latency = 0;
    global_count = 0 ;
	reset_task ;
	count = 0 ;
	for (i_pat = 0 ; i_pat < PAT_NUM ; i_pat = i_pat + 1) begin 
		input_task ;
        latency = 0;
		golden_task ;
		wait_task ;
		check_task ;
		$display ("\033[0;38;5;219mPass Pattern NO. %d  latency = %d\033[m", i_pat, latency);
		global_count = global_count + 1 ;
	end
	pass_task ;
	//$finish ;
end
initial begin
	forever@(posedge clk)begin
		if(inf.rst_n == 0)
          begin
		    @(negedge clk);
			if((inf.complete !== 0) || (inf.err_msg !== 0) || (inf.out_valid !== 0))
            begin
            $display ("--------------------------------------------------------------------------------------------");
            $display ("            FAIL! Output signal should be 0 after the reset signal is asserted              ");
            $display ("--------------------------------------------------------------------------------------------");
			  repeat(3) @(negedge clk);
              $finish;
			end
		  end
	end
end
// initial begin
// 	forever@(posedge clk)begin
// 		if(inf.out_valid)begin
//             @(negedge clk);
//             if((inf.complete !== golden_complete)||(inf.err_msg !== golden_err_msg)) begin 
//                 $display ("--------------------------------------------------------------------------------------------");
//                 $display ("                                  fail pattern: %d                                          ", i_pat);
//                 $display ("                                  GOLDEN_ERR_MSG: %d                                        ", golden_err_msg);
//                 $display ("                                  GOLDEN_COMPLETE: %d                                       ", golden_complete);
//                 $display ("                                  YOUR_ERR_MSG: %d                                          ", inf.err_msg);
//                 $display ("                                  YOUR_COMPLETE: %d                                         ", inf.complete);
//                 $display ("                               FAIL! Incorrect Anwser                                       ");
//                 $display ("--------------------------------------------------------------------------------------------");
//                 repeat(4) @(negedge clk);
//                 $finish ;
//             end
// 		end
// 	end
// end 

//================================================================
// tasks
//================================================================
task reset_task ; begin 
	inf.rst_n            = 1;
    inf.sel_action_valid = 0;
    inf.type_valid       = 0;
    inf.size_valid       = 0;
    inf.date_valid       = 0;
    inf.box_no_valid     = 0;
    inf.box_sup_valid    = 0;
    inf.D                = 'dx;

    #(10) inf.rst_n = 0;
    #(10) inf.rst_n = 1;
end endtask

logic[9:0] test1;

task input_task ; begin 
	@(negedge clk) ;
    inf.sel_action_valid = 1 ;
    act_rand.randomize();
    inf.D = act_rand.act_id ;
    test1 = act_rand.act_id;
	@(negedge clk) ;
	inf.sel_action_valid = 0 ;
	inf.D = 'dx ;
    @(negedge clk) ;
	
	case (act_rand.act_id)
		Make_drink : begin 
            //=========================================================
			// Type Valid
			//=========================================================
            inf.type_valid = 1 ;
            bev_type_rand.randomize() ;
            inf.D = bev_type_rand.bev ;
			@(negedge clk) ;
			inf.type_valid = 0 ; 
			inf.D = 'dx ;
            @(negedge clk) ;
            //=========================================================
            
			//=========================================================
			// Size Valid
			//=========================================================
			inf.size_valid = 1 ;
			bev_size_rand.randomize() ;
            inf.D = bev_size_rand.size ;
			@(negedge clk) ;
			inf.size_valid = 0 ;
			inf.D = 'dx ;
            @(negedge clk) ;
			//=========================================================
			
			//=========================================================
			// Date Valid
			//=========================================================
			// catch = today_rand.randomize() ;
            date.M = $urandom_range(1, 12);
            if (date.M == 1 || date.M == 3 || date.M == 5 || date.M == 7 || date.M == 8 || date.M == 10 || date.M == 12) begin
            date.D = $urandom_range(1,31);
            end
            if (date.M == 4 || date.M == 6 || date.M == 9 || date.M == 11) begin
                date.D = $urandom_range(1,30);
            end
            if (date.M == 2) begin
                date.D = $urandom_range(1,28);
            end
                
			today.M = date.M;
            today.D = date.D;
			inf.date_valid = 1 ;
			inf.D = {today.M, today.D} ;
			@(negedge clk) ;
			inf.date_valid = 0 ;
			inf.D = 'dx ;
            @(negedge clk) ;
			//=========================================================
			
			//=========================================================
			// Box No. Valid
			//=========================================================
			inf.box_no_valid = 1 ;
            box_rand.randomize() ;
			inf.D = box_rand.box_id ;
			@(negedge clk) ;
			// pull down input
			inf.box_no_valid = 0 ;
			inf.D = 'dx ;
			//=========================================================
		end
		Supply : begin 
			//=========================================================
			// Input Valid
			//=========================================================
			// catch = today_rand.randomize() ;
            date.M = $urandom_range(1, 12);
            if (date.M == 1 || date.M == 3 || date.M == 5 || date.M == 7 || date.M == 8 || date.M == 10 || date.M == 12) begin
                date.D = $urandom_range(1,31);
            end
            if (date.M == 4 || date.M == 6 || date.M == 9 || date.M == 11) begin
                date.D = $urandom_range(1,30);
            end
            if (date.M == 2) begin
                date.D = $urandom_range(1,28);
            end
			today.M = date.M;
            today.D = date.D;
			inf.date_valid = 1 ;
			inf.D = {today.M, today.D} ;
			@(negedge clk) ;
			inf.date_valid = 0 ;
			inf.D = 'dx ;
			@(negedge clk) ;
			//=========================================================
			
			//=========================================================
			// Box No. Valid
			//=========================================================
            inf.box_no_valid = 1 ;
			box_rand.randomize() ;
            inf.D = box_rand.box_id;
			//input_box = 20 ;
			//inf.D = input_box ;
			@(negedge clk) ;
			inf.box_no_valid = 0 ;
			inf.D = 'dx ;
			@(negedge clk) ;
			//=========================================================
			
			//=========================================================
			// Black_Tea Input Valid
			//=========================================================
			// catch = ing_front_rand.randomize() ;
			// catch = ing_rare_rand.randomize() ;
			// ing_front = ing_front_rand.ingredient_front ;
			// ing_rare  = ing_rare_rand.ingredient_rare ;
			// input_bt = ing_front*128+ing_rare ;
			inf.box_sup_valid = 1 ;
            supply_black = $urandom_range(0, 4095);
			inf.D = supply_black ;
			@(negedge clk) ;
			inf.box_sup_valid = 0 ;
			inf.D = 'dx ;
			@(negedge clk) ;
			//=========================================================

			//=========================================================
			// Green Tea Input Valid
			//=========================================================
            inf.box_sup_valid = 1 ;
            supply_green = $urandom_range(0, 4095);
			inf.D = supply_green ;
			@(negedge clk) ;
			inf.box_sup_valid = 0 ;
			inf.D = 'dx ;
			@(negedge clk) ;
			// catch = ing_front_rand.randomize() ;
			// catch = ing_rare_rand.randomize() ;
			// ing_front = ing_front_rand.ingredient_front ;
			// ing_rare  = ing_rare_rand.ingredient_rare ;
			// input_gt = ing_front*128+ing_rare ;
			// inf.box_sup_valid = 1 ;
			// inf.D = input_gt ;
			// @(negedge clk) ;
			// inf.box_sup_valid = 0 ;
			// inf.D = 'dx ;
			//=========================================================

			//=========================================================
			// Milk Input Valid
			//=========================================================
            inf.box_sup_valid = 1 ;
            supply_milk = $urandom_range(0, 4095);
			inf.D = supply_milk ;
			@(negedge clk) ;
			inf.box_sup_valid = 0 ;
			inf.D = 'dx ;
			@(negedge clk) ;
			// catch = ing_front_rand.randomize() ;
			// catch = ing_rare_rand.randomize() ;
			// ing_front = ing_front_rand.ingredient_front ;
			// ing_rare  = ing_rare_rand.ingredient_rare ;
			// input_m = ing_front*128+ing_rare ;
			// inf.box_sup_valid = 1 ;
			// inf.D = input_m ;
			// @(negedge clk) ;
			// inf.box_sup_valid = 0 ;
			// inf.D = 'dx ;
			//=========================================================
			
			//=========================================================
			// Pineapple_Juice Input Valid
			//=========================================================
            inf.box_sup_valid = 1 ;
            supply_pineapple = $urandom_range(0, 4095);
			inf.D = supply_pineapple ;
			@(negedge clk) ;
			inf.box_sup_valid = 0 ;
			inf.D = 'dx ;
			@(negedge clk) ;
			// catch = ing_front_rand.randomize() ;
			// catch = ing_rare_rand.randomize() ;
			// ing_front = ing_front_rand.ingredient_front ;
			// ing_rare  = ing_rare_rand.ingredient_rare ;
			// input_p = ing_front*128+ing_rare ;
			// inf.box_sup_valid = 1 ;
			// inf.D = input_p ;
			// @(negedge clk) ;
			// inf.box_sup_valid = 0 ;
			// inf.D = 'dx ;
			//=========================================================
		end
		Check_Valid_Date : begin 
			//=========================================================
			// Date Valid
			//=========================================================
            date.M = 12;
            if (date.M == 1 || date.M == 3 || date.M == 5 || date.M == 7 || date.M == 8 || date.M == 10 || date.M == 12) begin
                date.D = $urandom_range(1,31);
            end
            if (date.M == 4 || date.M == 6 || date.M == 9 || date.M == 11) begin
                date.D = $urandom_range(1,30);
            end
            if (date.M == 2) begin
                date.D = $urandom_range(1,28);
            end
            today.M = date.M;
            today.D = date.D;
            inf.date_valid = 1 ;
			inf.D = {today.M, today.D} ;
			@(negedge clk) ;
			inf.date_valid = 0 ;
			inf.D = 'dx ;
			@(negedge clk) ;
			//=========================================================
			
			//=========================================================
			// Box No. Valid
			//=========================================================
            inf.box_no_valid = 1 ;
			box_rand.randomize() ;
			inf.D = box_rand.box_id ;
			@(negedge clk) ;
			inf.box_no_valid = 0 ;
			inf.D = 'dx ;
			//=========================================================
		end
	endcase 
end endtask 

task golden_task ; begin 
    golden_black     = {golden_DRAM[65536 + 7 + (8 * box_rand.box_id)],      golden_DRAM[65536 + 6 + (8 * box_rand.box_id)][7:4]};
    golden_green     = {golden_DRAM[65536 + 6 + (8 * box_rand.box_id)][3:0], golden_DRAM[65536 + 5 + (8 * box_rand.box_id)]};
    golden_milk      = {golden_DRAM[65536 + 3 + (8 * box_rand.box_id)],      golden_DRAM[65536 + 2 + (8 * box_rand.box_id)][7:4]};
    golden_pineapple = {golden_DRAM[65536 + 2 + (8 * box_rand.box_id)][3:0], golden_DRAM[65536 + 1 + (8 * box_rand.box_id)]};
    golden_month     = {golden_DRAM[65536 + 4 + (8 * box_rand.box_id)]};
    golden_day       = {golden_DRAM[65536 + 0 + (8 * box_rand.box_id)]};
	// no_pass_expired   = 1 ;
	// enough_ing        = 1 ;
	// bt_overflow       = 0 ;
	// gt_overflow       = 0 ;
	// milk_overflow     = 0 ;
	// pine_overflow     = 0 ;
	
	case (act_rand.act_id) 
		Make_drink : begin
			//=========================================================
			// Pass Expired Day Or Not
			//=========================================================
			chech_Expired_task;
            //=========================================================
			// Enough Ingredient Or Not
			//=========================================================
            if(golden_err_msg == 2'b00) chech_Enough_task;
			//=========================================================
			// Make Drink
			//=========================================================
			if(golden_err_msg == 2'b00) make_drink_task;
			//=========================================================
			// Update Dram
			//=========================================================
			if(golden_err_msg == 2'b00) update_DRAM_task;
		end 
		Supply : begin 
            //=========================================================
			// Supply
			//=========================================================
            supply_task;
			//=========================================================
			// Ingredient Overflow Or Not
			//=========================================================
			check_ans_supply_task;
			//=========================================================
			// Update Dram
			//=========================================================
			update_DRAM_task;
		end
		Check_Valid_Date : begin 
			//=========================================================
			// Pass Expired Day Or Not
			//=========================================================
			chech_Expired_task ;
		end
	endcase 
end endtask 

task supply_task;
    begin
        @(negedge clk);
        golden_day = today.D;
        golden_month = today.M;
        if((golden_black     + supply_black) > 4095) begin
            golden_black[11:0]  = 'd4095;
            golden_black[12]    = 1;
        end
        else begin
            golden_black[11:0]  = golden_black     + supply_black;
            golden_black[12]    = 0;
        end
        if((golden_green     + supply_green) > 4095) begin
            golden_green[11:0]  = 'd4095;
            golden_green[12]    = 1;
        end
        else begin
            golden_green[11:0]  = golden_green     + supply_green;
            golden_green[12]    = 0;
        end
        if((golden_pineapple     + supply_pineapple) > 4095) begin
            golden_pineapple[11:0]  = 'd4095;
            golden_pineapple[12]    = 1;
        end
        else begin
            golden_pineapple[11:0]  = golden_pineapple     + supply_pineapple;
            golden_pineapple[12]    = 0;
        end
        if((golden_milk     + supply_milk) > 4095) begin
            golden_milk[11:0]  = 'd4095;
            golden_milk[12]    = 1;
        end
        else begin
            golden_milk[11:0]  = golden_milk     + supply_milk;
            golden_milk[12]    = 0;
        end
        @(negedge clk);
    end
endtask


task check_ans_supply_task;
    begin
    @(negedge clk);
    if (golden_milk[12] != 0 | golden_black[12] != 0 | golden_green[12] != 0 | golden_pineapple[12] != 0) begin
        golden_err_msg = 2'b11;
        golden_complete = 'b0;
    end
    else begin 
        golden_err_msg = 2'b00;
        golden_complete = 'b1;
    end
    @(negedge clk);
    end
endtask

task chech_Expired_task ; begin 
	if (today.M > golden_month) begin
        golden_err_msg = 2'b01;
        golden_complete = 'b0;
    end
    else if (today.M == golden_month && today.D > golden_day) begin
        golden_err_msg = 2'b01;
        golden_complete = 'b0;
    end
    else begin 
        golden_err_msg = 2'b00;
        golden_complete = 'b1;
    end
    @(negedge clk);
end endtask

task make_drink_task ; begin
    @(negedge clk);
    golden_green[11:0] = golden_green[11:0] - golden_green_need ;
    golden_black[11:0] = golden_black[11:0] - golden_black_need ;
    golden_pineapple[11:0] = golden_pineapple[11:0] - golden_pineapple_need ;
    golden_milk[11:0] = golden_milk[11:0] - golden_milk_need ;
    golden_day = golden_day;
    golden_month = golden_month;
    @(negedge clk);
end
endtask


task update_DRAM_task ; begin
    @(negedge clk);
    golden_DRAM[65536 + 7 + (8 * box_rand.box_id)]      = golden_black[11:4];
    golden_DRAM[65536 + 6 + (8 * box_rand.box_id)][7:4] = golden_black[3:0];

    golden_DRAM[65536 + 6 + (8 * box_rand.box_id)][3:0] = golden_green[11:8];
    golden_DRAM[65536 + 5 + (8 * box_rand.box_id)]      = golden_green[7:0];

    golden_DRAM[65536 + 3 + (8 * box_rand.box_id)]      = golden_milk[11:4];
    golden_DRAM[65536 + 2 + (8 * box_rand.box_id)][7:4] = golden_milk[3:0];

    golden_DRAM[65536 + 2 + (8 * box_rand.box_id)][3:0] = golden_pineapple[11:8];
    golden_DRAM[65536 + 1 + (8 * box_rand.box_id)]      = golden_pineapple[7:0];
    golden_DRAM[65536 + 4 + (8 * box_rand.box_id)]      = golden_month;
    golden_DRAM[65536 + 0 + (8 * box_rand.box_id)]      = golden_day;
    @(negedge clk);
end
endtask

task chech_Enough_task ; begin 
     case (bev_type_rand.bev)
        Black_Tea : begin
            if (bev_size_rand.size == 0) begin 
                golden_black_need = 960;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 0;
            end
            else if (bev_size_rand.size == 1) begin 
                golden_black_need = 720;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 0;
            end
            else if (bev_size_rand.size == 3) begin 
                golden_black_need = 480;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 0;
            end
            else begin 
                golden_black_need = 0;
                golden_green_need = 0;
                golden_pineapple = 0;
                golden_milk_need = 0;
            end

        end  
        Milk_Tea : begin
            if (bev_size_rand.size == 0) begin
                golden_black_need = 720;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 240;
            end
            else if (bev_size_rand.size == 1) begin
                golden_black_need = 540 ;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 180;
            end
            else if (bev_size_rand.size == 3) begin
                golden_black_need = 360;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 120;
            end
            else begin
                golden_black_need = 0;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 0;
            end
        end  
        Extra_Milk_Tea : begin
            if (bev_size_rand.size == 0) begin
                golden_black_need = 480;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 480;
            end
            else if (bev_size_rand.size == 1) begin
                golden_black_need = 360;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 360;
            end
            else if (bev_size_rand.size == 3) begin
                golden_black_need = 240;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 240;
            end
            else begin
                golden_black_need = 0;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 0;
            end
        end  
        Green_Tea : begin
            if (bev_size_rand.size == 0) begin
                golden_black_need = 0;
                golden_green_need = 960;
                golden_pineapple_need = 0;
                golden_milk_need = 0;
            end
            else if (bev_size_rand.size == 1) begin
                golden_black_need = 0;
                golden_green_need = 720;
                golden_pineapple_need = 0;
                golden_milk_need = 0;
            end
            else if (bev_size_rand.size == 3) begin
                golden_black_need = 0;
                golden_green_need = 480;
                golden_pineapple_need = 0;
                golden_milk_need = 0;
            end
            else begin
                golden_black_need = 0;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 0;
            end
        end  
        Green_Milk_Tea : begin
            if (bev_size_rand.size == 0) begin
                golden_black_need = 0;
                golden_green_need = 480;
                golden_pineapple_need = 0;
                golden_milk_need = 480;
            end
            else if (bev_size_rand.size == 1) begin
                golden_black_need = 0;
                golden_green_need = 360;
                golden_pineapple_need = 0;
                golden_milk_need = 360;
            end
            else if (bev_size_rand.size == 3) begin
                golden_black_need = 0;
                golden_green_need = 240;
                golden_pineapple_need = 0;
                golden_milk_need = 240;
            end
            else begin
                golden_black_need = 0;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 0;
            end
        end  
        Pineapple_Juice : begin
            if (bev_size_rand.size == 0) begin 
                golden_black_need = 0;
                golden_green_need = 0;
                golden_pineapple_need = 960;
                golden_milk_need = 0;
            end
            else if (bev_size_rand.size == 1) begin 
                golden_black_need = 0;
                golden_green_need = 0;
                golden_pineapple_need = 720;
                golden_milk_need = 0;
            end
            else if (bev_size_rand.size == 3) begin 
                golden_black_need = 0;
                golden_green_need = 0;
                golden_pineapple_need = 480;
                golden_milk_need = 0;
            end
            else begin 
                golden_black_need = 0;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 0;
            end
        end  
        Super_Pineapple_Tea : begin
            if (bev_size_rand.size == 0) begin
                golden_black_need = 480;
                golden_green_need = 0;
                golden_pineapple_need = 480;
                golden_milk_need = 0;
            end
            else if (bev_size_rand.size == 1) begin
                golden_black_need = 360;
                golden_green_need = 0;
                golden_pineapple_need = 360;
                golden_milk_need = 0;
            end
            else if (bev_size_rand.size == 3) begin
                golden_black_need = 240;
                golden_green_need = 0;
                golden_pineapple_need = 240;
                golden_milk_need = 0;
            end
            else begin
                golden_black_need = 0;
                golden_green_need = 0;
                golden_pineapple_need = 0;
                golden_milk_need = 0;
            end
        end  
        Super_Pineapple_Milk_Tea : begin
            if (bev_size_rand.size == 0) begin
                golden_black_need = 480; 
                golden_green_need = 0;         
                golden_milk_need = 240;  
                golden_pineapple_need = 240;        
            end
            else if (bev_size_rand.size == 1) begin
                golden_black_need = 360;  
                golden_green_need = 0;
                golden_milk_need = 180; 
                golden_pineapple_need = 180;                   
            end
            else if (bev_size_rand.size == 3) begin
                golden_black_need = 240; 
                golden_green_need = 0;
                golden_milk_need = 120;    
                golden_pineapple_need = 120;                 
            end
            else begin
                golden_black_need = 0;
                golden_green_need = 0; 
                golden_milk_need = 0;    
                golden_pineapple_need = 0;                 
            end
        end 
    endcase
    @(negedge clk); 
    if (golden_black_need > golden_black[11:0]) begin
        golden_err_msg = 2'b10;
        golden_complete = 'b0;
    end
    else if (golden_green_need > golden_green[11:0]) begin
        golden_err_msg = 2'b10;
        golden_complete = 'b0;
    end
    else if (golden_milk_need > golden_milk[11:0]) begin
        golden_err_msg = 2'b10;
        golden_complete = 'b0;
    end
    else if (golden_pineapple_need > golden_pineapple[11:0]) begin
        golden_err_msg = 2'b10;
        golden_complete = 'b0;
    end
    else begin 
        golden_err_msg = 2'b00;
        golden_complete = 'b1;
    end
    @(negedge clk);
end endtask




// task wait_task ; begin 
// 	exe_lat = -1 ;
// 	while (inf.out_valid !== 1) begin 
//         exe_lat = exe_lat + 1;
//         @(negedge clk);
// 	end
// end endtask 

task wait_task;
    begin
    while(inf.out_valid !== 1'b1) begin
        latency = latency + 1;
        if(latency == 1000) begin
            $display("*************************************************************************");
            $display("                           fail pattern: %d                           ", i_pat);
            $display("             The execution latency is limited in 1000 cycle              ");
            $display("*************************************************************************");
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
    end
endtask


task check_task ; begin 
	if((inf.complete !== golden_complete)||(inf.err_msg !== golden_err_msg)) begin 
        $display ("--------------------------------------------------------------------------------------------");
        $display ("                                  fail pattern: %d                                          ", i_pat);
        $display ("                                  GOLDEN_ERR_MSG: %d                                        ", golden_err_msg);
        $display ("                                  GOLDEN_COMPLETE: %d                                       ", golden_complete);
        $display ("                                  YOUR_ERR_MSG: %d                                          ", inf.err_msg);
        $display ("                                  YOUR_COMPLETE: %d                                         ", inf.complete);
        $display ("                               FAIL! Incorrect Anwser                                       ");
        $display ("--------------------------------------------------------------------------------------------");
        repeat(4) @(negedge clk);
        $finish ;
	end
end endtask 

task pass_task ; begin 
    $display("==========================================================================") ;
	$display("                            Congratulations                               ") ;
    $display("==========================================================================") ;
    $finish;
end endtask 

endprogram
