module BEV(input clk, INF.BEV_inf inf);
import usertype::*;
// This file contains the definition of several state machines used in the BEV (Beverage) System RTL design.
// The state machines are defined using SystemVerilog enumerated type_span.
// The state machines are:
// - state_t: used to represent the overall state of the BEV system
//
// Each enumerated type defines a set of named states that the corresponding process can be in.
typedef enum logic [3:0]{
    IDLE,
    LOAD,
    MAKE_DRINK,
    SUPPLY,
    CHECK_DATE,
    CHECK_ENOUGH ,
    WRITE_BACK,
    OUTPUT
} state_t;

// typedef enum logic [3:0]{
//     BLACK_TEA,
//     MILK_TEA,
//     EXTRA_MILK_TEA,
//     GREEN_TEA,
//     GREEN_MILK_TEA,
//     PINEAPPLE_JUICE ,
//     SUPER_PINEAPPLE_TEA,
//     SUPER_PINEAPPLE_MILK_TEA
// } Drink_Type;
/*
// REGISTERS
state_t state, nstate;

// STATE MACHINE
always_ff @( posedge clk or negedge inf.rst_n) begin : TOP_FSM_SEQ
    if (!inf.rst_n) state <= IDLE;
    else state <= nstate;
end

always_comb begin : TOP_FSM_COMB
    case(state)
        IDLE: begin
            if (inf.sel_action_valid)
            begin
                case(inf.D.d_act[0])
                    Make_drink: nstate = MAKE_DRINK;
                    Supply: nstate = SUPPLY;
                    Check_Valid_Date: nstate = CHECK_DATE;
                    default: nstate = IDLE;
                endcase
            end
            else
            begin
                nstate = IDLE;
            end
        end
        default: nstate = IDLE;
    endcase
end

always_ff @( posedge clk or negedge inf.rst_n) begin : MAKE_DRINK_FSM_SEQ
    if (!inf.rst_n) make_state <= IDLE_M;
    else make_state <= make_nstate;
end
*/

//======================================
//            Register
//======================================
state_t       current_state, next_state;
Action        action_span;
logic[2:0]    supply_cnt;
logic[3:0]    Month;
logic[4:0]    Day;
Bev_Type type_span;
Bev_Size size_span;
// logic[15:0]   size_beverage
logic[11:0]   Supply_Black_Tea;// Black Tea -> Green Tea -> Milk -> Pineapple Juice
logic[11:0]   Supply_Green_Tea;
logic[11:0]   Supply_Milk;
logic[11:0]   Supply_Pineapple_Juice;
logic [11:0]  need_black_tea, need_green_tea, need_milk, need_pine ;
// logic [63:0]  DRAM_data ;
logic [12:0] DRAM_Black_Tea, DRAM_Green_Tea, DRAM_Mike, DRAM_Pineapple_Juice ;
logic [7:0]  DRAM_Expired_Month, DRAM_Expired_Day ;
logic out_valid_flag;
logic [3:0] valid_count;
logic err_or_not;
// logic debug;
//logic box_no_valid_flag;
integer  i;

