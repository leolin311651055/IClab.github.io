//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab03      : BRIDGE
//   Author     : Ting-Yu Chang
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : BRIDGE_encrypted.v
//   Module Name : BRIDGE
//   Release version : v1.0 (Release Date: Sep-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module BRIDGE(
    // Input Signals
    clk,
    rst_n,
    in_valid,
    direction,
    addr_dram,
    addr_sd,
    // Output Signals
    out_valid,
    out_data,
    // DRAM Signals
    AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
	AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
    // SD Signals
    MISO,
    MOSI
);

// Input Signals
input clk, rst_n;
input in_valid;
input direction;
input [12:0] addr_dram;
input [15:0] addr_sd;

// Output Signals
output reg out_valid;
output reg [7:0] out_data;

// DRAM Signals
// write address channel
output reg [31:0] AW_ADDR;
output reg AW_VALID;
input AW_READY;
// write data channel
output reg W_VALID;
output reg [63:0] W_DATA;
input W_READY;
// write response channel
input B_VALID;
input [1:0] B_RESP;
output reg B_READY;
// read address channel
output reg [31:0] AR_ADDR;
output reg AR_VALID;
input AR_READY;
// read data channel
input [63:0] R_DATA;
input R_VALID;
input [1:0] R_RESP;
output reg R_READY;

// SD Signals
input MISO;
output reg MOSI;


//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter IDLE = 0;
parameter MOSI_LOAD_READ = 1;
parameter CRC_WORK_READ = 2;
parameter START_MISO_READ = 3;
parameter WAIT_MISO_READ = 4;
parameter GET_W_DATA = 5;
parameter AW_VALID_START = 6;
parameter W_VALID_START = 7;
parameter READ_OUTPUT = 8;
parameter AR_READY_STATE = 9;
parameter R_READY_STATE = 10;
parameter WAIT_RDATA = 11;
parameter MOSI_LOAD_WRITE = 12;
parameter CRC_WORK_WRITE = 13;
//parameter START_MISO_WRITE = 14;
parameter COUNTING_MOSI = 14 ;
parameter MOSI_LOAD_WRITE_END = 15;
parameter PREOUTPUT = 16;
parameter WRITE_OUTPUT = 17;

//integer i;



//==============================================//
//           reg & wire declaration             //
//==============================================//
// reg[39:0] read_pin;
reg[7:0] current_state,next_state;
reg[10:0] counter;
reg[10:0] counter_MOSI_write_2;
reg[6:0] CRC7_R_out;
reg[6:0] CRC7_W_out;
reg[15:0] CRC16_out;
reg[15:0] addr_sd_span;
reg[63:0] W_DATA_span;
reg[8:0] cnt_w_data;
reg[4:0] cnt_out;
reg[12:0] addr_dram_span;
reg direction_span;
reg[63:0] R_DATA_span;
//==============================================//
//                  design                      //
//==============================================//

//FSM
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        current_state <= IDLE;
    end
    else current_state <= next_state;
end

