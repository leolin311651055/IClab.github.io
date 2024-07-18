//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Midterm Proejct            : MRA  
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
	     arid_m_inf,
	   araddr_m_inf,
	    arlen_m_inf,
	   arsize_m_inf,
	  arburst_m_inf,
	  arvalid_m_inf,
	  arready_m_inf,
	
	      rid_m_inf,
	    rdata_m_inf,
	    rresp_m_inf,
	    rlast_m_inf,
	   rvalid_m_inf,
	   rready_m_inf,
	
	     awid_m_inf,
	   awaddr_m_inf,
	   awsize_m_inf,
	  awburst_m_inf,
	    awlen_m_inf,
	  awvalid_m_inf,
	  awready_m_inf,
	
	    wdata_m_inf,
	    wlast_m_inf,
	   wvalid_m_inf,
	   wready_m_inf,
	
	      bid_m_inf,
	    bresp_m_inf,
	   bvalid_m_inf,
	   bready_m_inf 
) ;

// ===============================================================
//  					Input / Output 
// ===============================================================
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 128 ;
// << CHIP io port with system >>
input 			  	clk,rst_n ;
input 			   	in_valid ;
input  [4:0] 		frame_id ;	//which map
input  [3:0]       	net_id ;     //value of target 
input  [5:0]       	loc_x ; 
input  [5:0]       	loc_y ; 
output reg [13:0] 	cost ;
output reg          busy ;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...) ;
*/

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf ; //maybe set 0, btw ID_WIDTH = 4
output wire [1:0]            arburst_m_inf ; //maybe set 1
output wire [2:0]             arsize_m_inf ; //each graph elemant size, maybe give 4
output wire [7:0]              arlen_m_inf ; //size, maybe give 127(0...127)
output wire                  arvalid_m_inf ; 
input  wire                  arready_m_inf ;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf ;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf ; //not used
input  wire                   rvalid_m_inf ;
output wire                   rready_m_inf ; //maybe set 1, we can read data immediately
input  wire [DATA_WIDTH-1:0]   rdata_m_inf ; 
input  wire                    rlast_m_inf ; //the last data will be delivered
input  wire [1:0]              rresp_m_inf ; //not used
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf ; //maybe set 0, btw ID_WIDTH = 4
output wire [1:0]            awburst_m_inf ; //maybe set 1
output wire [2:0]             awsize_m_inf ; //each graph elemant size, maybe give 4
output wire [7:0]              awlen_m_inf ; //size, maybe give 127(0...127)
output wire                  awvalid_m_inf ;
input  wire                  awready_m_inf ;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf ;
// -------------------------
// (2)	axi write data channel 
output wire                   wvalid_m_inf ;
input  wire                   wready_m_inf ;
output wire [DATA_WIDTH-1:0]   wdata_m_inf ;
output wire                    wlast_m_inf ;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf ; //not used
input  wire                   bvalid_m_inf ; //meant DRAM store done
output wire                   bready_m_inf ; //maybe set 1
input  wire  [1:0]             bresp_m_inf ; //not used
// -----------------------------

//===============================================================================
//                            register and parameter
//== =============================================================================
reg   [4:0]   frame_id_span ;
reg   [3:0]   done ;
reg   [3:0]   net_cnt ;
reg   [3:0]   net_id_span [15:0] ;     
reg   [13:0]  loc_x_start [15:0] ;
reg   [13:0]  loc_y_start [15:0] ;
reg   [13:0]  loc_x_end   [15:0] ;
reg   [13:0]  loc_y_end   [15:0] ;
// reg   [13:0]  loc_x_back ;
// reg   [13:0]  loc_y_back ;
wire  [13:0]  loc_y_back_down ;
wire  [13:0]  loc_x_back_left ;
wire  [13:0]  loc_y_back_up ;
wire  [13:0]  loc_x_back_right ;
assign 		  loc_y_back_down  = loc_y_end[done] + 1;
assign 		  loc_y_back_up    = loc_y_end[done] - 1;
assign 		  loc_x_back_left  = loc_x_end[done] - 1;
assign 		  loc_x_back_right = loc_x_end[done] + 1;
reg           ends ;

reg  [15:0]  current_state,next_state ;
reg  [7:0]  counter ;
wire [7:0]  counter_t1 ;
wire [7:0]  counter_t2 ;
wire [7:0]  counter_t3 ;
wire [7:0]  counter_t4 ;
assign 		 counter_t1 = counter + 1;
assign 		 counter_t2 = counter - 1;
assign 		 counter_t3 = counter >> 7;
reg  [1:0]   map[0:63][0:63] ; //0 : space  ; 1 : obstacles  ; 2, 3 : mapping

 
reg  [6:0]   label_addr ;
reg  [127:0] label_out,label_in ;
reg  		 WEN_label ;  
 
reg  [6:0]   wei_addr ;
reg  [127:0] wei_out,wei_in ;
reg	         WEN_weight ; 

parameter    IDLE            = 0  ;
parameter    INPUT           = 1  ;
parameter    LOADLABEL       = 2  ;
parameter    LOADWEIGHT      = 3  ;
parameter    CREATMAP        = 4  ;
parameter    PATHING         = 5  ;
parameter    GOBACK          = 6  ;
parameter    GOBACK_DELAY    = 7  ;
parameter    GOBACK_DELAY_2  = 8  ;
parameter    FINDNEXTSTATE   = 9  ;
parameter    BACKTODRAM      = 10 ;
parameter    OUTPUT          = 11 ;

integer i,j ;
assign counter_t4 = (!rst_n) ? 0 :
                    (counter == 0 || counter == 1) ? 2 :
                    (counter == 2 || counter == 3) ? 3 :
                    0;
//===============================================================================
//                                    FSM
//===============================================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        current_state <= IDLE ;
    end
    else begin
        current_state <= next_state ;
    end
end

