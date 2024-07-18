//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Lab02 Exercise		: Enigma
//   Author     		: Yi-Xuan, Ran
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : ENIGMA.v
//   Module Name : ENIGMA
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
 
module ENIGMA
#(  
    parameter IDLE        =  3'b000,
    parameter LOAD        =  3'b001,
	parameter CRYPTION    =  3'b010,
	parameter OUTPUT      =  3'b011
)
(
	// Input Ports
	clk, 
	rst_n, 
	in_valid, 
	in_valid_2, 
	crypt_mode, 
	code_in, 

	// Output Ports
	out_code, 
	out_valid
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk;              // clock input
input rst_n;            // asynchronous reset (active low)
input in_valid;         // code_in_temp valid signal for rotor (level sensitive). 0/1: inactive/active
input in_valid_2;       // code_in_temp valid signal for code  (level sensitive). 0/1: inactive/active
input crypt_mode;       // 0: encrypt; 1:decrypt; only valid for 1 cycle when in_valid is active

input [6-1:0] code_in;	// When in_valid   is active, then code_in_temp is input of rotors. 
						// When in_valid_2 is active, then code_in_temp is input of code words.
							
output reg out_valid;       	// 0: out_code is not valid; 1: out_code is valid
output reg [6-1:0] out_code;	// encrypted/decrypted code word

// ===============================================================
// Design
// ===============================================================
reg[2:0] current_state,next_state;
reg[69:0][6-1:0] rotor_A;
reg[69:0][6-1:0] rotor_B;
reg[9:0] load_counter;
reg crypt_type;
reg[4:0][5:0] shift_vector;
reg in_valid_temp;
reg out_valid_temp,in_valid_2_temp,in_valid_2_temp_temp;
reg[69:0][6-1:0] rotor_A_temp,rotor_A_temp_2;
reg[69:0][6-1:0] rotor_B_temp;
reg [6-1:0] out,code_in_temp,out_temp;
reg[10:0] count;


integer k,l,s,m,n,i,x;

//reg cryption;
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n) current_state <= IDLE;
// 	else current_state <= next_state;
// end

// always@(*) begin
// 	if(!rst_n) next_state = IDLE;
// 	else begin
// 		case(current_state)
// 			IDLE : begin
// 				if(in_valid) next_state = LOAD;
// 				else if(in_valid_2) next_state = CRYPTION;
// 				else next_state = current_state;
// 			end
// 			LOAD : begin
// 				if(in_valid_2) next_state = CRYPTION;
// 				else next_state = current_state;
// 			end
// 			CRYPTION : begin
// 				if(out_valid) next_state = OUTPUT;
// 				else next_state = current_state;
// 			end
// 			OUTPUT : begin
// 				if(!out_valid) next_state = IDLE;
// 				else next_state = current_state;
// 			end

// 			default : next_state = current_state;
// 		endcase
// 	end
// end

//out valid
always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin 
			out_valid <= 0;
		end
		else if(count>=3)
		begin
			out_valid <= 1;
		end

		else begin
			out_valid <= 0;
		end
end

always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin 
			code_in_temp <= 0;
		end
		else begin
			code_in_temp <= code_in;
		end
end

always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin 
			in_valid_2_temp_temp <= 0;
		end
		else begin
			in_valid_2_temp_temp <= in_valid_2_temp;
		end
end

always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin 
			in_valid_2_temp <= 0;
		end
		else begin
			in_valid_2_temp <= in_valid_2;
		end
end

always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin 
			rotor_A_temp <= 0;
		end
		else begin
			rotor_A_temp <= rotor_A;
		end
end


always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin 
			rotor_B_temp <= 0;
		end
		else begin
			rotor_B_temp <= rotor_B;
		end
end


always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin 
			in_valid_temp <= 0;
		end
		else begin
			in_valid_temp <= in_valid;
		end
end