always@(*) begin
	if(!rst_n) next_state = IDLE;
	else begin
		case(current_state)
			IDLE : begin
				if(in_valid & direction == 1) next_state = MOSI_LOAD_READ;
				else if(in_valid & direction == 0) next_state = AR_READY_STATE;
				else next_state = current_state;
			end
			MOSI_LOAD_READ : begin
				if(counter == 48) next_state = CRC_WORK_READ;
				else next_state = current_state;
			end
			CRC_WORK_READ : begin
				if(MISO == 0) next_state = START_MISO_READ;
				else next_state = current_state;
			end
            START_MISO_READ : begin
				if(MISO == 1) next_state = WAIT_MISO_READ;
				else next_state = current_state;
			end
            WAIT_MISO_READ : begin
				if(MISO == 0) next_state = GET_W_DATA;
				else next_state = current_state;
			end
			GET_W_DATA : begin
				if(cnt_w_data == 100) next_state = AW_VALID_START;
				else next_state = current_state;
			end
            AW_VALID_START : begin
				if(AW_READY == 1 & AW_VALID ==1) next_state = W_VALID_START;
				else next_state = current_state;
			end
            W_VALID_START : begin
				if(B_VALID == 1) next_state = READ_OUTPUT;
				else next_state = current_state;
			end
            READ_OUTPUT : begin
				if(cnt_out >= 8) next_state = IDLE;
				else next_state = current_state;
			end


            AR_READY_STATE : begin
				if(AR_READY) next_state = R_READY_STATE;
				else next_state = current_state;
			end
            R_READY_STATE : begin
				if(R_READY == 0) next_state = WAIT_RDATA;
				else next_state = current_state;
			end
            WAIT_RDATA : begin
				if(MISO == 1) next_state = MOSI_LOAD_WRITE;
				else next_state = current_state;
			end


            MOSI_LOAD_WRITE : begin
				if(counter == 48) next_state = CRC_WORK_WRITE;
				else next_state = current_state;
			end
            CRC_WORK_WRITE : begin
				if(MISO == 0) next_state = COUNTING_MOSI;
				else next_state = current_state;
			end
            // START_MISO_WRITE : begin
			// 	if(MISO == 1) next_state = COUNTING_MOSI;
			// 	else next_state = current_state;
			// end
            COUNTING_MOSI : begin
				if(counter_MOSI_write_2>=126) next_state = MOSI_LOAD_WRITE_END;
				else next_state = current_state;
			end
            MOSI_LOAD_WRITE_END : begin
				if(counter_MOSI_write_2>=9) next_state = PREOUTPUT;
				else next_state = current_state;
			end
            PREOUTPUT : begin
				if(MISO == 1) next_state = WRITE_OUTPUT;
				else next_state = current_state;
			end
            WRITE_OUTPUT : begin
				if(cnt_out >= 8) next_state = IDLE;
				else next_state = current_state;
			end
			default : next_state = current_state;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 0;
    end
    else if((current_state == MOSI_LOAD_READ | current_state == MOSI_LOAD_WRITE) & (counter < 48)) begin
        counter <= counter +1 ;
    end
    else counter <= 0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter_MOSI_write_2 <= 0;
    end
    else if(((current_state == 13 & MISO == 0) | current_state == 14) & counter_MOSI_write_2 < 126) begin
        counter_MOSI_write_2 <= counter_MOSI_write_2 +1 ;
    end
    else if(counter_MOSI_write_2 == 126) begin
        counter_MOSI_write_2 <= 0 ;
    end
    else if(current_state == 15 & counter_MOSI_write_2 < 10) begin
        counter_MOSI_write_2 <= counter_MOSI_write_2 +1 ;
    end
    else counter_MOSI_write_2 <= 0;
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) addr_sd_span <= 0;
    else if(in_valid) addr_sd_span <= addr_sd;
    else addr_sd_span <= addr_sd_span;
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
    end
    else if(cnt_out <= 7 & (current_state == READ_OUTPUT | current_state == WRITE_OUTPUT)) begin
        out_valid <= 1;
    end
    else begin
        out_valid <= 0;
    end
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_out <= 0;
    end
    else if(cnt_out <= 7 & (current_state == READ_OUTPUT | current_state == WRITE_OUTPUT)) begin
        cnt_out <= cnt_out + 1;
    end
    else begin
        cnt_out <= 0;
    end
end



always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        direction_span <= 0;
    end
    else if(direction == 1 | direction == 0) begin
        direction_span <= direction;
    end
    else begin
        direction_span <= direction_span;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        R_DATA_span <= 0;
    end
    else if(R_VALID) begin
        R_DATA_span <= R_DATA;
    end
    else begin
        R_DATA_span <= R_DATA_span;
    end
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_data <= 0;
    end
    else if(current_state == READ_OUTPUT & cnt_out <8) begin
        case(cnt_out)
            7:out_data <= W_DATA_span[7:0];
            6:out_data <= W_DATA_span[15:8];
            5:out_data <= W_DATA_span[23:16];
            4:out_data <= W_DATA_span[31:24];
            3:out_data <= W_DATA_span[39:32];
            2:out_data <= W_DATA_span[47:40];
            1:out_data <= W_DATA_span[55:48];
            0:out_data <= W_DATA_span[63:56];
            default : out_data <= out_data;
        endcase
        //out_data[i] <= ;
    end
    else if(current_state == WRITE_OUTPUT & cnt_out <8) begin
        case(cnt_out) 
            7:out_data <= R_DATA_span[7:0];
            6:out_data <= R_DATA_span[15:8];
            5:out_data <= R_DATA_span[23:16];
            4:out_data <= R_DATA_span[31:24];
            3:out_data <= R_DATA_span[39:32];
            2:out_data <= R_DATA_span[47:40];
            1:out_data <= R_DATA_span[55:48];
            0:out_data <= R_DATA_span[63:56];
            default : out_data <= out_data;
        endcase
        // out_data[i] <= ;
    end
    else  out_data <= 0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        AW_ADDR <= 0;
    end
    else if(current_state == AW_VALID_START & !AW_READY) begin
        AW_ADDR <= addr_dram_span;
    end
    else if(AW_READY) begin
        AW_ADDR <= 0;
    end
    else AW_ADDR <= 0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_dram_span <= 0;
    end
    else if(in_valid) begin
        addr_dram_span <= addr_dram;
    end
    else addr_dram_span <= addr_dram_span;