// always_ff @ ( posedge clk or negedge inf.rst_n) begin //: BEV_FSM_SWITCH
//     if (!inf.rst_n) debug <= 0;
//     else if (inf.C_addr == 'hb0 & debug == 0) debug <= 1;
//     else if (inf.C_addr == 'hb0 & debug == 1) debug <= 0;
//     else debug <= debug;
// end
//======================================
//              FSM
//======================================
always_ff @ ( posedge clk or negedge inf.rst_n) begin //: BEV_FSM_SWITCH
    if (!inf.rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always_comb begin //: BEV_FSM
    case(current_state)
        IDLE: begin
            if (inf.sel_action_valid) next_state = LOAD ;
            else next_state = current_state ;
        end
        LOAD: begin
            if (valid_count == 5 & out_valid_flag == 1 & action_span == 0) next_state = CHECK_DATE ;
            else if (valid_count == 7 & out_valid_flag == 1 & action_span == 1) next_state = SUPPLY ;
            else if (valid_count == 3 & out_valid_flag == 1 & action_span == 2) next_state = CHECK_DATE ;
            else next_state = current_state ;
        end
        MAKE_DRINK: begin
            next_state = WRITE_BACK;
            // if (inf.sel_action_valid & D = 0) next_state = MAKE_DRINK ;
            // else next_state = IDLE ;
        end
        SUPPLY: begin
            next_state = WRITE_BACK;
        end
        CHECK_DATE: begin
            //next_state = WRITE_BACK;
            if (action_span == 0) begin
                if(Month == DRAM_Expired_Month & Day > DRAM_Expired_Day) next_state = OUTPUT ;
                else if(Month > DRAM_Expired_Month) next_state = OUTPUT ;
                else next_state = CHECK_ENOUGH ;
            end
            else if (action_span == 2) next_state = OUTPUT ;
            else next_state = current_state;
        end
        CHECK_ENOUGH: begin
            if(DRAM_Pineapple_Juice < need_pine) next_state = OUTPUT ;
            else if(DRAM_Black_Tea < need_black_tea) next_state = OUTPUT ;
            else if(DRAM_Green_Tea < need_green_tea) next_state = OUTPUT ;
            else if(DRAM_Mike < need_milk) next_state = OUTPUT ;
            else next_state = MAKE_DRINK ;
        end
		WRITE_BACK:begin
            if (out_valid_flag == 1) next_state = OUTPUT ;
            else next_state = current_state ;
        end
        OUTPUT:begin
            if (inf.out_valid == 1) next_state = IDLE ;
            else next_state = current_state ;
        end
        default: next_state = current_state;
    endcase
end


//======================================
//            DRAM Control
//======================================
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) inf.C_addr <= 0;
    else if (current_state == OUTPUT) inf.C_addr <= 0;
    else if(inf.box_no_valid) inf.C_addr <= inf.D.d_box_no[0];
    else inf.C_addr <= inf.C_addr ;
end

logic C_in_valid_onoff;
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) begin
        inf.C_in_valid <= 0;
    end
    else if(inf.box_no_valid & current_state == LOAD)  begin
        inf.C_in_valid <= 1;
    end
    else if(!inf.box_no_valid & current_state == LOAD)  begin
        inf.C_in_valid <= 0;
    end
    else if(current_state == WRITE_BACK & !inf.C_in_valid & !C_in_valid_onoff)  begin
        inf.C_in_valid <= 1;
    end
    else if(current_state == WRITE_BACK & inf.C_in_valid & C_in_valid_onoff)  begin
        inf.C_in_valid <= 0;
    end
    else  begin
        inf.C_in_valid <= inf.C_in_valid;
    end
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) begin
        C_in_valid_onoff <= 0 ;
    end
    else if (current_state == IDLE) begin
        C_in_valid_onoff <= 0 ;
    end
    else if(current_state == WRITE_BACK & !inf.C_in_valid)  begin;
        C_in_valid_onoff <= 1 ;
    end
    else  begin
        C_in_valid_onoff <= C_in_valid_onoff ;
    end
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) inf.C_r_wb <= 0;
    else if (current_state == OUTPUT) inf.C_r_wb <= 0;
    else if(current_state == IDLE) inf.C_r_wb <= 0;
    else if(current_state == LOAD) inf.C_r_wb <= 1;
    else if(current_state == WRITE_BACK) inf.C_r_wb <= 0;
    //else if(current_state == CHECK_DATE) inf.C_r_wb <= 0;
    else inf.C_r_wb <= inf.C_r_wb ;
end