// //shift vector (just for checking)
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin 
// 		shift_vector <=0;
// 		//out_code <= 0;
// 	end
// 	else if(current_state == 2 | in_valid_2)
// 	begin
// 		shift_vector[0][5:0] <= code_in_temp;
// 		shift_vector[1][5:0] <= rotor_A[code_in_temp][5:0];
// 		shift_vector[2][5:0] <= rotor_B[rotor_A[code_in_temp][5:0]][5:0];
// 		shift_vector[3][5:0] <= 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0];
// 		for(k=0;k<64;k++) begin
// 			if(rotor_B[k][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) begin 
// 				shift_vector[4][5:0] <= k;
// 				for(s=0;s<64;s++) begin
// 					if(rotor_A[s][5:0] == k) begin 
// 						//out_code <= l;
// 					end
// 				end
// 			end
// 		end
// 	end
// 	else begin
// 	end
// end


//output
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin 
		out <= 0;
	end
	else if(in_valid_2_temp) //out_valid_on
	begin
		for(k=0;k<64;k++) begin
			if(rotor_B[k][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) begin 
				out <= k;
			end
		end
	end
	else begin
		out <= 0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin 
		out_temp <= 0;
	end
	else if(in_valid_2_temp_temp) //out_valid_on
		begin
			for(l=0;l<64;l++) begin
				if(rotor_A_temp[l][5:0] == out) begin 
					out_temp <= l;
				end
			end
		end
	else begin
		out_temp <= 0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin 
		out_code <= 0;
	end
	else if(in_valid_2_temp_temp) //out_valid_on
		out_code <= out_temp;
	else begin
		out_code <= 0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin 
		count <= 0;
	end
	else if(in_valid_2 | in_valid_2_temp ) //out_valid_on
		count <= count + 1 ;
	else begin
		count <= 0;
	end
end





reg[5:0] n_temp;
always@(*) begin
	if(!rst_n) n_temp = 0;
	else if(((in_valid_2_temp) & crypt_type)) begin
		if(rotor_B[0][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 0;
		else if(rotor_B[1][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 1;
		else if(rotor_B[2][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 2;
		else if(rotor_B[3][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 3;
		else if(rotor_B[4][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 4;
		else if(rotor_B[5][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 5;
		else if(rotor_B[6][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 6;
		else if(rotor_B[7][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 7;
		else if(rotor_B[8][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 8;
		else if(rotor_B[9][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 9;
		else if(rotor_B[10][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 10;
		else if(rotor_B[11][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 11;
		else if(rotor_B[12][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 12;
		else if(rotor_B[13][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 13;
		else if(rotor_B[14][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 14;
		else if(rotor_B[15][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 15;
		else if(rotor_B[16][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 16;
		else if(rotor_B[17][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 17;
		else if(rotor_B[18][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 18;
		else if(rotor_B[19][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 19;
		else if(rotor_B[20][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 20;
		else if(rotor_B[21][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 21;
		else if(rotor_B[22][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 22;
		else if(rotor_B[23][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 23;
		else if(rotor_B[24][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 24;
		else if(rotor_B[25][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 25;
		else if(rotor_B[26][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 26;
		else if(rotor_B[27][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 27;
		else if(rotor_B[28][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 28;
		else if(rotor_B[29][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 29;
		else if(rotor_B[30][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 30;
		else if(rotor_B[31][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 31;
		else if(rotor_B[32][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 32;
		else if(rotor_B[33][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 33;
		else if(rotor_B[34][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 34;
		else if(rotor_B[35][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 35;
		else if(rotor_B[36][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 36;
		else if(rotor_B[37][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 37;
		else if(rotor_B[38][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 38;
		else if(rotor_B[39][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 39;
		else if(rotor_B[40][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 40;
		else if(rotor_B[41][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 41;
		else if(rotor_B[42][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 42;
		else if(rotor_B[43][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 43;
		else if(rotor_B[44][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 44;
		else if(rotor_B[45][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 45;
		else if(rotor_B[46][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 46;
		else if(rotor_B[47][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 47;
		else if(rotor_B[48][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 48;
		else if(rotor_B[49][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 49;
		else if(rotor_B[50][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 50;
		else if(rotor_B[51][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 51;
		else if(rotor_B[52][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 52;
		else if(rotor_B[53][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 53;
		else if(rotor_B[54][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 54;
		else if(rotor_B[55][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 55;
		else if(rotor_B[56][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 56;
		else if(rotor_B[57][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 57;
		else if(rotor_B[58][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 58;
		else if(rotor_B[59][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 59;
		else if(rotor_B[60][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 60;
		else if(rotor_B[61][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 61;
		else if(rotor_B[62][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 62;
		else if(rotor_B[63][5:0] == 63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) n_temp = 63;
		else n_temp = 0;
	end
	else n_temp = 0;
end


always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin 
		rotor_A <= 69'b0;
		load_counter <= 10'b0;
	end
	else if(in_valid_temp) begin
		if(load_counter <= 10'd63) begin
			rotor_A[load_counter][5:0] <= code_in_temp[5:0];
			load_counter <= load_counter+1;
		end
		else if(load_counter >= 10'd64 & load_counter <= 127) begin
			load_counter <= load_counter+1;
		end
		else begin
			load_counter <= load_counter;
		end
	end
	else if(((in_valid_2_temp) & !crypt_type)) begin
	for(i=0;i<64;i=i+1) begin
		if((rotor_A[code_in_temp][1:0]+i) < 64) begin
			rotor_A[rotor_A[code_in_temp][1:0]+i][5:0] <= rotor_A[i][5:0];
		end
		else if((rotor_A[code_in_temp][1:0]+i) > 63) begin
			rotor_A[rotor_A[code_in_temp][1:0]+i-64][5:0] <= rotor_A[i][5:0];
		end
	end
	end
	else if(((in_valid_2_temp) & crypt_type)) begin
	for(i=0;i<64;i=i+1) begin
		if((n_temp[1:0]+i) < 64) begin 
			rotor_A[n_temp[1:0]+i][5:0] <= rotor_A[i][5:0];
		end
		else if((n_temp[1:0]+i) > 63) begin
			rotor_A[n_temp[1:0]+i-64][5:0] <= rotor_A[i][5:0];
	end
	end
	end
	else begin
		rotor_A <= rotor_A;
		load_counter <= 0;
	end
end




always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin 
		rotor_B <= 69'b0;
	end
	else if(in_valid_temp) begin
		if(load_counter >= 10'd64 & load_counter <= 127) begin
			rotor_B[load_counter-64][5:0] <= code_in_temp[5:0];
			//load_counter <= load_counter+1;
		end
		else begin
		end
	end
	else if(in_valid_2_temp & !crypt_type) begin
		for(x=0;x<64;x=x+1) begin
			if((rotor_B[rotor_A[code_in_temp][5:0]][2:0]) == 3'd0) begin
				rotor_B[x+1][5:0] <= rotor_B[x+1][5:0];
			end
			else if(rotor_B[rotor_A[code_in_temp][5:0]][2:0] == 3'd1) begin
				if((x%2)==0) begin
					rotor_B[x+1][5:0] <= rotor_B[x][5:0];
					rotor_B[x][5:0] <= rotor_B[x+1][5:0];
				end
			end
			else if(rotor_B[rotor_A[code_in_temp][5:0]][2:0] == 3'd2) begin
				if((x%4)==0) begin
					rotor_B[x+2][5:0] <= rotor_B[x][5:0]; 
					rotor_B[x][5:0] <= rotor_B[x+2][5:0];
					rotor_B[x+3][5:0] <= rotor_B[x+1][5:0]; 
					rotor_B[x+1][5:0] <= rotor_B[x+3][5:0];
				end
			end
			else if(rotor_B[rotor_A[code_in_temp][5:0]][2:0] == 3'd3) begin
				if(((x%8)==0) | ((x%8)==7)) begin
					rotor_B[x][5:0] <= rotor_B[x][5:0];
				end
				else if((x%8)==1) begin
					rotor_B[x+3][5:0] <= rotor_B[x][5:0]; 
					rotor_B[x][5:0] <= rotor_B[x+3][5:0];
					rotor_B[x+4][5:0] <= rotor_B[x+1][5:0]; 
					rotor_B[x+1][5:0] <= rotor_B[x+4][5:0];
					rotor_B[x+5][5:0] <= rotor_B[x+2][5:0]; 
					rotor_B[x+2][5:0] <= rotor_B[x+5][5:0];
				end
			end
			else if(rotor_B[rotor_A[code_in_temp][5:0]][2:0] == 3'd4) begin
				if((x%8)==0) begin
					rotor_B[x][5:0] <= rotor_B[x+4][5:0];
					rotor_B[x+4][5:0] <= rotor_B[x][5:0]; 
					rotor_B[x+1][5:0] <= rotor_B[x+5][5:0];
					rotor_B[x+5][5:0] <= rotor_B[x+1][5:0]; 
					rotor_B[x+2][5:0] <= rotor_B[x+6][5:0];
					rotor_B[x+6][5:0] <= rotor_B[x+2][5:0]; 
					rotor_B[x+3][5:0] <= rotor_B[x+7][5:0];
					rotor_B[x+7][5:0] <= rotor_B[x+3][5:0]; 
				end
			end
			else if(rotor_B[rotor_A[code_in_temp][5:0]][2:0] == 3'd5) begin
				if((x%8)==0) begin
					rotor_B[x][5:0] <= rotor_B[x+5][5:0];
					rotor_B[x+1][5:0] <= rotor_B[x+6][5:0];
					rotor_B[x+2][5:0] <= rotor_B[x+7][5:0]; 
					rotor_B[x+3][5:0] <= rotor_B[x+3][5:0];
					rotor_B[x+4][5:0] <= rotor_B[x+4][5:0];
					rotor_B[x+5][5:0] <= rotor_B[x][5:0];
					rotor_B[x+6][5:0] <= rotor_B[x+1][5:0];
					rotor_B[x+7][5:0] <= rotor_B[x+2][5:0];
				end
			end
			else if(rotor_B[rotor_A[code_in_temp][5:0]][2:0] == 3'd6) begin
				if((x%8)==0) begin
					rotor_B[x][5:0] <= rotor_B[x+6][5:0];
					rotor_B[x+1][5:0] <= rotor_B[x+7][5:0];
					rotor_B[x+2][5:0] <= rotor_B[x+3][5:0]; 
					rotor_B[x+3][5:0] <= rotor_B[x+2][5:0];
					rotor_B[x+4][5:0] <= rotor_B[x+5][5:0];
					rotor_B[x+5][5:0] <= rotor_B[x+4][5:0];
					rotor_B[x+6][5:0] <= rotor_B[x][5:0];
					rotor_B[x+7][5:0] <= rotor_B[x+1][5:0];
				end
			end
			else if(rotor_B[rotor_A[code_in_temp][5:0]][2:0] == 3'd7) begin
				if((x%8)==0) begin
					rotor_B[x][5:0] <= rotor_B[x+7][5:0];
					rotor_B[x+1][5:0] <= rotor_B[x+6][5:0];
					rotor_B[x+2][5:0] <= rotor_B[x+5][5:0]; 
					rotor_B[x+3][5:0] <= rotor_B[x+4][5:0];
					rotor_B[x+4][5:0] <= rotor_B[x+3][5:0];
					rotor_B[x+5][5:0] <= rotor_B[x+2][5:0];
					rotor_B[x+6][5:0] <= rotor_B[x+1][5:0];
					rotor_B[x+7][5:0] <= rotor_B[x][5:0];
				end
			end
		end
	end
	else if(in_valid_2_temp & crypt_type) begin
		for(x=0;x<64;x=x+1) begin
			if(((63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) %8) == 0) begin
				rotor_B[x+1][5:0] <= rotor_B[x+1][5:0];
			end
			else if(((63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) %8) == 1) begin
				if((x%2)==0) begin
					rotor_B[x+1][5:0] <= rotor_B[x][5:0];
					rotor_B[x][5:0] <= rotor_B[x+1][5:0];
				end
			end
			else if(((63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) %8) == 2) begin
				if((x%4)==0) begin
					rotor_B[x+2][5:0] <= rotor_B[x][5:0]; 
					rotor_B[x][5:0] <= rotor_B[x+2][5:0];
					rotor_B[x+3][5:0] <= rotor_B[x+1][5:0]; 
					rotor_B[x+1][5:0] <= rotor_B[x+3][5:0];
				end
			end
			else if(((63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) %8) == 3) begin
				if(((x%8)==0) | ((x%8)==7)) begin
					rotor_B[x][5:0] <= rotor_B[x][5:0];
				end
				else if((x%8)==1) begin
					rotor_B[x+3][5:0] <= rotor_B[x][5:0]; 
					rotor_B[x][5:0] <= rotor_B[x+3][5:0];
					rotor_B[x+4][5:0] <= rotor_B[x+1][5:0]; 
					rotor_B[x+1][5:0] <= rotor_B[x+4][5:0];
					rotor_B[x+5][5:0] <= rotor_B[x+2][5:0]; 
					rotor_B[x+2][5:0] <= rotor_B[x+5][5:0];
				end
			end
			else if(((63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) %8) == 4) begin
				if((x%8)==0) begin
					rotor_B[x][5:0] <= rotor_B[x+4][5:0];
					rotor_B[x+4][5:0] <= rotor_B[x][5:0]; 
					rotor_B[x+1][5:0] <= rotor_B[x+5][5:0];
					rotor_B[x+5][5:0] <= rotor_B[x+1][5:0]; 
					rotor_B[x+2][5:0] <= rotor_B[x+6][5:0];
					rotor_B[x+6][5:0] <= rotor_B[x+2][5:0]; 
					rotor_B[x+3][5:0] <= rotor_B[x+7][5:0];
					rotor_B[x+7][5:0] <= rotor_B[x+3][5:0]; 
				end
			end
			else if(((63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) %8) == 5) begin
				if((x%8)==0) begin
					rotor_B[x][5:0] <= rotor_B[x+5][5:0];
					rotor_B[x+1][5:0] <= rotor_B[x+6][5:0];
					rotor_B[x+2][5:0] <= rotor_B[x+7][5:0]; 
					rotor_B[x+3][5:0] <= rotor_B[x+3][5:0];
					rotor_B[x+4][5:0] <= rotor_B[x+4][5:0];
					rotor_B[x+5][5:0] <= rotor_B[x][5:0];
					rotor_B[x+6][5:0] <= rotor_B[x+1][5:0];
					rotor_B[x+7][5:0] <= rotor_B[x+2][5:0];
				end
			end
			else if(((63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) %8) == 6) begin
				if((x%8)==0) begin
					rotor_B[x][5:0] <= rotor_B[x+6][5:0];
					rotor_B[x+1][5:0] <= rotor_B[x+7][5:0];
					rotor_B[x+2][5:0] <= rotor_B[x+3][5:0]; 
					rotor_B[x+3][5:0] <= rotor_B[x+2][5:0];
					rotor_B[x+4][5:0] <= rotor_B[x+5][5:0];
					rotor_B[x+5][5:0] <= rotor_B[x+4][5:0];
					rotor_B[x+6][5:0] <= rotor_B[x][5:0];
					rotor_B[x+7][5:0] <= rotor_B[x+1][5:0];
				end
			end
			else if(((63 - rotor_B[rotor_A[code_in_temp][5:0]][5:0]) %8) == 7) begin
				if((x%8)==0) begin
					rotor_B[x][5:0] <= rotor_B[x+7][5:0];
					rotor_B[x+1][5:0] <= rotor_B[x+6][5:0];
					rotor_B[x+2][5:0] <= rotor_B[x+5][5:0]; 
					rotor_B[x+3][5:0] <= rotor_B[x+4][5:0];
					rotor_B[x+4][5:0] <= rotor_B[x+3][5:0];
					rotor_B[x+5][5:0] <= rotor_B[x+2][5:0];
					rotor_B[x+6][5:0] <= rotor_B[x+1][5:0];
					rotor_B[x+7][5:0] <= rotor_B[x][5:0];
				end
			end
		end
	end
	else begin
		rotor_B <= rotor_B;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		crypt_type <= 0;
	end
	else if(in_valid && in_valid_temp == 0) begin
		crypt_type <= crypt_mode;
	end
	else begin
		crypt_type <= crypt_type;
	end
end



endmodule