end


//reg[2:0] cnt_aw;
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        AW_VALID <= 0;
        //cnt_aw <= 0;
    end
    else if(current_state == AW_VALID_START & !AW_READY) begin
        AW_VALID <= 1;
    end
    else if(current_state == AW_VALID_START & AW_READY)begin
        AW_VALID <= 0;
    end
    else begin
        AW_VALID <= 0;
    end
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        W_VALID <= 0;
        //cnt_aw <= 0;
    end
    else if(AW_READY) begin
        W_VALID <= 1;
    end
    else if(W_READY)begin
        W_VALID <= 0;
    end
    else begin
        W_VALID <= W_VALID;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        AR_ADDR <= 0;
    end
    else if(current_state == AR_READY_STATE & !AR_READY) begin
        AR_ADDR <= addr_dram_span;
    end
    else if(AR_READY) begin
        AR_ADDR <= 0;
    end
    // else if(AR_READY_span) begin
    //     AR_ADDR <= 0;
    // end
    else AR_ADDR <= 0;
end


always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        AR_VALID <= 0;
    end
    else if(current_state == AR_READY_STATE & !AR_READY) begin
        AR_VALID <= 1;
    end
    else AR_VALID <= 0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        R_READY <= 0;
    end
    else if(AR_READY) begin
        R_READY <= 1;
    end
    else if(R_VALID) begin
        R_READY <= 0;
    end
    else R_READY <= R_READY;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        B_READY <= 0;
        //cnt_aw <= 0;
    end
    else if(current_state == AW_VALID_START & AW_READY == 1 & AW_VALID ==1) begin
        B_READY<= 1;
    end
    else if(B_VALID)begin
        B_READY <= 0;
    end
    else begin
        B_READY <= B_READY;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        W_DATA <= 0;
    end
    else if(AW_READY & !W_READY) begin
        W_DATA <= W_DATA_span;
    end
    else if(W_READY) begin
        W_DATA <= 0;
    end
    else begin
        W_DATA <= W_DATA;
    end
end



always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        W_DATA_span <= 0;
        cnt_w_data <= 0;
    end
    else if(current_state == GET_W_DATA) begin
        W_DATA_span[63-cnt_w_data] <= MISO;
        cnt_w_data <= cnt_w_data + 1;
    end
    else begin
        W_DATA_span <= W_DATA_span;
        cnt_w_data <= 0;
    end
end


assign CRC7_R_out =  CRC7({1'b0, 1'b1, 6'd17, 16'd0, addr_sd_span}) ;
assign CRC7_W_out = CRC7({1'b0, 1'b1, 6'd24, 16'd0, addr_sd_span}) ;

assign CRC16_out = CRC16({R_DATA_span}) ;