//======================================
//           DRAM Data Input
//======================================
//////////All Valid In or Not////////////
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) valid_count <= 1;
    else if ((current_state == IDLE)) valid_count <= 1;
    //else if(inf.C_out_valid == 1) valid_count <= valid_count + 1 ;
    else if(inf.sel_action_valid == 1) valid_count <= valid_count + 1 ;
    else if(inf.type_valid == 1) valid_count <= valid_count + 1 ;
    else if(inf.size_valid == 1) valid_count <= valid_count + 1 ;
    else if(inf.date_valid == 1) valid_count <= valid_count + 1 ;
    else if(inf.box_no_valid == 1) valid_count <= valid_count + 1 ;
    else if(inf.box_sup_valid == 1) valid_count <= valid_count + 1 ;
    else valid_count <= valid_count ;
end

//////////Out Valid Flag////////////
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) out_valid_flag <= 0;
    else if(inf.C_out_valid == 1 & current_state == LOAD) out_valid_flag <= 1 ;
    else if(inf.C_out_valid == 1 & current_state == WRITE_BACK) out_valid_flag <= 1 ;
    else if(current_state == WRITE_BACK | current_state == LOAD) out_valid_flag <= out_valid_flag ;
    else out_valid_flag <= 0 ;
end

// always_ff @ ( posedge clk or negedge inf.rst_n) begin 
//     if (!inf.rst_n) box_no_valid_flag <= 0;
//     else if(inf.box_no_valid == 1 & current_state == LOAD) box_no_valid_flag <= 1 ;
//     else box_no_valid_flag <= 0 ;
// end
//////////Type////////////
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) type_span <= 0;
    else if(current_state == LOAD & inf.type_valid) type_span <= inf.D.d_type[0];
    else type_span <= type_span ;
end

//////////Size////////////
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) size_span <= 0;
    else if(current_state == LOAD & inf.size_valid) size_span <= inf.D.d_size[0];
    else size_span <= size_span ;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) need_black_tea <= 0;
    else if(type_span == 0) begin
        if(size_span == 0) need_black_tea <= 960;
        else if(size_span == 1) need_black_tea <= 720;
        else if(size_span == 3) need_black_tea <= 480;
    end
    else if(type_span == 1) begin
        if(size_span == 0) need_black_tea <= 720;
        else if(size_span == 1) need_black_tea <= 540;
        else if(size_span == 3) need_black_tea <= 360;
    end
    else if(type_span == 2) begin
        if(size_span == 0) need_black_tea <= 480;
        else if(size_span == 1) need_black_tea <= 360;
        else if(size_span == 3) need_black_tea <= 240;
    end
    else if(type_span == 6) begin
        if(size_span == 0) need_black_tea <= 480;
        else if(size_span == 1) need_black_tea <= 360;
        else if(size_span == 3) need_black_tea <= 240;
    end
    else if(type_span == 7) begin
        if(size_span == 0) need_black_tea <= 480;
        else if(size_span == 1) need_black_tea <= 360;
        else if(size_span == 3) need_black_tea <= 240;
    end
    else need_black_tea <= 0 ;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) need_green_tea <= 0;
    else if(type_span == 3) begin
        if(size_span == 0)      need_green_tea <= 960;
        else if(size_span == 1) need_green_tea <= 720;
        else if(size_span == 3) need_green_tea <= 480;
    end
    else if(type_span == 4) begin
        if(size_span == 0)      need_green_tea <= 480;
        else if(size_span == 1) need_green_tea <= 360;
        else if(size_span == 3) need_green_tea <= 240;
    end
    else need_green_tea <= 0 ;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) need_milk <= 0;
    else if(type_span == 1) begin
        if(size_span == 0)      need_milk <= 240;
        else if(size_span == 1) need_milk <= 180;
        else if(size_span == 3) need_milk <= 120;
    end
    else if(type_span == 2) begin
        if(size_span == 0)      need_milk <= 480;
        else if(size_span == 1) need_milk <= 360;
        else if(size_span == 3) need_milk <= 240;
    end
    else if(type_span == 4) begin
        if(size_span == 0)      need_milk <= 480;
        else if(size_span == 1) need_milk <= 360;
        else if(size_span == 3) need_milk <= 240;
    end
    else if(type_span == 7) begin
        if(size_span == 0)      need_milk <= 240;
        else if(size_span == 1) need_milk <= 180;
        else if(size_span == 3) need_milk <= 120;
    end
    else need_milk <= 0 ;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) need_pine <= 0;
    else if(type_span == 5) begin
        if(size_span == 0)      need_pine <= 960;
        else if(size_span == 1) need_pine <= 720;
        else if(size_span == 3) need_pine <= 480;
    end
    else if(type_span == 6) begin
        if(size_span == 0)      need_pine <= 480;
        else if(size_span == 1) need_pine <= 360;
        else if(size_span == 3) need_pine <= 240;
    end
    else if(type_span == 7) begin
        if(size_span == 0)      need_pine <= 240;
        else if(size_span == 1) need_pine <= 180;
        else if(size_span == 3) need_pine <= 120;
    end
    else need_pine <= 0 ;
