// `include "../00_TESTBED/pseudo_DRAM.sv"
`ifdef RTL
    `define CYCLE_TIME 2.5
`endif
`ifdef GATE
    `define CYCLE_TIME 2.5
`endif

`include "Usertype.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter MAX_CYCLE=1000;
parameter PAT_NUM = 8500 ;
integer i, j, latency, total_latency, i_pat ;
real CYCLE = `CYCLE_TIME;
parameter CYCLE_DELAY = 1000;
//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 256 box
Date date,today;
logic [12:0] dram_Rose;
logic [12:0] dram_Lily;
logic [12:0] dram_Carnation;
logic [12:0] dram_Baby_Breath;
logic [7:0]  dram_Month;
logic [7:0]  dram_date;
logic [1:0]  golden_warn_msg;
logic        golden_complete;
logic [3:0]  Mode_type;
logic [11:0] Needing_Rose;
logic [11:0] Needing_Lily;
logic [11:0] Needing_Carnation;
logic [11:0] Needing_Baby_Breath;
//debug
logic [2:0] dram_strategy;
logic [1:0] dram_mode;
logic [11:0] dram_Rose_debug;
logic [11:0] dram_Lily_debug;
logic [11:0] dram_Carnation_debug;
logic [11:0] dram_Baby_Breath_debug;
logic [8:0] dram_addr;
logic [11:0] Restock_Rose;
logic [11:0] Restock_Lily;
logic [11:0] Restock_Carnation;
logic [11:0] Restock_Baby_Breath;
logic [2:0]  dram_action;

assign dram_Rose_debug        = dram_Rose[11:0];
assign dram_Lily_debug        = dram_Lily[11:0];
assign dram_Carnation_debug   = dram_Carnation[11:0]; 
assign dram_Baby_Breath_debug = dram_Baby_Breath[11:0];
//debug
// logic wait_next_valid;
//================================================================
// class random
//================================================================

/**
 * Class representing a random action.
 */
class random_act;
    randc Action act_id;
    constraint range{
        act_id inside{Purchase, Restock, Check_Valid_Date};
    }
endclass

class random_data_no;
	randc logic [8:0] data_no ;
	constraint range {
		data_no inside {[0:255]} ;
	}
endclass

// class random_mode_and_strategy;
//     randc logic [4:0] mode_and_strategy;
//     constraint range{
//         mode_and_strategy inside {[0:31]};
//     }
// endclass


class random_strategy;
    randc Strategy_Type strategy;
    constraint range{
        strategy inside{ Strategy_A ,
                         Strategy_B ,
                         Strategy_C ,
                         Strategy_D ,
                         Strategy_E ,
                         Strategy_F ,
                         Strategy_G ,
                         Strategy_H };
    }
endclass

class random_mode;
    randc Mode mode;
    constraint range{
        mode inside{ Single ,
                     Group_Order ,
                     Event  };
    }
endclass

class random_restock;
    randc logic [11:0] restock;
    constraint range {
		restock inside {[0:4095]} ;
    }
endclass

//================================================================
// initial
//================================================================
random_act act_rand;
random_data_no data_no_rand;
random_strategy strategy_rand;
random_mode mode_rand;

random_restock restock_Rose_rand;
random_restock restock_Lily_rand;
random_restock restock_Carnation_rand;
random_restock restock_Baby_Breath_rand;
initial begin
	$readmemh (DRAM_p_r, golden_DRAM) ;
    act_rand = new();
    data_no_rand = new();
    strategy_rand = new();
    mode_rand = new();
    restock_Rose_rand = new();
    restock_Lily_rand = new();
    restock_Carnation_rand = new();
    restock_Baby_Breath_rand = new();
	reset_task;
	for (i_pat = 0 ; i_pat < PAT_NUM ; i_pat = i_pat + 1) begin
		input_task;
		golden_task;
	    wait_out_valid_task;
	    check_task;
        if(i_pat % 1000 == 0) $display ("\033[0;38;5;219mPass Pattern NO. %d  latency = %d\033[m", i_pat, latency);
	end
	pass_task;
end