always@(*) begin
	if(!rst_n) next_state = IDLE ;
	else begin
		case(current_state)
			IDLE : begin
				if(in_valid) next_state = INPUT ;
				else next_state = current_state ;
			end
			INPUT : begin
				if(!in_valid) next_state = LOADLABEL ;
				else next_state = current_state ;
			end
			LOADLABEL : begin
				if(counter == 128) next_state = LOADWEIGHT ;
				else next_state = current_state ;
			end
			LOADWEIGHT : begin
				if(counter == 128) next_state = CREATMAP ;
				else next_state = current_state ;
			end
			CREATMAP : begin
				if(counter ==129) next_state = PATHING ;
				else next_state = current_state ;
			end
			PATHING : begin
				if((loc_x_end[done] + 1 == loc_x_start[done]) && (loc_y_end[done] == loc_y_start[done])) begin//stop count, when target found
					next_state = FINDNEXTSTATE ;
				end
				else if((loc_x_end[done] - 1 == loc_x_start[done]) && (loc_y_end[done] == loc_y_start[done])) begin//stop count, when target found
					next_state = FINDNEXTSTATE ;
				end
				else if((loc_x_end[done] == loc_x_start[done]) && (loc_y_end[done] + 1 == loc_y_start[done])) begin//stop count, when target found
					next_state = FINDNEXTSTATE ;
				end
				else if((loc_x_end[done] == loc_x_start[done]) && (loc_y_end[done] - 1 == loc_y_start[done])) begin//stop count, when target found
					next_state = FINDNEXTSTATE ;
				end
				else if(map[loc_x_end[done] + 1][loc_y_end[done]][1] == 1) begin//stop count, when target found
					next_state = GOBACK_DELAY ;
				end
				else if(map[loc_x_end[done] - 1][loc_y_end[done]][1] == 1) begin//stop count, when target found
					next_state = GOBACK_DELAY ;
				end
				else if(map[loc_x_end[done]][loc_y_end[done] + 1][1] == 1) begin//stop count, when target found
					next_state = GOBACK_DELAY ;
				end
				else if(map[loc_x_end[done]][loc_y_end[done] - 1][1] == 1) begin//stop count, when target found
					next_state = GOBACK_DELAY ;
				end
				else next_state = current_state ;
			end
			GOBACK_DELAY : begin
				next_state = GOBACK_DELAY_2 ;
			end
			GOBACK_DELAY_2 : begin
				next_state = GOBACK ;
			end
			GOBACK : begin
				if(!ends) next_state = FINDNEXTSTATE ;
				else next_state = GOBACK_DELAY ;
			end

			FINDNEXTSTATE : begin
				if(done == net_cnt && counter == 0) next_state = BACKTODRAM ;
				else if(done != net_cnt && counter == 0) next_state = CREATMAP ;
				else next_state = current_state ;
			end
			BACKTODRAM : begin
				if(wlast_m_inf) next_state = OUTPUT ; 
				else next_state = current_state ;
			end
			OUTPUT : begin
				if(bvalid_m_inf) next_state = IDLE ;
				else next_state = current_state ;
			end
			default : next_state = current_state ;
		endcase
	end
end

always@(posedge clk) begin
    if((in_valid && (current_state == INPUT || current_state == IDLE))) 
        counter <= counter_t1 ;
		else if((!in_valid && current_state == INPUT)) 
        counter <= 0 ;
    else if((current_state == LOADLABEL) && (rvalid_m_inf)) 
        counter <= counter_t1 ;
    else if(current_state == LOADLABEL && !(rvalid_m_inf)) 
        counter <= 0 ;
	else if((in_valid || current_state == LOADWEIGHT) && (rvalid_m_inf)) 
        counter <= counter_t1 ;
    else if(current_state == LOADWEIGHT && !(rvalid_m_inf)) 
        counter <= 0 ;
	else if(current_state == CREATMAP && counter < 129) 
        counter <= counter_t1 ;
    else if(current_state == CREATMAP && counter >= 129) 
        counter <= 0 ;
	else if(current_state == PATHING && next_state == GOBACK_DELAY) begin
        if(counter == 0) counter <= 2;
		else if(counter == 1) counter <= 3;
		else if(counter == 2) counter <= 0;
		else if(counter == 3) counter <= 1;
	end
	else if(current_state == PATHING && counter < 3 && !ends) 
        counter <= counter_t1 ;
    else if(current_state == PATHING && counter == 3 && !ends) 
        counter <= 0 ;
	else if(current_state == GOBACK_DELAY) 
		counter <= counter;
	else if(current_state == GOBACK_DELAY_2) 
		counter <= counter;
	else if(current_state == GOBACK && counter > 0 && ends) 
        counter <= counter_t2 ;
    else if(current_state == GOBACK && counter == 0 && ends) 
        counter <= 3 ;
	else if(current_state == GOBACK && counter == 0 && !ends) 
        counter <= 0 ;
	else if(current_state == FINDNEXTSTATE && counter < 1) 
        counter <= counter_t1 ;
    else if(current_state == FINDNEXTSTATE && counter >= 1) 
        counter <= 0 ;
	else if(current_state == BACKTODRAM && wready_m_inf && !wlast_m_inf) 
        counter <= counter_t1 ;
    else if(current_state == BACKTODRAM && wlast_m_inf) 
        counter <= 0 ;
    else begin
        counter <= 0 ;
    end
end

//===============================================================================
//                                 DRAM Setting
//===============================================================================
//1.AXI Lite Read Address
reg     arvalid_m_inf_reg ;
assign  arvalid_m_inf = arvalid_m_inf_reg ;
assign	arid_m_inf    = 'd0   ; 
assign	arburst_m_inf = 'd1   ;
assign	arsize_m_inf  = 'd4   ;
assign	arlen_m_inf   = 'd127 ;
//label or weight
assign  araddr_m_inf  = (current_state == LOADLABEL) ? {16'h0001 , frame_id_span , 11'd0} : {16'h0002 , frame_id_span , 11'd0}  ;//origin

always@(posedge clk or negedge rst_n) begin 
	if (!rst_n) arvalid_m_inf_reg <= 0  ;
	else if(current_state == INPUT && next_state == LOADLABEL) arvalid_m_inf_reg <= 1 ;
	else if(current_state == LOADLABEL && next_state == LOADWEIGHT) arvalid_m_inf_reg <= 1 ;
	else if(arready_m_inf) arvalid_m_inf_reg <= 0 ;
	else arvalid_m_inf_reg <= arvalid_m_inf_reg ;
end
//2.AXI Lite Read
assign rready_m_inf  = 'd1 ;