end

//////////Date////////////
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) Day <= 0;
    else if(current_state == LOAD & inf.date_valid) Day <= inf.D.d_date[0].D[4:0];
    else Day <= Day ;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) Month <= 0;
    else if(current_state == LOAD & inf.date_valid) Month <= inf.D.d_date[0].M[3:0];
    else Month <= Month ;
end
//////////Action////////////
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) action_span <= 3;
    else if(inf.sel_action_valid) action_span <= inf.D.d_act[0];
    else action_span <= action_span ;
end
////////Supply////////////
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) supply_cnt <= 0 ;
    else if (current_state == IDLE) supply_cnt <= 0 ;
    else if(inf.box_sup_valid) begin
        supply_cnt <= supply_cnt + 1;
    end
    else begin
        supply_cnt <= supply_cnt ;
    end
end
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) begin
        Supply_Black_Tea       <= 0 ;
        Supply_Green_Tea       <= 0 ;
        Supply_Milk            <= 0 ;
        Supply_Pineapple_Juice <= 0 ;
    end
    else if(inf.box_sup_valid) begin
        if(supply_cnt == 0) Supply_Black_Tea            <= inf.D.d_ing[0] ;
        else if(supply_cnt == 1) Supply_Green_Tea       <= inf.D.d_ing[0] ;
        else if(supply_cnt == 2) Supply_Milk            <= inf.D.d_ing[0] ;
        else if(supply_cnt == 3) Supply_Pineapple_Juice <= inf.D.d_ing[0] ;
    end
    else begin
        Supply_Black_Tea       <= Supply_Black_Tea       ;
        Supply_Green_Tea       <= Supply_Green_Tea       ;
        Supply_Milk            <= Supply_Milk            ;
        Supply_Pineapple_Juice <= Supply_Pineapple_Juice ;
    end