//MOSI
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        MOSI <= 1;
    end
    else if(current_state == MOSI_LOAD_READ ) begin
        case(counter)
			1 : MOSI  <= 0;
			2 : MOSI  <= 1;
			3 : MOSI  <= 0;
            4 : MOSI  <= 1;
            5 : MOSI  <= 0;
            6 : MOSI  <= 0;
            7 : MOSI  <= 0;
            8 : MOSI  <= 1;
            9 : MOSI  <= 0;
            10 : MOSI <= 0;
			11 : MOSI <= 0;
			12 : MOSI <= 0;
			13 : MOSI <= 0;
            14 : MOSI <= 0;
            15 : MOSI <= 0;
            16 : MOSI <= 0;
            17 : MOSI <= 0;
            18 : MOSI <= 0;
            19 : MOSI <= 0;
            20 : MOSI <= 0;
			21 : MOSI <= 0;
			22 : MOSI <= 0;
			23 : MOSI <= 0;
            24 : MOSI <= 0;
            25 : MOSI <= addr_sd_span[15];
            26 : MOSI <= addr_sd_span[14];
            27 : MOSI <= addr_sd_span[13];
            28 : MOSI <= addr_sd_span[12];
            29 : MOSI <= addr_sd_span[11];
            30 : MOSI <= addr_sd_span[10];
			31 : MOSI <= addr_sd_span[9];
			32 : MOSI <= addr_sd_span[8];
			33 : MOSI <= addr_sd_span[7];
            34 : MOSI <= addr_sd_span[6];
            35 : MOSI <= addr_sd_span[5];
            36 : MOSI <= addr_sd_span[4];
            37 : MOSI <= addr_sd_span[3];
            38 : MOSI <= addr_sd_span[2];
            39 : MOSI <= addr_sd_span[1];
            40 : MOSI <= addr_sd_span[0];
			41 : MOSI <= CRC7_R_out[6];
			42 : MOSI <= CRC7_R_out[5];
			43 : MOSI <= CRC7_R_out[4];
            44 : MOSI <= CRC7_R_out[3];
            45 : MOSI <= CRC7_R_out[2];
            46 : MOSI <= CRC7_R_out[1];
            47 : MOSI <= CRC7_R_out[0];
            48 : MOSI <= 1;
			default : MOSI <= 1;
		endcase
        //MOSI <= 0;
    end
    else if(current_state == MOSI_LOAD_WRITE) begin
        case(counter)
			1 : MOSI  <= 0;
			2 : MOSI  <= 1;

			3 : MOSI  <= 0;
            4 : MOSI  <= 1;
            5 : MOSI  <= 1;
            6 : MOSI  <= 0;
            7 : MOSI  <= 0;
            8 : MOSI  <= 0;

            9 : MOSI  <= 0;
            10 : MOSI <= 0;
			11 : MOSI <= 0;
			12 : MOSI <= 0;
			13 : MOSI <= 0;
            14 : MOSI <= 0;
            15 : MOSI <= 0;
            16 : MOSI <= 0;
            17 : MOSI <= 0;
            18 : MOSI <= 0;
            19 : MOSI <= 0;
            20 : MOSI <= 0;
			21 : MOSI <= 0;
			22 : MOSI <= 0;
			23 : MOSI <= 0;
            24 : MOSI <= 0;
            25 : MOSI <= addr_sd_span[15];
            26 : MOSI <= addr_sd_span[14];
            27 : MOSI <= addr_sd_span[13];
            28 : MOSI <= addr_sd_span[12];
            29 : MOSI <= addr_sd_span[11];
            30 : MOSI <= addr_sd_span[10];
			31 : MOSI <= addr_sd_span[9];
			32 : MOSI <= addr_sd_span[8];
			33 : MOSI <= addr_sd_span[7];
            34 : MOSI <= addr_sd_span[6];
            35 : MOSI <= addr_sd_span[5];
            36 : MOSI <= addr_sd_span[4];
            37 : MOSI <= addr_sd_span[3];
            38 : MOSI <= addr_sd_span[2];
            39 : MOSI <= addr_sd_span[1];
            40 : MOSI <= addr_sd_span[0];
			41 : MOSI <= CRC7_W_out[6];
			42 : MOSI <= CRC7_W_out[5];
			43 : MOSI <= CRC7_W_out[4];
            44 : MOSI <= CRC7_W_out[3];
            45 : MOSI <= CRC7_W_out[2];
            46 : MOSI <= CRC7_W_out[1];
            47 : MOSI <= CRC7_W_out[0];
            48 : MOSI <= 1;
			default : MOSI <= 1;
		endcase
        //MOSI <= 0;
    end
    else if(counter_MOSI_write_2 >=39) begin
        case(counter_MOSI_write_2-38)
			1 : MOSI  <= 1;
			2 : MOSI  <= 1;
			3 : MOSI  <= 1;
            4 : MOSI  <= 1;
            5 : MOSI  <= 1;
            6 : MOSI  <= 1;
            7 : MOSI  <= 1;
            8 : MOSI  <= 0;
            9 : MOSI  <= R_DATA_span[63];
            10 : MOSI <= R_DATA_span[62];
			11 : MOSI <= R_DATA_span[61];
			12 : MOSI <= R_DATA_span[60];
			13 : MOSI <= R_DATA_span[59];
            14 : MOSI <= R_DATA_span[58];
            15 : MOSI <= R_DATA_span[57];
            16 : MOSI <= R_DATA_span[56];
            17 : MOSI <= R_DATA_span[55];
            18 : MOSI <= R_DATA_span[54];
            19 : MOSI <= R_DATA_span[53];
            20 : MOSI <= R_DATA_span[52];
			21 : MOSI <= R_DATA_span[51];
			22 : MOSI <= R_DATA_span[50];
			23 : MOSI <= R_DATA_span[49];
            24 : MOSI <= R_DATA_span[48];
            25 : MOSI <= R_DATA_span[47];
            26 : MOSI <= R_DATA_span[46];
            27 : MOSI <= R_DATA_span[45];
            28 : MOSI <= R_DATA_span[44];
            29 : MOSI <= R_DATA_span[43];
            30 : MOSI <= R_DATA_span[42];
			31 : MOSI <= R_DATA_span[41];
			32 : MOSI <= R_DATA_span[40];
			33 : MOSI <= R_DATA_span[39];
            34 : MOSI <= R_DATA_span[38];
            35 : MOSI <= R_DATA_span[37];
            36 : MOSI <= R_DATA_span[36];
            37 : MOSI <= R_DATA_span[35];
            38 : MOSI <= R_DATA_span[34];
            39 : MOSI <= R_DATA_span[33];
            40 : MOSI <= R_DATA_span[32];
			41 : MOSI <= R_DATA_span[31];
			42 : MOSI <= R_DATA_span[30];
            43 : MOSI <= R_DATA_span[29];
            44 : MOSI <= R_DATA_span[28];
            45 : MOSI <= R_DATA_span[27];
            46 : MOSI <= R_DATA_span[26];
            47 : MOSI <= R_DATA_span[25];
            48 : MOSI <= R_DATA_span[24];
            49 : MOSI <= R_DATA_span[23];
            50 : MOSI <= R_DATA_span[22];
            51 : MOSI <= R_DATA_span[21];
            52 : MOSI <= R_DATA_span[20];
            53 : MOSI <= R_DATA_span[19]; 
            54 : MOSI <= R_DATA_span[18]; 
            55 : MOSI <= R_DATA_span[17]; 
            56 : MOSI <= R_DATA_span[16]; 
            57 : MOSI <= R_DATA_span[15];
            58 : MOSI <= R_DATA_span[14];
            59 : MOSI <= R_DATA_span[13];
            60 : MOSI <= R_DATA_span[12];
            61 : MOSI <= R_DATA_span[11];
            62 : MOSI <= R_DATA_span[10];
            63 : MOSI <= R_DATA_span[9];
            64 : MOSI <= R_DATA_span[8];
            65 : MOSI <= R_DATA_span[7];
            66 : MOSI <= R_DATA_span[6];
            67 : MOSI <= R_DATA_span[5];
            68 : MOSI <= R_DATA_span[4];
            69 : MOSI <= R_DATA_span[3];
            70 : MOSI <= R_DATA_span[2];
            71 : MOSI <= R_DATA_span[1];
            72 : MOSI <= R_DATA_span[0];
            73 : MOSI <= CRC16_out[15];
            74 : MOSI <= CRC16_out[14];
            75 : MOSI <= CRC16_out[13];
            76 : MOSI <= CRC16_out[12];
            77 : MOSI <= CRC16_out[11];
            78 : MOSI <= CRC16_out[10];
            79 : MOSI <= CRC16_out[9];
            80 : MOSI <= CRC16_out[8];
            81 : MOSI <= CRC16_out[7];
            82 : MOSI <= CRC16_out[6];
            83 : MOSI <= CRC16_out[5];
            84 : MOSI <= CRC16_out[4];
            85 : MOSI <= CRC16_out[3];
            86 : MOSI <= CRC16_out[2];
            87 : MOSI <= CRC16_out[1];
            88 : MOSI <= CRC16_out[0];
			default : MOSI <= 1;
		endcase
        //MOSI <= 0;
    end
    else MOSI <= 1;
end




//==============================================//
//             Example for function             //
//==============================================//

function automatic [6:0] CRC7;  // Return 7-bit result
    input [39:0] data;  // 40-bit data input
    reg [6:0] crc;
    integer i;
    reg data_in, data_out;
    parameter polynomial = 7'h9;  // x^7 + x^3 + 1
    begin
        crc = 7'd0;
        for (i = 0; i < 40; i = i + 1) begin
            data_in = data[39-i];
            data_out = crc[6];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC7 = crc;
    end
endfunction

function automatic [15:0] CRC16;  
    input [63:0] data;  
    reg [15:0] crc;
    integer i;
    reg data_in,data_out;
    parameter polynomial = 16'h1021;  

    begin
        crc = 16'd0;
        for (i = 0; i < 64; i = i + 1) begin
            data_in = data[63-i];
            data_out = crc[15];
            crc = crc << 1;  // Shift the CRC
            if (data_in ^ data_out) begin
                crc = crc ^ polynomial;
            end
        end
        CRC16 = crc;
    end
endfunction


function automatic [15:0] CRC16_CCITT;
    // Try to implement CRC-16-CCITT function by yourself.
endfunction
endmodule