//3.AXI Lite Write Address
reg     awvalid_m_inf_reg ;
assign  awvalid_m_inf = awvalid_m_inf_reg ;
assign	awid_m_inf    = 'd0 ; 
assign	awburst_m_inf = 'd1 ;
assign	awsize_m_inf  = 'd4 ;
assign	awlen_m_inf   = 'd127 ;
always@(posedge clk or negedge rst_n) begin 
	if (!rst_n) awvalid_m_inf_reg <= 0 ;
	else if (next_state == BACKTODRAM && current_state == FINDNEXTSTATE) awvalid_m_inf_reg <= 1 ;
	else if (awready_m_inf) awvalid_m_inf_reg <= 0 ;
end

//4.AXI Lite Write
reg    wvalid_m_inf_reg ;
assign wvalid_m_inf = wvalid_m_inf_reg ;
assign wlast_m_inf = (counter == 127) ? 1 : 0 ;
assign wdata_m_inf = label_out ;
assign awaddr_m_inf = {16'h0001 , frame_id_span , 11'd0} ;
always@(posedge clk or negedge rst_n) begin 
	if (!rst_n) wvalid_m_inf_reg <= 0  ;
	else if (awready_m_inf) wvalid_m_inf_reg <= 1 ;
	else if (counter == 127) wvalid_m_inf_reg <= 0 ;
end

//5.AXI Lite Response
assign bready_m_inf = 1  ;

//===============================================================================
//                                  Load Index
//===============================================================================

always@(posedge clk or negedge rst_n) begin 
	if (!rst_n) frame_id_span <= 0  ;
	else if(in_valid) frame_id_span <= frame_id ;
	else frame_id_span <= frame_id_span ;
end