end
////////Data////////////
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) DRAM_Expired_Day <= 0;
    else if (current_state == IDLE) DRAM_Expired_Day <= 0;
    else if(current_state == LOAD & inf.C_r_wb & inf.C_out_valid) DRAM_Expired_Day <= inf.C_data_r[7:0];
    else if(current_state == SUPPLY) DRAM_Expired_Day <= Day;
    else DRAM_Expired_Day <= DRAM_Expired_Day ;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) DRAM_Pineapple_Juice <= 0;
    else if (current_state == IDLE) DRAM_Pineapple_Juice <= 0;
    else if(current_state == LOAD & inf.C_r_wb & inf.C_out_valid) begin
        // DRAM_Pineapple_Juice[11:8] <= inf.C_data_r[23:20];
        // DRAM_Pineapple_Juice[7:0] <= inf.C_data_r[15:8];
        DRAM_Pineapple_Juice <= inf.C_data_r[19:8];
    end
    else if(current_state == SUPPLY) begin
        if((Supply_Pineapple_Juice + DRAM_Pineapple_Juice) > 4095) begin
            DRAM_Pineapple_Juice[11:0] <= 12'd4095 ;
            DRAM_Pineapple_Juice[12] <= 1;
        end
        else DRAM_Pineapple_Juice <= Supply_Pineapple_Juice + DRAM_Pineapple_Juice ;
    end
    else if(current_state == MAKE_DRINK) DRAM_Pineapple_Juice <= DRAM_Pineapple_Juice - need_pine;
    else DRAM_Pineapple_Juice <= DRAM_Pineapple_Juice ;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) DRAM_Mike <= 0;
    else if (current_state == IDLE) DRAM_Mike <= 0;
    else if(current_state == LOAD & inf.C_r_wb & inf.C_out_valid) begin
        // DRAM_Mike[11:4] <= inf.C_data_r[31:24];
        // DRAM_Mike[3:0] <= inf.C_data_r[19:16];
        DRAM_Mike <= inf.C_data_r[31:20];
    end
    else if(current_state == SUPPLY) begin
        if((DRAM_Mike + Supply_Milk) > 4095) begin
            DRAM_Mike[11:0] <= 12'd4095 ;
            DRAM_Mike[12] <= 1;
        end
        else DRAM_Mike <= DRAM_Mike + Supply_Milk;
    end
    else if(current_state == MAKE_DRINK) DRAM_Mike <= DRAM_Mike - need_milk;
    else DRAM_Mike <= DRAM_Mike ;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) DRAM_Expired_Month <= 0;
    else if (current_state == IDLE) DRAM_Expired_Month <= 0;
    else if(current_state == LOAD & inf.C_r_wb & inf.C_out_valid) DRAM_Expired_Month <= inf.C_data_r[39:32];
    else if(current_state == SUPPLY) DRAM_Expired_Month <= Month;
    else DRAM_Expired_Month <= DRAM_Expired_Month ;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) DRAM_Green_Tea <= 0;
    else if (current_state == IDLE) DRAM_Green_Tea <= 0;
    else if(current_state == LOAD & inf.C_r_wb & inf.C_out_valid) begin
        // DRAM_Green_Tea[11:8] <= inf.C_data_r[55:52];
        // DRAM_Green_Tea[7:0] <= inf.C_data_r[47:40];
        DRAM_Green_Tea <= inf.C_data_r[51:40];
    end
    else if(current_state == SUPPLY) begin
        if((Supply_Green_Tea + DRAM_Green_Tea) > 4095)  begin
            DRAM_Green_Tea[11:0] <= 12'd4095 ;
            DRAM_Green_Tea[12] <= 1;
        end
        else DRAM_Green_Tea <= Supply_Green_Tea + DRAM_Green_Tea;
    end
    else if(current_state == MAKE_DRINK) DRAM_Green_Tea <= DRAM_Green_Tea - need_green_tea;
    else DRAM_Green_Tea <= DRAM_Green_Tea ;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) DRAM_Black_Tea <= 0;
    else if (current_state == IDLE) DRAM_Black_Tea <= 0;
    else if(current_state == LOAD & inf.C_r_wb & inf.C_out_valid) begin
        // DRAM_Black_Tea[11:4] <= inf.C_data_r[63:56];
        // DRAM_Black_Tea[3:0] <= inf.C_data_r[51:48];
        DRAM_Black_Tea <= inf.C_data_r[63:52];
    end
    else if(current_state == SUPPLY) begin
        if((Supply_Black_Tea + DRAM_Black_Tea) > 4095)  begin
            DRAM_Black_Tea[11:0] <= 12'd4095 ;
            DRAM_Black_Tea[12] <= 1;
        end
        else DRAM_Black_Tea <= Supply_Black_Tea + DRAM_Black_Tea;
    end
    else if(current_state == MAKE_DRINK) DRAM_Black_Tea <= DRAM_Black_Tea - need_black_tea;
    else DRAM_Black_Tea <= DRAM_Black_Tea ;
end