task reset_task ; begin 
    total_latency        = 0;
	inf.rst_n            = 'b1;
    inf.sel_action_valid = 'b0;
    inf.strategy_valid   = 'b0;
    inf.mode_valid       = 'b0;
    inf.date_valid       = 'b0;
    inf.data_no_valid    = 'b0;
    inf.restock_valid    = 'b0;
    inf.D                = 'dx;

    // force clk = 0;

    #CYCLE;       inf.rst_n = 0; 
    #(CYCLE * 2); inf.rst_n = 1;
    
    if(inf.sel_action_valid !== 'b0 || inf.strategy_valid !== 'b0 || inf.mode_valid !== 'b0 || inf.date_valid !== 'b0 || inf.data_no_valid !== 'b0 || inf.restock_valid !== 'b0) begin
        $display("----------------------------------------------------------------------------------------");
        $display("     ▄▀▀▄▀▀▀▀▀▀▄▀▀▄                                                   ");
        $display("    ▄▀            ▀▄      ▄▄                                          ");
        $display("    █  ▀   ▀       ▀▄▄   █  █            Wrong Answer                 ");
        $display("    █   ▀▀            ▀▀▀   ▀▄  ╭  Output signal should be 0 after RESET  at %8t", $time);
        $display("    █  ▄▀▀▀▄                 █  ╭                                        ");
        $display("    ▀▄                       █                                           ");
        $display("     █   ▄▄   ▄▄▄▄▄    ▄▄   █                                           ");
        $display("     ▀▄▄▀ ▀▀▄▀     ▀▄▄▀  ▀▄▀                                            ");
        $display("----------------------------------------------------------------------------------------");
        // release clk;
		repeat(2) #CYCLE; //warning maybe change 10
        $finish;
    end
	#CYCLE; 
    // release clk;
end endtask

task input_task ; begin 
	// @(negedge clk) ;
    // wait_next_valid = 1;
    repeat($urandom_range(1, 4)) @(negedge clk);
    inf.sel_action_valid = 1;
    // wait_next_valid = 0;
    act_rand.randomize();
    inf.D = act_rand.act_id;
	@(negedge clk) ;
	inf.sel_action_valid = 0 ;
	//inf.D = 'dx ;
    repeat($urandom_range(0, 3)) @(negedge clk);
	
	case (act_rand.act_id)
		Purchase : begin 
            //=========================================================
			// Strategy Type Valid
			//=========================================================
            inf.strategy_valid = 1;
            strategy_rand.randomize();
            inf.D = strategy_rand.strategy;
            //debug
            dram_strategy = strategy_rand.strategy;
            //debug
			@(negedge clk) ;
			inf.strategy_valid = 0;
			//inf.D = 'dx ;
            repeat($urandom_range(0, 3)) @(negedge clk);
            //=========================================================
            
			//=========================================================
			// Mode Valid
			//=========================================================
			inf.mode_valid = 1;
			mode_rand.randomize();
            inf.D = mode_rand.mode;
            //debug
            dram_mode = mode_rand.mode;
            //debug
			@(negedge clk) ;
			inf.mode_valid = 0;
			//inf.D = 'dx ;
            repeat($urandom_range(0, 3)) @(negedge clk);
			//=========================================================
			
			//=========================================================
			// Date Valid
			//=========================================================
            Date_input_task;
			//=========================================================
			
			//=========================================================
			// DRAM No. Valid
			//=========================================================
			DRAM_No_input_task;
			//=========================================================
		end
		Restock : begin 
			//=========================================================
			// Date Valid
			//=========================================================
            Date_input_task;
			//=========================================================
			
			//=========================================================
			// DRAM No. Valid
			//=========================================================
            DRAM_No_input_task;
			//=========================================================
			
			//=========================================================
			// Rose Input Valid
			//=========================================================
			inf.restock_valid = 1;
            restock_Rose_rand.randomize();
			inf.D = restock_Rose_rand.restock;
            //debug
                Restock_Rose = restock_Rose_rand.restock;
            //debug
			@(negedge clk) ;
			inf.restock_valid = 0;
			//inf.D = 'dx ;
			repeat($urandom_range(0, 3)) @(negedge clk);
			//=========================================================

			//=========================================================
			// Lily Input Valid
			//=========================================================
            inf.restock_valid = 1;
            restock_Lily_rand.randomize();
			inf.D = restock_Lily_rand.restock;
            //debug
                Restock_Lily = restock_Lily_rand.restock;
            //debug
			@(negedge clk);
			inf.restock_valid = 0;
			inf.D = 'dx;
			repeat($urandom_range(0, 3)) @(negedge clk);
			//=========================================================

			//=========================================================
			// Carnation Input Valid
			//=========================================================
            inf.restock_valid = 1;
            restock_Carnation_rand.randomize();
			inf.D = restock_Carnation_rand.restock;
            //debug
                 Restock_Carnation = restock_Carnation_rand.restock;
            //debug
			@(negedge clk);
			inf.restock_valid = 0;
			inf.D = 'dx;
			repeat($urandom_range(0, 3)) @(negedge clk);
			//=========================================================
			
			//=========================================================
			// Baby_Breath Input Valid
			//=========================================================
            inf.restock_valid = 1;
            restock_Baby_Breath_rand.randomize();
			inf.D = restock_Baby_Breath_rand.restock;
            //debug
                Restock_Baby_Breath =  restock_Baby_Breath_rand.restock;
            //debug
			@(negedge clk);
			inf.restock_valid = 0;
			inf.D = 'dx;
			repeat($urandom_range(0, 3)) @(negedge clk);
			//=========================================================
		end
		Check_Valid_Date : begin 
		    //=========================================================
			// Date Valid
			//=========================================================
            Date_input_task;
			//=========================================================
			
			//=========================================================
			// DRAM No. Valid
			//=========================================================
            DRAM_No_input_task;
			//=========================================================
		end
	endcase 