always@(posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		net_cnt <= 0  ;
	end
	else if(current_state == INPUT && (counter[0] == 1) && counter >= 2) net_cnt <= net_cnt + 1 ;
	else if (current_state == OUTPUT) begin
		net_cnt <= 0  ;
	end
	else net_cnt <= net_cnt ;
end

always@(posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		for(i=0  ; i < 16  ; i++)
			net_id_span[i] <= 0  ;
	end
	else if(current_state == INPUT && (counter[0] == 1)) net_id_span[counter >> 1] <= net_id ;
	else net_id_span <= net_id_span ;
end

always@(posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		for(i=0  ; i < 8  ; i++)
			loc_x_start[i] <= 0  ;
	end
	else if(in_valid && (counter[0] == 0)) loc_x_start[counter >> 1] <= loc_x ;
	else loc_x_start <= loc_x_start ;
end

always@(posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		for(i=0  ; i < 8  ; i++)
			loc_y_start[i] <= 0  ;
	end
	else if(in_valid && (counter[0] == 0)) loc_y_start[counter >> 1] <= loc_y ;
	else loc_y_start <= loc_y_start ;
end

always@(posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		for(i=0  ; i < 8  ; i++)
			loc_x_end[i] <= 0  ;
	end
	else if(current_state == PATHING) begin
		if(map[loc_x_end[done]][loc_y_end[done] + 1][1]) loc_x_end[done] <= loc_x_end[done] ;
		else if(map[loc_x_end[done]][loc_y_end[done] - 1][1]) loc_x_end[done] <= loc_x_end[done] ;
		else if(map[loc_x_end[done] + 1][loc_y_end[done]][1]) loc_x_end[done] <= loc_x_end[done] + 1 ;
		else if(map[loc_x_end[done] - 1][loc_y_end[done]][1]) loc_x_end[done] <= loc_x_end[done] - 1 ;
	end
	else if((~loc_y_back_down[6]) && current_state == GOBACK && ends && map[loc_x_end[done]][loc_y_back_down] == counter_t4) begin //down //maybe_bug
		loc_x_end[done] <= loc_x_end[done] ;
	end
	else if((~loc_y_back_up[6]) && current_state == GOBACK && ends && map[loc_x_end[done]][loc_y_back_up] == counter_t4) begin //up
		loc_x_end[done] <= loc_x_end[done] ;
	end
	else if((~loc_x_back_right[6]) && current_state == GOBACK && ends && map[loc_x_back_right][loc_y_end[done]] == counter_t4) begin //right
		loc_x_end[done] <= loc_x_back_right ;
	end
	else if((~loc_x_back_left[6]) && current_state == GOBACK && ends && map[loc_x_back_left][loc_y_end[done]] == counter_t4) begin //left
		loc_x_end[done] <= loc_x_back_left ;
	end
	else if(in_valid && (counter[0] == 1)) loc_x_end[counter >> 1] <= loc_x ;
	else loc_x_end <= loc_x_end ;
end

always@(posedge clk or negedge rst_n) begin 
	if (!rst_n) begin
		for(i=0  ; i < 8  ; i++)
			loc_y_end[i] <= 0  ;
	end
	else if(current_state == PATHING) begin
		if(map[loc_x_end[done]][loc_y_end[done] + 1][1]) loc_y_end[done] <= loc_y_end[done] + 1;
		else if(map[loc_x_end[done]][loc_y_end[done] - 1][1]) loc_y_end[done] <= loc_y_end[done] - 1;
		else if(map[loc_x_end[done] + 1][loc_y_end[done]][1]) loc_y_end[done] <= loc_y_end[done] ;
		else if(map[loc_x_end[done] - 1][loc_y_end[done]][1]) loc_y_end[done] <= loc_y_end[done] ;
	end
	else if((~loc_y_back_down[6]) && current_state == GOBACK && ends && map[loc_x_end[done]][loc_y_back_down] == counter_t4) begin //down
		loc_y_end[done] <= loc_y_back_down ;
	end
	else if((~loc_y_back_up[6]) && current_state == GOBACK && ends && map[loc_x_end[done]][loc_y_back_up] == counter_t4) begin //up
		loc_y_end[done] <= loc_y_back_up ;
	end
	else if((~loc_x_back_right[6]) && current_state == GOBACK && ends && map[loc_x_back_right][loc_y_end[done]] == counter_t4) begin //right
		loc_y_end[done] <= loc_y_end[done] ;
	end
	else if((~loc_x_back_left[6]) && current_state == GOBACK && ends && map[loc_x_back_left][loc_y_end[done]] == counter_t4) begin //left
		loc_y_end[done] <= loc_y_end[done] ;
	end
	else if(in_valid && (counter[0] == 1)) loc_y_end[counter >> 1] <= loc_y ;
	else loc_y_end <= loc_y_end ;
end


//===============================================================================
//                                  Creat Map
//===============================================================================


always@(posedge clk) begin 
	if(current_state == CREATMAP && counter >= 1) begin 
		for(i = 0  ; i < 128  ; i = i + 4) begin
			if((counter_t2[0] == 0))begin
				if({label_out[i+3],label_out[i+2],label_out[i+1],label_out[i]} == 0) map[(i >> 2)][(((counter_t2) >> 1 ))] <= 3'd0 ;
				else  map[(i >> 2)][(((counter_t2) >> 1 ))] <= 3'd1 ;
			end
			else if((counter_t2[0] == 1)) begin
				if({label_out[i+3],label_out[i+2],label_out[i+1],label_out[i]} == 0) map[(i >> 2) + 32][(((counter_t2) >> 1 ))] <= 3'd0 ;
				else map[(i >> 2) + 32][(((counter_t2) >> 1 ))] <= 3'd1 ;
			end
		end
	end
	else if(current_state == PATHING && !ends) begin
		//middle 
		for(i=1  ; i < 63  ; i++) begin
			for(j=1  ; j < 63  ; j++) begin
				if((((loc_x_start[done] == (i-1)) && (loc_y_start[done] == j)) || ((loc_x_start[done] == (i+1)) && (loc_y_start[done] == j)) 
				| ((loc_x_start[done] == i) && (loc_y_start[done] == (j+1))) || ((loc_x_start[done] == i) && (loc_y_start[done] == (j-1)))) && map[i][j] == 0) map[i][j] <= 2 ;
				else if(((map[i - 1][j][1]) || (map[i + 1][j][1]) || (map[i][j + 1][1]) || (map[i][j - 1][1])) && map[i][j] == 0) map[i][j] <= counter_t4 ;
			end
		end//boundary
		for(i=1  ; i < 63  ; i++) begin
			if(((map[i - 1][0][1]) || (map[i + 1][0][1]) || (map[i][1][1])) && map[i][0] == 0) map[i][0] <= counter_t4 ;
			if(((map[i - 1][63][1]) || (map[i + 1][63][1]) || (map[i][62][1])) && map[i][63] == 0) map[i][63] <= counter_t4 ;
		end
		for(j=1  ; j < 63  ; j++) begin
			if(((map[1][j][1]) || (map[0][j + 1][1]) || (map[0][j - 1][1])) && map[0][j] == 0) map[0][j] <= counter_t4 ;
			if(((map[62][j][1]) || (map[63][j + 1][1]) || (map[63][j - 1][1])) && map[63][j] == 0) map[63][j] <= counter_t4 ;
		end
		//coner
		if(((map[0][1][1]) || (map[1][0][1])) && map[0][0] == 0) map[0][0] <= counter_t4 ;
		if(((map[1][63][1]) || (map[0][62][1])) && map[0][63] == 0) map[0][63] <= counter_t4 ;
		if(((map[63][1][1]) || (map[62][0][1])) && map[63][0] == 0) map[63][0] <= counter_t4 ;
		if(((map[63][62][1]) || (map[62][63][1])) && map[63][63] == 0) map[63][63] <= counter_t4 ;
	end
	else map <= map ;
end

// always@(posedge clk or negedge rst_n) begin 
// 	if(current_state == PATHING) begin
// 		if(map[loc_x_end[done]][loc_y_end[done] + 1][1]) loc_x_end[done] <= loc_x_end[done] ;
// 		else if(map[loc_x_end[done]][loc_y_end[done] - 1][1]) loc_x_end[done] <= loc_x_end[done] ;
// 		else if(map[loc_x_end[done] + 1][loc_y_end[done]][1]) loc_x_end[done] <= loc_x_end[done] + 1 ;
// 		else if(map[loc_x_end[done] - 1][loc_y_end[done]][1]) loc_x_end[done] <= loc_x_end[done] - 1 ;
// 	end
// 	else if((~loc_y_back_down[6]) && current_state == GOBACK && ends && map[loc_x_end[done]][loc_y_back_down] == counter_t4) begin //down //maybe_bug
// 		loc_x_end[done] <= loc_x_end[done] ;
// 	end
// 	else if((~loc_y_back_up[6]) && current_state == GOBACK && ends && map[loc_x_end[done]][loc_y_back_up] == counter_t4) begin //up
// 		loc_x_end[done] <= loc_x_end[done] ;
// 	end
// 	else if((~loc_x_back_right[6]) && current_state == GOBACK && ends && map[loc_x_back_right][loc_y_back] == counter_t4) begin //right
// 		loc_x_end[done] <= loc_x_back_right ;
// 	end
// 	else if((~loc_x_back_left[6]) && current_state == GOBACK && ends && map[loc_x_back_left][loc_y_back] == counter_t4) begin //left
// 		loc_x_end[done] <= loc_x_back_left ;
// 	end
// 	// else loc_x_end[done] <= loc_x_end[done] ;
// end

// always@(posedge clk or negedge rst_n) begin 
// 	if(current_state == PATHING) begin
// 		if(map[loc_x_end[done]][loc_y_end[done] + 1][1]) loc_y_end[done] <= loc_y_end[done] + 1;
// 		else if(map[loc_x_end[done]][loc_y_end[done] - 1][1]) loc_y_end[done] <= loc_y_end[done] - 1;
// 		else if(map[loc_x_end[done] + 1][loc_y_end[done]][1]) loc_y_end[done] <= loc_y_end[done] ;
// 		else if(map[loc_x_end[done] - 1][loc_y_end[done]][1]) loc_y_end[done] <= loc_y_end[done] ;
// 	end
// 	else if((~loc_y_back_down[6]) && current_state == GOBACK && ends && map[loc_x_end[done]][loc_y_back_down] == counter_t4) begin //down
// 		loc_y_end[done] <= loc_y_back_down ;
// 	end
// 	else if((~loc_y_back_up[6]) && current_state == GOBACK && ends && map[loc_x_end[done]][loc_y_back_up] == counter_t4) begin //up
// 		loc_y_end[done] <= loc_y_back_up ;
// 	end
// 	else if((~loc_x_back_right[6]) && current_state == GOBACK && ends && map[loc_x_back_right][loc_y_end[done]] == counter_t4) begin //right
// 		loc_y_end[done] <= loc_y_end[done] ;
// 	end
// 	else if((~loc_x_back_left[6]) && current_state == GOBACK && ends && map[loc_x_back_left][loc_y_end[done]] == counter_t4) begin //left
// 		loc_y_end[done] <= loc_y_end[done] ;
// 	end
// 	else loc_y_end[done] <= loc_y_end[done] ;
// end


//===============================================================================
//                                  Label SRAM
//===============================================================================
always@(*) begin 
	if (!rst_n) label_addr = 0 ;
	else if(current_state == LOADLABEL && rvalid_m_inf) label_addr = counter ;
	else if(current_state == CREATMAP && counter <= 127) label_addr = counter ;
	else if (current_state == GOBACK || current_state == GOBACK_DELAY || current_state == GOBACK_DELAY_2) label_addr = {loc_y_end[done], loc_x_end[done][5]} ;
	else if(current_state == BACKTODRAM && wready_m_inf) label_addr = counter_t1 ;
	else if(current_state == BACKTODRAM && !wready_m_inf) label_addr = 'd0 ;
	else label_addr = counter ;
end

always@(*) begin 
	if(current_state == LOADLABEL && rvalid_m_inf) begin
		label_in = rdata_m_inf ;
	end
	else if(current_state == GOBACK || current_state == GOBACK_DELAY || current_state == GOBACK_DELAY_2) begin
		label_in = label_out;
		label_in[{loc_x_end[done][4:0], 2'b11} -: 4] = net_id_span[done] ;
	end
	else label_in = 0;
end

always@(*) begin 
	if (!rst_n) WEN_label = 1  ;
	else if(current_state == LOADLABEL && rvalid_m_inf) WEN_label = 0 ;
	else if(current_state == GOBACK) WEN_label = 0 ;
	else WEN_label = 1 ;
end


//===============================================================================
//                                 Weight SRAM
//===============================================================================
always@(*) begin 
	if (!rst_n) wei_addr = 0  ;
	else if(current_state == LOADWEIGHT && rvalid_m_inf) wei_addr = counter ;
	else if (current_state == GOBACK || current_state == GOBACK_DELAY || current_state == GOBACK_DELAY_2) wei_addr = {loc_y_end[done], loc_x_end[done][5]} ;
	else wei_addr = 0 ;
end

always@(*) begin 
	if (!rst_n) wei_in = 0  ;
	else if(current_state == LOADWEIGHT && rvalid_m_inf) wei_in = rdata_m_inf ;
	else wei_in = 0 ;
end

always@(*) begin 
	if (!rst_n) WEN_weight = 1  ;
	else if(current_state == LOADWEIGHT && rvalid_m_inf) WEN_weight = 0 ;
	else WEN_weight = 1 ;
end

//===============================================================================
//                                    Output
//=============================================================================== 
always@(posedge clk or negedge rst_n) begin 
	if (!rst_n) done <= 0  ;
	else if(current_state == IDLE) done <= 0 ;
	else if(current_state == FINDNEXTSTATE && done != net_cnt && counter == 0) begin
		done <= done + 1 ;
	end
	else done <= done ;
end

always@(posedge clk or negedge rst_n) begin 
	if (!rst_n) ends <= 0  ;
	else if(current_state == CREATMAP) ends <= 0 ;
	else if(current_state == PATHING) begin
		if(map[loc_x_end[done] + 1][loc_y_end[done]][1] == 1) ends <= 1 ;
		else if(map[loc_x_end[done] - 1][loc_y_end[done]][1] == 1) ends <= 1 ;
		else if(map[loc_x_end[done]][loc_y_end[done] + 1][1] == 1) ends <= 1 ;
		else if(map[loc_x_end[done]][loc_y_end[done] - 1][1] == 1) ends <= 1 ;
	end
	else if(current_state == GOBACK) begin
		if(loc_x_start[done] + 1 == loc_x_end[done] && loc_y_start[done] == loc_y_end[done]) ends <= 0 ;
		else if(loc_x_start[done] - 1 == loc_x_end[done] && loc_y_start[done] == loc_y_end[done]) ends <= 0 ;
		else if(loc_x_start[done] == loc_x_end[done] && loc_y_start[done] + 1 == loc_y_end[done]) ends <= 0 ;
		else if(loc_x_start[done] == loc_x_end[done] && loc_y_start[done] - 1 == loc_y_end[done]) ends <= 0 ;
	end
	else ends <= ends ;
end

always@(posedge clk or negedge rst_n) begin 
	if (!rst_n) busy <= 0 ;
	else if (next_state == IDLE || in_valid) busy <= 0 ;
	else busy <= 1 ;
end

always@(posedge clk or negedge rst_n) begin 
	if (!rst_n) cost <= 0 ;
	else if (current_state == IDLE) cost <= 0 ;
	else if(current_state == GOBACK && ends) begin
		cost <= cost + {9'd0,wei_out[{loc_x_end[done][4:0], 2'b11} -: 4]} ;
	end
	else cost <= cost ;
end

//===============================================================================
//                                  SRAM Module
//===============================================================================                                                                          
map_128x128 label_128x128(
	.A0(label_addr[0])     ,.A1(label_addr[1])    ,.A2(label_addr[2])    ,.A3(label_addr[3])    ,.A4(label_addr[4])    ,.A5(label_addr[5])    ,.A6(label_addr[6]),
	.DO0  (label_out[0])   ,.DO1  (label_out[1])   ,.DO2  (label_out[2])   ,.DO3  (label_out[3])   ,.DO4  (label_out[4])   ,.DO5  (label_out[5])   ,.DO6  (label_out[6])   ,.DO7  (label_out[7])   ,.DO8  (label_out[8])   ,.DO9 (label_out[9]),
	.DO10 (label_out[10])  ,.DO11 (label_out[11])  ,.DO12 (label_out[12])  ,.DO13 (label_out[13])  ,.DO14 (label_out[14])  ,.DO15 (label_out[15])  ,.DO16 (label_out[16])  ,.DO17 (label_out[17])  ,.DO18 (label_out[18])  ,.DO19(label_out[19]),
	.DO20 (label_out[20])  ,.DO21 (label_out[21])  ,.DO22 (label_out[22])  ,.DO23 (label_out[23])  ,.DO24 (label_out[24])  ,.DO25 (label_out[25])  ,.DO26 (label_out[26])  ,.DO27 (label_out[27])  ,.DO28 (label_out[28])  ,.DO29(label_out[29]),
	.DO30 (label_out[30])  ,.DO31 (label_out[31])  ,.DO32 (label_out[32])  ,.DO33 (label_out[33])  ,.DO34 (label_out[34])  ,.DO35 (label_out[35])  ,.DO36 (label_out[36])  ,.DO37 (label_out[37])  ,.DO38 (label_out[38])  ,.DO39(label_out[39]),
	.DO40 (label_out[40])  ,.DO41 (label_out[41])  ,.DO42 (label_out[42])  ,.DO43 (label_out[43])  ,.DO44 (label_out[44])  ,.DO45 (label_out[45])  ,.DO46 (label_out[46])  ,.DO47 (label_out[47])  ,.DO48 (label_out[48])  ,.DO49(label_out[49]),
	.DO50 (label_out[50])  ,.DO51 (label_out[51])  ,.DO52 (label_out[52])  ,.DO53 (label_out[53])  ,.DO54 (label_out[54])  ,.DO55 (label_out[55])  ,.DO56 (label_out[56])  ,.DO57 (label_out[57])  ,.DO58 (label_out[58])  ,.DO59(label_out[59]),
	.DO60 (label_out[60])  ,.DO61 (label_out[61])  ,.DO62 (label_out[62])  ,.DO63 (label_out[63])  ,.DO64 (label_out[64])  ,.DO65 (label_out[65])  ,.DO66 (label_out[66])  ,.DO67 (label_out[67])  ,.DO68 (label_out[68])  ,.DO69(label_out[69]),
	.DO70 (label_out[70])  ,.DO71 (label_out[71])  ,.DO72 (label_out[72])  ,.DO73 (label_out[73])  ,.DO74 (label_out[74])  ,.DO75 (label_out[75])  ,.DO76 (label_out[76])  ,.DO77 (label_out[77])  ,.DO78 (label_out[78])  ,.DO79(label_out[79]),
    .DO80 (label_out[80])  ,.DO81 (label_out[81])  ,.DO82 (label_out[82])  ,.DO83 (label_out[83])  ,.DO84 (label_out[84])  ,.DO85 (label_out[85])  ,.DO86 (label_out[86])  ,.DO87 (label_out[87])  ,.DO88 (label_out[88])  ,.DO89(label_out[89]),
	.DO90 (label_out[90])  ,.DO91 (label_out[91])  ,.DO92 (label_out[92])  ,.DO93 (label_out[93])  ,.DO94 (label_out[94])  ,.DO95 (label_out[95])  ,.DO96 (label_out[96])  ,.DO97 (label_out[97])  ,.DO98 (label_out[98])  ,.DO99(label_out[99]),
	.DO100(label_out[100]) ,.DO101(label_out[101]) ,.DO102(label_out[102]) ,.DO103(label_out[103]) ,.DO104(label_out[104]) ,.DO105(label_out[105]) ,.DO106(label_out[106]) ,.DO107(label_out[107]) ,.DO108(label_out[108]) ,.DO109(label_out[109]),
	.DO110(label_out[110]) ,.DO111(label_out[111]) ,.DO112(label_out[112]) ,.DO113(label_out[113]) ,.DO114(label_out[114]) ,.DO115(label_out[115]) ,.DO116(label_out[116]) ,.DO117(label_out[117]) ,.DO118(label_out[118]) ,.DO119(label_out[119]),
	.DO120(label_out[120]) ,.DO121(label_out[121]) ,.DO122(label_out[122]) ,.DO123(label_out[123]) ,.DO124(label_out[124]) ,.DO125(label_out[125]) ,.DO126(label_out[126]) ,.DO127(label_out[127]) ,
	.DI0  (label_in[0])    ,.DI1  (label_in[1])    ,.DI2  (label_in[2])    ,.DI3  (label_in[3])    ,.DI4  (label_in[4])    ,.DI5  (label_in[5])    ,.DI6  (label_in[6])    ,.DI7  (label_in[7])    ,.DI8 (label_in[8])    ,.DI9(label_in[9]),
	.DI10 (label_in[10])   ,.DI11 (label_in[11])   ,.DI12 (label_in[12])   ,.DI13 (label_in[13])   ,.DI14 (label_in[14])   ,.DI15 (label_in[15])   ,.DI16 (label_in[16])   ,.DI17 (label_in[17])   ,.DI18(label_in[18])  ,.DI19(label_in[19]),
	.DI20 (label_in[20])   ,.DI21 (label_in[21])   ,.DI22 (label_in[22])   ,.DI23 (label_in[23])   ,.DI24 (label_in[24])   ,.DI25 (label_in[25])   ,.DI26 (label_in[26])   ,.DI27 (label_in[27])   ,.DI28(label_in[28])  ,.DI29(label_in[29]),
	.DI30 (label_in[30])   ,.DI31 (label_in[31])   ,.DI32 (label_in[32])   ,.DI33 (label_in[33])   ,.DI34 (label_in[34])   ,.DI35 (label_in[35])   ,.DI36 (label_in[36])   ,.DI37 (label_in[37])   ,.DI38(label_in[38])  ,.DI39(label_in[39]),
	.DI40 (label_in[40])   ,.DI41 (label_in[41])   ,.DI42 (label_in[42])   ,.DI43 (label_in[43])   ,.DI44 (label_in[44])   ,.DI45 (label_in[45])   ,.DI46 (label_in[46])   ,.DI47 (label_in[47])   ,.DI48(label_in[48])  ,.DI49(label_in[49]),
	.DI50 (label_in[50])   ,.DI51 (label_in[51])   ,.DI52 (label_in[52])   ,.DI53 (label_in[53])   ,.DI54 (label_in[54])   ,.DI55 (label_in[55])   ,.DI56 (label_in[56])   ,.DI57 (label_in[57])   ,.DI58(label_in[58])  ,.DI59(label_in[59]),
	.DI60 (label_in[60])   ,.DI61 (label_in[61])   ,.DI62 (label_in[62])   ,.DI63 (label_in[63])   ,.DI64 (label_in[64])   ,.DI65 (label_in[65])   ,.DI66 (label_in[66])   ,.DI67 (label_in[67])   ,.DI68(label_in[68])  ,.DI69(label_in[69]),
	.DI70 (label_in[70])   ,.DI71 (label_in[71])   ,.DI72 (label_in[72])   ,.DI73 (label_in[73])   ,.DI74 (label_in[74])   ,.DI75 (label_in[75])   ,.DI76 (label_in[76])   ,.DI77 (label_in[77])   ,.DI78(label_in[78])  ,.DI79(label_in[79]),
	.DI80 (label_in[80])   ,.DI81 (label_in[81])   ,.DI82 (label_in[82])   ,.DI83 (label_in[83])   ,.DI84 (label_in[84])   ,.DI85 (label_in[85])   ,.DI86 (label_in[86])   ,.DI87 (label_in[87])   ,.DI88(label_in[88])  ,.DI89(label_in[89]),
	.DI90 (label_in[90])   ,.DI91 (label_in[91])   ,.DI92 (label_in[92])   ,.DI93 (label_in[93])   ,.DI94 (label_in[94])   ,.DI95 (label_in[95])   ,.DI96 (label_in[96])   ,.DI97 (label_in[97])   ,.DI98(label_in[98])  ,.DI99(label_in[99]),
	.DI100(label_in[100])  ,.DI101(label_in[101])  ,.DI102(label_in[102])  ,.DI103(label_in[103])  ,.DI104(label_in[104])  ,.DI105(label_in[105])  ,.DI106(label_in[106])  ,.DI107(label_in[107])  ,.DI108(label_in[108]) ,.DI109(label_in[109]),
    .DI110(label_in[110])  ,.DI111(label_in[111])  ,.DI112(label_in[112])  ,.DI113(label_in[113])  ,.DI114(label_in[114])  ,.DI115(label_in[115])  ,.DI116(label_in[116])  ,.DI117(label_in[117])  ,.DI118(label_in[118]) ,.DI119(label_in[119]),
	.DI120(label_in[120])  ,.DI121(label_in[121])  ,.DI122(label_in[122])  ,.DI123(label_in[123])  ,.DI124(label_in[124])  ,.DI125(label_in[125])  ,.DI126(label_in[126])  ,.DI127(label_in[127])  ,
	.CK(clk),
	.WEB(WEN_label),
	.OE(1'b1),
	.CS(1'b1)) ;

map_128x128 weight_128x128(
	.A0(wei_addr[0])     ,.A1(wei_addr[1])    ,.A2(wei_addr[2])    ,.A3(wei_addr[3])    ,.A4(wei_addr[4])    ,.A5(wei_addr[5])    ,.A6(wei_addr[6]),
	.DO0  (wei_out[0])   ,.DO1 (wei_out[1])   ,.DO2 (wei_out[2])   ,.DO3 (wei_out[3])   ,.DO4 (wei_out[4])   ,.DO5 (wei_out[5])   ,.DO6 (wei_out[6])   ,.DO7 (wei_out[7])   ,.DO8 (wei_out[8])   ,.DO9 (wei_out[9]),
	.DO10 (wei_out[10])  ,.DO11(wei_out[11])  ,.DO12(wei_out[12])  ,.DO13(wei_out[13])  ,.DO14(wei_out[14])  ,.DO15(wei_out[15])  ,.DO16(wei_out[16])  ,.DO17(wei_out[17])  ,.DO18(wei_out[18])  ,.DO19(wei_out[19]),
	.DO20 (wei_out[20])  ,.DO21(wei_out[21])  ,.DO22(wei_out[22])  ,.DO23(wei_out[23])  ,.DO24(wei_out[24])  ,.DO25(wei_out[25])  ,.DO26(wei_out[26])  ,.DO27(wei_out[27])  ,.DO28(wei_out[28])  ,.DO29(wei_out[29]),
	.DO30 (wei_out[30])  ,.DO31(wei_out[31])  ,.DO32(wei_out[32])  ,.DO33(wei_out[33])  ,.DO34(wei_out[34])  ,.DO35(wei_out[35])  ,.DO36(wei_out[36])  ,.DO37(wei_out[37])  ,.DO38(wei_out[38])  ,.DO39(wei_out[39]),
	.DO40 (wei_out[40])  ,.DO41(wei_out[41])  ,.DO42(wei_out[42])  ,.DO43(wei_out[43])  ,.DO44(wei_out[44])  ,.DO45(wei_out[45])  ,.DO46(wei_out[46])  ,.DO47(wei_out[47])  ,.DO48(wei_out[48])  ,.DO49(wei_out[49]),
	.DO50 (wei_out[50])  ,.DO51(wei_out[51])  ,.DO52(wei_out[52])  ,.DO53(wei_out[53])  ,.DO54(wei_out[54])  ,.DO55(wei_out[55])  ,.DO56(wei_out[56])  ,.DO57(wei_out[57])  ,.DO58(wei_out[58])  ,.DO59(wei_out[59]),
	.DO60 (wei_out[60])  ,.DO61(wei_out[61])  ,.DO62(wei_out[62])  ,.DO63(wei_out[63])  ,.DO64(wei_out[64])  ,.DO65(wei_out[65])  ,.DO66(wei_out[66])  ,.DO67(wei_out[67])  ,.DO68(wei_out[68])  ,.DO69(wei_out[69]),
	.DO70 (wei_out[70])  ,.DO71(wei_out[71])  ,.DO72(wei_out[72])  ,.DO73(wei_out[73])  ,.DO74(wei_out[74])  ,.DO75(wei_out[75])  ,.DO76(wei_out[76])  ,.DO77(wei_out[77])  ,.DO78(wei_out[78])  ,.DO79(wei_out[79]),
    .DO80 (wei_out[80])  ,.DO81(wei_out[81])  ,.DO82(wei_out[82])  ,.DO83(wei_out[83])  ,.DO84(wei_out[84])  ,.DO85(wei_out[85])  ,.DO86(wei_out[86])  ,.DO87(wei_out[87])  ,.DO88(wei_out[88])  ,.DO89(wei_out[89]),
	.DO90 (wei_out[90])  ,.DO91(wei_out[91])  ,.DO92(wei_out[92])  ,.DO93(wei_out[93])  ,.DO94(wei_out[94])  ,.DO95(wei_out[95])  ,.DO96(wei_out[96])  ,.DO97(wei_out[97])  ,.DO98(wei_out[98])  ,.DO99(wei_out[99]),
	.DO100(wei_out[100]) ,.DO101(wei_out[101]) ,.DO102(wei_out[102]) ,.DO103(wei_out[103]) ,.DO104(wei_out[104]) ,.DO105(wei_out[105]) ,.DO106(wei_out[106]) ,.DO107(wei_out[107]) ,.DO108(wei_out[108]) ,.DO109(wei_out[109]),
	.DO110(wei_out[110]) ,.DO111(wei_out[111]) ,.DO112(wei_out[112]) ,.DO113(wei_out[113]) ,.DO114(wei_out[114]) ,.DO115(wei_out[115]) ,.DO116(wei_out[116]) ,.DO117(wei_out[117]) ,.DO118(wei_out[118]) ,.DO119(wei_out[119]),
	.DO120(wei_out[120]) ,.DO121(wei_out[121]) ,.DO122(wei_out[122]) ,.DO123(wei_out[123]) ,.DO124(wei_out[124]) ,.DO125(wei_out[125]) ,.DO126(wei_out[126]) ,.DO127(wei_out[127]) ,
	.DI0  (wei_in[0])   ,.DI1(wei_in[1])    ,.DI2(wei_in[2])    ,.DI3(wei_in[3])    ,.DI4(wei_in[4])    ,.DI5(wei_in[5])    ,.DI6(wei_in[6])    ,.DI7(wei_in[7])    ,.DI8(wei_in[8])    ,.DI9(wei_in[9]),
	.DI10 (wei_in[10])  ,.DI11(wei_in[11])  ,.DI12(wei_in[12])  ,.DI13(wei_in[13])  ,.DI14(wei_in[14])  ,.DI15(wei_in[15])  ,.DI16(wei_in[16])  ,.DI17(wei_in[17])  ,.DI18(wei_in[18])  ,.DI19(wei_in[19]),
	.DI20 (wei_in[20])  ,.DI21(wei_in[21])  ,.DI22(wei_in[22])  ,.DI23(wei_in[23])  ,.DI24(wei_in[24])  ,.DI25(wei_in[25])  ,.DI26(wei_in[26])  ,.DI27(wei_in[27])  ,.DI28(wei_in[28])  ,.DI29(wei_in[29]),
	.DI30 (wei_in[30])  ,.DI31(wei_in[31])  ,.DI32(wei_in[32])  ,.DI33(wei_in[33])  ,.DI34(wei_in[34])  ,.DI35(wei_in[35])  ,.DI36(wei_in[36])  ,.DI37(wei_in[37])  ,.DI38(wei_in[38])  ,.DI39(wei_in[39]),
	.DI40 (wei_in[40])  ,.DI41(wei_in[41])  ,.DI42(wei_in[42])  ,.DI43(wei_in[43])  ,.DI44(wei_in[44])  ,.DI45(wei_in[45])  ,.DI46(wei_in[46])  ,.DI47(wei_in[47])  ,.DI48(wei_in[48])  ,.DI49(wei_in[49]),
	.DI50 (wei_in[50])  ,.DI51(wei_in[51])  ,.DI52(wei_in[52])  ,.DI53(wei_in[53])  ,.DI54(wei_in[54])  ,.DI55(wei_in[55])  ,.DI56(wei_in[56])  ,.DI57(wei_in[57])  ,.DI58(wei_in[58])  ,.DI59(wei_in[59]),
	.DI60 (wei_in[60])  ,.DI61(wei_in[61])  ,.DI62(wei_in[62])  ,.DI63(wei_in[63])  ,.DI64(wei_in[64])  ,.DI65(wei_in[65])  ,.DI66(wei_in[66])  ,.DI67(wei_in[67])  ,.DI68(wei_in[68])  ,.DI69(wei_in[69]),
	.DI70 (wei_in[70])  ,.DI71(wei_in[71])  ,.DI72(wei_in[72])  ,.DI73(wei_in[73])  ,.DI74(wei_in[74])  ,.DI75(wei_in[75])  ,.DI76(wei_in[76])  ,.DI77(wei_in[77])  ,.DI78(wei_in[78])  ,.DI79(wei_in[79]),
	.DI80 (wei_in[80])  ,.DI81(wei_in[81])  ,.DI82(wei_in[82])  ,.DI83(wei_in[83])  ,.DI84(wei_in[84])  ,.DI85(wei_in[85])  ,.DI86(wei_in[86])  ,.DI87(wei_in[87])  ,.DI88(wei_in[88])  ,.DI89(wei_in[89]),
	.DI90 (wei_in[90])  ,.DI91(wei_in[91])  ,.DI92(wei_in[92])  ,.DI93(wei_in[93])  ,.DI94(wei_in[94])  ,.DI95(wei_in[95])  ,.DI96(wei_in[96])  ,.DI97(wei_in[97])  ,.DI98(wei_in[98])  ,.DI99(wei_in[99]),
	.DI100(wei_in[100]) ,.DI101(wei_in[101]) ,.DI102(wei_in[102]) ,.DI103(wei_in[103]) ,.DI104(wei_in[104]) ,.DI105(wei_in[105]) ,.DI106(wei_in[106]) ,.DI107(wei_in[107]) ,.DI108(wei_in[108]) ,.DI109(wei_in[109]),
    .DI110(wei_in[110]) ,.DI111(wei_in[111]) ,.DI112(wei_in[112]) ,.DI113(wei_in[113]) ,.DI114(wei_in[114]) ,.DI115(wei_in[115]) ,.DI116(wei_in[116]) ,.DI117(wei_in[117]) ,.DI118(wei_in[118]) ,.DI119(wei_in[119]),
	.DI120(wei_in[120]) ,.DI121(wei_in[121]) ,.DI122(wei_in[122]) ,.DI123(wei_in[123]) ,.DI124(wei_in[124]) ,.DI125(wei_in[125]) ,.DI126(wei_in[126]) ,.DI127(wei_in[127]) ,
	.CK(clk),
	.WEB(WEN_weight),
	.OE(1'b1),
	.CS(1'b1)) ;
endmodule