//======================================
//         Output to DRAM Data
//======================================
always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) inf.C_data_w[7:0] <= 0;
    else if(current_state == WRITE_BACK) inf.C_data_w[7:0] <= DRAM_Expired_Day ;
    else inf.C_data_w[7:0] <= inf.C_data_w[7:0] ;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) begin
        inf.C_data_w[19:8] <= 0;
    end
    else if(current_state == WRITE_BACK) begin
        inf.C_data_w[19:8] <= DRAM_Pineapple_Juice;
    end
    else begin
        inf.C_data_w[19:8] <= inf.C_data_w[19:8] ;
    end
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n)  begin
        inf.C_data_w[31:20] <= 0;
    end
    else if (current_state == IDLE)  begin
        inf.C_data_w[31:20] <= 0;
    end
    else if(current_state == WRITE_BACK) begin
        inf.C_data_w[31:20] <= DRAM_Mike;
    end
    else begin
        inf.C_data_w[31:20] <= inf.C_data_w[31:20] ;
    end
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) inf.C_data_w[39:32] <= 0 ;
    else if(current_state == WRITE_BACK) inf.C_data_w[39:32] <= DRAM_Expired_Month ;
    else inf.C_data_w[39:32] <= inf.C_data_w[39:32] ;
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) begin
        inf.C_data_w[51:40] <= 0;
    end
    else if(current_state == WRITE_BACK) begin
        inf.C_data_w[51:40] <= DRAM_Green_Tea;
    end
    else begin
        inf.C_data_w[51:40] <= inf.C_data_w[51:40];
    end
end

always_ff @ ( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) begin
        inf.C_data_w[63:52] <= 0 ;
    end
    else if(current_state == WRITE_BACK) begin
        inf.C_data_w[63:52] <= DRAM_Black_Tea;
    end
    else begin
        inf.C_data_w[63:52] <= inf.C_data_w[63:52] ;
    end
end


//======================================
//              Output
//======================================
// always_ff @ ( posedge clk or negedge inf.rst_n) begin 
//     if (!inf.rst_n) begin
//         out_valid_onoff <= 0 ;
//     end
//     else if (current_state == IDLE) begin
//         out_valid_onoff <= 0 ;
//     end
//     else if(current_state == OUTPUT & !inf.C_in_valid)  begin;
//         out_valid_onoff <= 1 ;
//     end
//     else  begin
//         out_valid_onoff <= out_valid_onoff ;
//     end
// end