end endtask 

task DRAM_No_input_task; begin    
    inf.data_no_valid = 1 ;
    data_no_rand.randomize() ;
    inf.D = data_no_rand.data_no ;
    //debug
    // $display ("\033[0;38;5;219m Memory Address %d\033[m", data_no_rand.data_no);
    dram_addr = data_no_rand.data_no;
    //debug
    @(negedge clk) ;
    inf.data_no_valid = 0 ;
    //inf.D = 'dx ;
    repeat($urandom_range(0, 3)) @(negedge clk);
end endtask

task Date_input_task; begin    
    inf.date_valid = 1 ;
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
    today.M = date.M; //optimization : today and date both needing or not
    today.D = date.D;
    inf.D = {today.M, today.D} ;
    @(negedge clk) ;
    inf.date_valid = 0 ;
    //inf.D = 'dx ;
    repeat($urandom_range(0, 3)) @(negedge clk);
end endtask

task golden_task ; begin 
    dram_Rose[11:0]        = {golden_DRAM[65536 + 7 + (data_no_rand.data_no << 3)],      golden_DRAM[65536 + 6 + (data_no_rand.data_no << 3)][7:4]};
    dram_Lily[11:0]        = {golden_DRAM[65536 + 6 + (data_no_rand.data_no << 3)][3:0], golden_DRAM[65536 + 5 + (data_no_rand.data_no << 3)]};
    dram_Carnation[11:0]   = {golden_DRAM[65536 + 3 + (data_no_rand.data_no << 3)],      golden_DRAM[65536 + 2 + (data_no_rand.data_no << 3)][7:4]};
    dram_Baby_Breath[11:0] = {golden_DRAM[65536 + 2 + (data_no_rand.data_no << 3)][3:0], golden_DRAM[65536 + 1 + (data_no_rand.data_no << 3)]};
    dram_Month[7:0]        = {golden_DRAM[65536 + 4 + (data_no_rand.data_no << 3)]};
    dram_date[7:0]         = {golden_DRAM[65536 + 0 + (data_no_rand.data_no << 3)]};
	case (act_rand.act_id) 
		Purchase : begin
			chech_Expired_task;
            if(golden_warn_msg == 2'b00) begin
                chech_Enough_task;
                if(golden_warn_msg == 2'b00) begin
                    purchase_flower;
                    update_DRAM_task;
                end
            end
		end 
		Restock : begin 
            supply_task;
			check_ans_supply_task;
			update_DRAM_task;
		end
		Check_Valid_Date : begin 
			chech_Expired_task;
		end
	endcase 
end endtask 

task chech_Expired_task ; begin 
	if (today.M < dram_Month) begin
        golden_warn_msg = 'b01;
        golden_complete = 'b0;
    end
    else if (today.M == dram_Month && today.D < dram_date) begin
        golden_warn_msg = 'b01;
        golden_complete = 'b0;
    end
    else begin 
        golden_warn_msg = 'b00;
        golden_complete = 'b1;
    end
    // @(negedge clk);
end endtask

task chech_Enough_task ; begin 
    case (mode_rand.mode)
        Single : begin
            Mode_type = 'd1;
        end  
        Group_Order : begin
            Mode_type = 'd4;
        end  
        Event : begin
            Mode_type = 'd8;
        end  
    endcase
    case (strategy_rand.strategy)
        Strategy_A : begin
            Needing_Rose        = 120 * Mode_type;
            Needing_Lily        = 0;
            Needing_Carnation   = 0;
            Needing_Baby_Breath = 0;
        end  
        Strategy_B : begin
            Needing_Rose        = 0;
            Needing_Lily        = 120 * Mode_type;
            Needing_Carnation   = 0;
            Needing_Baby_Breath = 0;
        end  
        Strategy_C : begin
            Needing_Rose        = 0;
            Needing_Lily        = 0;
            Needing_Carnation   = 120 * Mode_type;
            Needing_Baby_Breath = 0;
        end  
        Strategy_D : begin
            Needing_Rose        = 0;
            Needing_Lily        = 0;
            Needing_Carnation   = 0;
            Needing_Baby_Breath = 120 * Mode_type;
        end  
        Strategy_E : begin
            Needing_Rose        = 60 * Mode_type;
            Needing_Lily        = 60 * Mode_type;
            Needing_Carnation   = 0;
            Needing_Baby_Breath = 0;
        end  
        Strategy_F : begin
            Needing_Rose        = 0;
            Needing_Lily        = 0;
            Needing_Carnation   = 60 * Mode_type;
            Needing_Baby_Breath = 60 * Mode_type;
        end  
        Strategy_G : begin
            Needing_Rose        = 60 * Mode_type;
            Needing_Lily        = 0;
            Needing_Carnation   = 60 * Mode_type;
            Needing_Baby_Breath = 0;
        end  
        Strategy_H : begin
            Needing_Rose        = 30 * Mode_type;
            Needing_Lily        = 30 * Mode_type;
            Needing_Carnation   = 30 * Mode_type;
            Needing_Baby_Breath = 30 * Mode_type;
        end 
    endcase
    // @(negedge clk); 
    if (Needing_Rose > dram_Rose[11:0]) begin
        golden_warn_msg = 2'b10;
        golden_complete = 'b0;
    end
    else if (Needing_Lily > dram_Lily[11:0]) begin
        golden_warn_msg = 2'b10;
        golden_complete = 'b0;
    end
    else if (Needing_Carnation > dram_Carnation[11:0]) begin
        golden_warn_msg = 2'b10;
        golden_complete = 'b0;
    end
    else if (Needing_Baby_Breath > dram_Baby_Breath[11:0]) begin
        golden_warn_msg = 2'b10;
        golden_complete = 'b0;
    end
    else begin 
        golden_warn_msg = 2'b00;
        golden_complete = 'b1;
    end
    // @(negedge clk);
end endtask

task purchase_flower; begin
    // @(negedge clk);
    dram_Rose[11:0]        = dram_Rose[11:0] - Needing_Rose;
    dram_Lily[11:0]        = dram_Lily[11:0] - Needing_Lily;
    dram_Carnation[11:0]   = dram_Carnation[11:0] - Needing_Carnation;
    dram_Baby_Breath[11:0] = dram_Baby_Breath[11:0] - Needing_Baby_Breath;
    // @(negedge clk);
end
endtask

task update_DRAM_task ; begin
    // @(negedge clk);
    golden_DRAM[65536 + 7 + (data_no_rand.data_no << 3)]      = dram_Rose[11:4];
    golden_DRAM[65536 + 6 + (data_no_rand.data_no << 3)][7:4] = dram_Rose[3:0];
    golden_DRAM[65536 + 6 + (data_no_rand.data_no << 3)][3:0] = dram_Lily[11:8];
    golden_DRAM[65536 + 5 + (data_no_rand.data_no << 3)]      = dram_Lily[7:0];
    golden_DRAM[65536 + 3 + (data_no_rand.data_no << 3)]      = dram_Carnation[11:4];
    golden_DRAM[65536 + 2 + (data_no_rand.data_no << 3)][7:4] = dram_Carnation[3:0];
    golden_DRAM[65536 + 2 + (data_no_rand.data_no << 3)][3:0] = dram_Baby_Breath[11:8];
    golden_DRAM[65536 + 1 + (data_no_rand.data_no << 3)]      = dram_Baby_Breath[7:0];
    golden_DRAM[65536 + 4 + (data_no_rand.data_no << 3)]      = dram_Month;
    golden_DRAM[65536 + 0 + (data_no_rand.data_no << 3)]      = dram_date;
    // @(negedge clk);
end
endtask

task supply_task;
    begin
        // @(negedge clk);
        dram_date  = today.D;
        dram_Month = today.M;
        if((dram_Rose[11:0] + restock_Rose_rand.restock) > 4095) begin
            dram_Rose[11:0]  = 'd4095;
            dram_Rose[12]    = 1;
        end
        else begin
            dram_Rose[11:0]  = dram_Rose[11:0] + restock_Rose_rand.restock;
            dram_Rose[12]    = 0;
        end
        if((dram_Lily[11:0] + restock_Lily_rand.restock) > 4095) begin
            dram_Lily[11:0]  = 'd4095;
            dram_Lily[12]    = 1;
        end
        else begin
            dram_Lily[11:0]  = dram_Lily[11:0] + restock_Lily_rand.restock;
            dram_Lily[12]    = 0;
        end
        if((dram_Carnation[11:0] + restock_Carnation_rand.restock) > 4095) begin
            dram_Carnation[11:0]  = 'd4095;
            dram_Carnation[12]    = 1;
        end
        else begin
            dram_Carnation[11:0]  = dram_Carnation[11:0] + restock_Carnation_rand.restock;
            dram_Carnation[12]    = 0;
        end
        if((dram_Baby_Breath[11:0] + restock_Baby_Breath_rand.restock) > 4095) begin
            dram_Baby_Breath[11:0]  = 'd4095;
            dram_Baby_Breath[12]    = 1;
        end
        else begin
            dram_Baby_Breath[11:0]  = dram_Baby_Breath[11:0] + restock_Baby_Breath_rand.restock;
            dram_Baby_Breath[12]    = 0;
        end
        // @(negedge clk);
    end
endtask

task check_ans_supply_task;
    begin
    // @(negedge clk);
    if (dram_Rose[12] != 0 || dram_Lily[12] != 0 || dram_Carnation[12] != 0 || dram_Baby_Breath[12] != 0) begin
        golden_warn_msg = 2'b11;
        golden_complete = 'b0;
    end
    else begin 
        golden_warn_msg = 2'b00;
        golden_complete = 'b1;
    end
    // @(negedge clk);
    end
endtask


task wait_out_valid_task; begin
    latency = -1;
    while(inf.out_valid !== 1'b1) begin
        latency = latency + 1;
    	if(latency == CYCLE_DELAY) begin
            $display("--------------------------------------------------------------------------------");
            $display("     ▄▀▀▄▀▀▀▀▀▀▄▀▀▄                                                   ");
            $display("    ▄▀            ▀▄      ▄▄                                          ");
            $display("    █  ▀   ▀       ▀▄▄   █  █          Wrong Answer                         ");
            $display("    █   ▀▀            ▀▀▀   ▀▄  ╭   The execution cycles are over %3d\033[m", CYCLE_DELAY);
            $display("    █  ▄▀▀▀▄                 █  ╭                                        ");
            $display("    ▀▄                       █                                           ");
            $display("     █   ▄▄   ▄▄▄▄▄    ▄▄   █                                           ");
            $display("     ▀▄▄▀ ▀▀▄▀     ▀▄▄▀  ▀▄▀                                            ");
            $display("--------------------------------------------------------------------------------");
			repeat(2)@(negedge clk);
			$finish;
    	end
    	@(negedge clk);
   	end
    if(latency === 0) latency = 1;
    total_latency = total_latency + latency;
end endtask

task check_task ; begin 
	if((inf.complete !== golden_complete) || (inf.warn_msg !== golden_warn_msg)) begin 
        $display ("--------------------------------------------------------------------------------------------");
        $display ("                                  fail pattern: %d                                          ", i_pat);
        $display ("                                  GOLDEN_ERR_MSG: %d                                        ", golden_warn_msg);
        $display ("                                  GOLDEN_COMPLETE: %d                                       ", golden_complete);
        $display ("                                  YOUR_ERR_MSG: %d                                          ", inf.warn_msg);
        $display ("                                  YOUR_COMPLETE: %d                                         ", inf.complete);
        $display ("                                     Wrong Answer                                           ");
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