// always_ff @( posedge clk or negedge inf.rst_n) begin 
//     if (!inf.rst_n) begin 
// 		inf.err_msg  <= No_Err ;
// 	end
//     else if(current_state == WRITE_BACK) begin
//         //check overflow
//         if(DRAM_Pineapple_Juice[12] == 1 | DRAM_Mike[12] == 1 | DRAM_Green_Tea[12] == 1 | DRAM_Black_Tea[12] == 1)
//             inf.err_msg <= Ing_OF;
//             else inf.err_msg  <= No_Err ;
//     end
//     else if(current_state == CHECK_DATE) begin
//         //check date
//         if(Month <= DRAM_Expired_Month & Day >= DRAM_Expired_Day) inf.err_msg <= No_Exp ;
//         else if(Month >= DRAM_Expired_Month) inf.err_msg <= No_Exp ;
//         else inf.err_msg  <= No_Err ;
//     end
//     else if(current_state == CHECK_ENOUGH) begin
//         //check ingredient enough
//         if(type_span == 0) begin
//             if(DRAM_Black_Tea < 1) inf.err_msg <= No_Ing ;
//             else inf.err_msg  <= No_Err ;
//         end
//         else if(type_span == 1) begin
//             if(DRAM_Black_Tea < 3 | DRAM_Mike < 1) inf.err_msg <= No_Ing ;
//             else inf.err_msg  <= No_Err ;
//         end
//         else if(type_span == 2) begin
//             if(DRAM_Black_Tea < 1 | DRAM_Mike < 1) inf.err_msg <= No_Ing ;
//             else inf.err_msg  <= No_Err ;
//         end
//         else if(type_span == 3) begin
//             if(DRAM_Green_Tea < 1) inf.err_msg <= No_Ing ;
//             else inf.err_msg  <= No_Err ;
//         end
//         else if(type_span == 4) begin
//             if(DRAM_Green_Tea < 1 | DRAM_Mike < 1) inf.err_msg <= No_Ing ;
//             else inf.err_msg  <= No_Err ;
//         end
//         else if(type_span == 5) begin
//             if(DRAM_Pineapple_Juice < 1) inf.err_msg <= No_Ing ;
//             else inf.err_msg  <= No_Err ;
//         end
//         else if(type_span == 6) begin
//             if(DRAM_Black_Tea < 1 | DRAM_Pineapple_Juice < 1) inf.err_msg <= No_Ing ;
//             else inf.err_msg  <= No_Err ;
//         end
//         else if(type_span == 7) begin
//             if(DRAM_Black_Tea < 2 | DRAM_Pineapple_Juice < 1 | DRAM_Mike < 1) inf.err_msg <= No_Ing ;
//             else inf.err_msg  <= No_Err ;
//         end
//     end
//     else if(current_state == OUTPUT & inf.out_valid == 1) inf.err_msg  <= No_Err ;
//     else begin 
// 	    inf.err_msg  <= inf.err_msg ;
// 	end 
// end
always_ff @ ( posedge clk or negedge inf.rst_n) begin //: BEV_FSM_SWITCH
    if (!inf.rst_n) err_or_not <= 0;
    else if (current_state == IDLE) err_or_not <= 0;
    else if(current_state == CHECK_ENOUGH & action_span == 0 & DRAM_Pineapple_Juice < need_pine) err_or_not <= 1;
    else if(current_state == CHECK_ENOUGH & action_span == 0 & DRAM_Black_Tea < need_black_tea)  err_or_not <= 1;
    else if(current_state == CHECK_ENOUGH & action_span == 0 & DRAM_Green_Tea < need_green_tea)  err_or_not <= 1;
    else if(current_state == CHECK_ENOUGH & action_span == 0 & DRAM_Mike < need_milk) err_or_not <= 1;
    else err_or_not <= err_or_not;
end

always_comb begin 
    if (!inf.rst_n) begin 
		inf.err_msg  = No_Err ;
	end
    else if(inf.out_valid == 0) inf.err_msg  = No_Err ;
    else if(inf.out_valid == 1) begin
        //check overflow 
        if(action_span == 1 & DRAM_Pineapple_Juice[12] == 1 | DRAM_Mike[12] == 1 
        | DRAM_Green_Tea[12] == 1 | DRAM_Black_Tea[12] == 1)
            inf.err_msg = Ing_OF;
        //check date
        else if((Month == DRAM_Expired_Month) & (Day > DRAM_Expired_Day)) inf.err_msg = No_Exp ;
        else if((Month > DRAM_Expired_Month)) inf.err_msg = No_Exp ;
        //check needing enough
        // else if(action_span == 0 & DRAM_Pineapple_Juice < need_pine) inf.err_msg = No_Ing ;
        // else if(action_span == 0 & DRAM_Black_Tea < need_black_tea)  inf.err_msg = No_Ing ;
        // else if(action_span == 0 & DRAM_Green_Tea < need_green_tea)  inf.err_msg = No_Ing ;
        // else if(action_span == 0 & DRAM_Mike < need_milk) inf.err_msg = No_Ing ;
        else if(action_span == 0 & err_or_not) inf.err_msg = No_Ing ;
        else inf.err_msg  = No_Err ;
    end
    // else if(inf.out_valid == 1) begin
        
    // end
    // else if(current_state == CHECK_ENOUGH) begin
    //     //check ingredient enough
    //     if(type_span == 0) begin
    //         if(DRAM_Black_Tea < 1) inf.err_msg <= No_Ing ;
    //         else inf.err_msg  <= No_Err ;
    //     end
    //     else if(type_span == 1) begin
    //         if(DRAM_Black_Tea < 3 | DRAM_Mike < 1) inf.err_msg <= No_Ing ;
    //         else inf.err_msg  <= No_Err ;
    //     end
    //     else if(type_span == 2) begin
    //         if(DRAM_Black_Tea < 1 | DRAM_Mike < 1) inf.err_msg <= No_Ing ;
    //         else inf.err_msg  <= No_Err ;
    //     end
    //     else if(type_span == 3) begin
    //         if(DRAM_Green_Tea < 1) inf.err_msg <= No_Ing ;
    //         else inf.err_msg  <= No_Err ;
    //     end
    //     else if(type_span == 4) begin
    //         if(DRAM_Green_Tea < 1 | DRAM_Mike < 1) inf.err_msg <= No_Ing ;
    //         else inf.err_msg  <= No_Err ;
    //     end
    //     else if(type_span == 5) begin
    //         if(DRAM_Pineapple_Juice < 1) inf.err_msg <= No_Ing ;
    //         else inf.err_msg  <= No_Err ;
    //     end
    //     else if(type_span == 6) begin
    //         if(DRAM_Black_Tea < 1 | DRAM_Pineapple_Juice < 1) inf.err_msg <= No_Ing ;
    //         else inf.err_msg  <= No_Err ;
    //     end
    //     else if(type_span == 7) begin
    //         if(DRAM_Black_Tea < 2 | DRAM_Pineapple_Juice < 1 | DRAM_Mike < 1) inf.err_msg <= No_Ing ;
    //         else inf.err_msg  <= No_Err ;
    //     end
    // end
    else begin 
	    inf.err_msg  = No_Err ;
	end 
end

//logic out_valid_onoff;
always_ff @( posedge clk or negedge inf.rst_n) begin 
    if (!inf.rst_n) begin 
		inf.out_valid <= 0 ;
	end
    // else if(current_state == OUTPUT & inf.out_valid == 0 & out_valid_onoff == 0) inf.out_valid <= 1 ;
    //else if(current_state == CHECK_DATE & next_state == OUTPUT & inf.out_valid == 0) inf.out_valid <= 1 ;
    else if(current_state == OUTPUT & inf.out_valid == 0) inf.out_valid <= 1 ;
    else if(inf.out_valid == 1) inf.out_valid <= 0 ;
    else begin 
		inf.out_valid <= 0 ;
	end 
end

// always_ff @( posedge clk or negedge inf.rst_n) begin 
//     if (!inf.rst_n) begin 
// 		inf.complete <= 0 ;
// 	end
//     // else if(current_state == CHECK_DATE & next_state == OUTPUT) begin
//     //     if(inf.err_msg == No_Err & inf.complete == 0) inf.complete <= 1;
//     //     else if(inf.complete == 1) inf.complete <= 0;
//     // end
//     else if(current_state == OUTPUT) begin
//         if(inf.err_msg == No_Err & inf.complete == 0) inf.complete <= 1;
//         else if(inf.complete == 1) inf.complete <= 0;
//     end
//     else begin 
// 		inf.complete <= 0 ;
// 	end 
// end

always_comb begin 
    if (!inf.rst_n) begin 
		inf.complete = 0 ;
	end
    // else if(current_state == CHECK_DATE & next_state == OUTPUT) begin
    //     if(inf.err_msg == No_Err & inf.complete == 0) inf.complete <= 1;
    //     else if(inf.complete == 1) inf.complete <= 0;
    // end
    else if(inf.out_valid == 0) inf.complete = 0 ;
    else if(inf.out_valid == 1) begin
        if(inf.err_msg == No_Err & inf.complete == 0) inf.complete = 1;
        else inf.complete = 0 ;
        //else if(inf.complete == 1) inf.complete <= 0;
    end
    else begin 
		inf.complete = 0 ;
	end 
end
endmodule
