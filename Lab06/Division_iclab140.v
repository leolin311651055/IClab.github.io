//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : Division_IP.v
//   	Module Name : Division_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module Division_IP #(parameter IP_WIDTH = 7) (
    // Input signals
    IN_Dividend, IN_Divisor,
    // Output signals
    OUT_Quotient
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_WIDTH*4-1:0]  IN_Dividend;
input [IP_WIDTH*4-1:0]  IN_Divisor;

output logic [IP_WIDTH*4-1:0] OUT_Quotient;

integer j, k;

// reg [3:0] Divisor_power_in  [0:(IP_WIDTH - 1)]; //debug
reg [3:0] Divisor_coeff_in  [0:(IP_WIDTH - 1)];

reg [3:0] Divisor_coeff_after_mult_pre  [0:(IP_WIDTH - 1)][0:(IP_WIDTH - 1)]; //[Iterate times][data]
reg [3:0] Divisor_coeff_after_mult  [0:(IP_WIDTH - 1)][0:(IP_WIDTH - 1)];


reg [3:0] Dividend_coeff_after_xor [0:(IP_WIDTH - 1)][0:(IP_WIDTH - 1)]; //[Iterate times][data]
reg [3:0] Dividend_coeff_after_xor_temp [0:(IP_WIDTH - 1)][0:(IP_WIDTH - 1)]; //for translate table ; Optimization: can be smaller




// reg [(IP_WIDTH - 1):0] point_head_Dividend [0:(IP_WIDTH - 1)][0:(IP_WIDTH - 1)];//[Iterate times][Sort times] ; Optimization: Think clearly about the number of bits
// reg [(IP_WIDTH - 1):0] point_head_Divisor [0:(IP_WIDTH - 1)][0:(IP_WIDTH - 1)];
reg [(IP_WIDTH - 1):0] point_head_Dividend [0:(IP_WIDTH - 1)];
reg [(IP_WIDTH - 1):0] point_head_Divisor  [0:(IP_WIDTH - 1)];

reg [3:0] div_power_ans [0:(IP_WIDTH - 1)];//[Iterate times]
reg [3:0] div_coeff_ans [0:(IP_WIDTH - 1)];//[Iterate times] 

wire [3:0] tables_idx_to_int [0:15]; //The integer corresponding to index
assign tables_idx_to_int[0]  = 4'd1 ;
assign tables_idx_to_int[1]  = 4'd2 ;
assign tables_idx_to_int[2]  = 4'd4 ;
assign tables_idx_to_int[3]  = 4'd8 ;
assign tables_idx_to_int[4]  = 4'd3 ;
assign tables_idx_to_int[5]  = 4'd6 ;
assign tables_idx_to_int[6]  = 4'd12;
assign tables_idx_to_int[7]  = 4'd11;
assign tables_idx_to_int[8]  = 4'd5 ;
assign tables_idx_to_int[9]  = 4'd10;
assign tables_idx_to_int[10] = 4'd7 ;
assign tables_idx_to_int[11] = 4'd14;
assign tables_idx_to_int[12] = 4'd15;
assign tables_idx_to_int[13] = 4'd13;
assign tables_idx_to_int[14] = 4'd9 ;
assign tables_idx_to_int[15] = 4'd0 ;

wire [3:0] tables_int_to_idx [0:15]; //The integer corresponding to index
assign tables_int_to_idx[0]  = 4'd15 ;
assign tables_int_to_idx[1]  = 4'd0 ;
assign tables_int_to_idx[2]  = 4'd1 ;
assign tables_int_to_idx[3]  = 4'd4 ;
assign tables_int_to_idx[4]  = 4'd2 ;
assign tables_int_to_idx[5]  = 4'd8 ;
assign tables_int_to_idx[6]  = 4'd5 ;
assign tables_int_to_idx[7]  = 4'd10;
assign tables_int_to_idx[8]  = 4'd3 ;
assign tables_int_to_idx[9]  = 4'd14;
assign tables_int_to_idx[10] = 4'd9 ;
assign tables_int_to_idx[11] = 4'd7 ;
assign tables_int_to_idx[12] = 4'd6 ;
assign tables_int_to_idx[13] = 4'd13;
assign tables_int_to_idx[14] = 4'd11;
assign tables_int_to_idx[15] = 4'd12;

// reg [3:0] debug_a [(IP_WIDTH - 1):0];
// reg [3:0] debug_b [(IP_WIDTH - 1):0];
// reg [3:0] debug_c [0:(IP_WIDTH - 1)];

reg [3:0] ans_count;
// ===============================================================
// Design
// ===============================================================


always@(*) begin
    for (k = 0; k < IP_WIDTH ; k ++ ) begin
        Dividend_coeff_after_xor[0][IP_WIDTH - k - 1] = IN_Dividend[4*k+:4];
        Divisor_coeff_in[IP_WIDTH - k - 1] = IN_Divisor[4*k+:4];
        // Divisor_power_in[IP_WIDTH - k - 1] = k; //debug
    end
    point_head_Dividend[0] = 0;
    point_head_Divisor[0] = 0;
    // ===============================================================
    // sort (point)
    // ===============================================================
    for (k = 0; k < IP_WIDTH - 1 ; k ++ ) begin //Sort times
        if(Dividend_coeff_after_xor[0][point_head_Dividend[k]] == 15) begin
            point_head_Dividend[k + 1] = point_head_Dividend[k] + 1;
        end
        else point_head_Dividend[k + 1] = point_head_Dividend[k];
    end
    for (k = 0; k < IP_WIDTH - 1 ; k ++ ) begin //Sort times
        if(Divisor_coeff_in[point_head_Divisor[k]] == 15) begin
            point_head_Divisor[k + 1] = point_head_Divisor[k] + 1;
        end
        else point_head_Divisor[k + 1] = point_head_Divisor[k];
    end
end

// ===============================================================
// div
// ===============================================================
genvar i;
generate
for (i = 0; i < IP_WIDTH ; i ++ ) begin : compute//Iterate times
    always@(*) begin
        // ===============================================================
        // max degree div
        // ===============================================================
        // debug_a[i] = point_head_Dividend[IP_WIDTH - 1] + i;
        // debug_b[i] = Dividend_coeff_after_xor[i][point_head_Dividend[IP_WIDTH - 1] + i];
        if(Dividend_coeff_after_xor[i][point_head_Dividend[IP_WIDTH - 1] + i] != 15) begin
            if(Dividend_coeff_after_xor[i][point_head_Dividend[IP_WIDTH - 1] + i] >= Divisor_coeff_in[point_head_Divisor[IP_WIDTH - 1]]) 
                div_coeff_ans[i] = Dividend_coeff_after_xor[i][point_head_Dividend[IP_WIDTH - 1] + i] - Divisor_coeff_in[point_head_Divisor[IP_WIDTH - 1]];
            else div_coeff_ans[i] = (15 - Divisor_coeff_in[point_head_Divisor[IP_WIDTH - 1]]) + Dividend_coeff_after_xor[i][point_head_Dividend[IP_WIDTH - 1] + i];
        end
        else begin
            div_coeff_ans[i] = 15;
        end
        if(i == 0) div_power_ans[i] = (IP_WIDTH - point_head_Dividend[IP_WIDTH - 1]) - (IP_WIDTH - point_head_Divisor[IP_WIDTH - 1]);
        else div_power_ans[i] = div_power_ans[i - 1] - 1;
        
        // ===============================================================
        // mult divisor
        // ==============================================================
        for (j = 0; j < IP_WIDTH ; j ++ ) begin
            if(Dividend_coeff_after_xor[i][point_head_Dividend[IP_WIDTH - 1] + i] != 15 && Divisor_coeff_in[j] != 15) begin
                if(Divisor_coeff_in[j] + div_coeff_ans[i] < 15) Divisor_coeff_after_mult[i][j] = Divisor_coeff_in[j] + div_coeff_ans[i];
                else if(Divisor_coeff_in[j] + div_coeff_ans[i] == 15) Divisor_coeff_after_mult[i][j] = 0;
                else Divisor_coeff_after_mult[i][j] = (Divisor_coeff_in[j] + div_coeff_ans[i] - 15);
            end
            else begin
                Divisor_coeff_after_mult[i][j] = 15;
            end
        end
        // ===============================================================
        // XOR
        // ==============================================================
        // debug_c[i] = point_head_Dividend[IP_WIDTH - 1] + i;
        for (j = 0; j < IP_WIDTH ; j ++ ) begin
            if(j < ((point_head_Dividend[IP_WIDTH - 1] + i) + IP_WIDTH - point_head_Divisor[IP_WIDTH - 1]) && j >= (point_head_Dividend[IP_WIDTH - 1] + i)) begin
                Dividend_coeff_after_xor_temp[i + 1][j] = tables_idx_to_int[Dividend_coeff_after_xor[i][j]]^tables_idx_to_int[Divisor_coeff_after_mult[i][point_head_Divisor[IP_WIDTH - 1] + j - (point_head_Dividend[IP_WIDTH - 1] + i)]]; //Optimization: can be smaller
                Dividend_coeff_after_xor[i + 1][j] = tables_int_to_idx[Dividend_coeff_after_xor_temp[i + 1][j]];
            end
            else if(j >= ((point_head_Dividend[IP_WIDTH - 1] + i) + IP_WIDTH - point_head_Divisor[IP_WIDTH - 1]))begin
                Dividend_coeff_after_xor[i + 1][j] = Dividend_coeff_after_xor[i][j];
            end
            else begin
                Dividend_coeff_after_xor[i + 1][j] = 15;
            end
        end     
    // ===============================================================
    // ready for sort
    // ===============================================================
    // debug_c[i] = point_head_Dividend[IP_WIDTH - 1] + i;
    end
end
endgenerate

// ===============================================================
// output answer
// ===============================================================
always@(*) begin
    ans_count = (IP_WIDTH - point_head_Dividend[IP_WIDTH - 1]) - (IP_WIDTH - point_head_Divisor[IP_WIDTH - 1]);
    for (j = 0; j < IP_WIDTH ; j ++ ) begin
        if((IP_WIDTH - point_head_Dividend[IP_WIDTH - 1]) >= (IP_WIDTH - point_head_Divisor[IP_WIDTH - 1]))begin
            if(j <= (IP_WIDTH - point_head_Dividend[IP_WIDTH - 1]) - (IP_WIDTH - point_head_Divisor[IP_WIDTH - 1])) OUT_Quotient[4*j+:4] = div_coeff_ans[(IP_WIDTH - point_head_Dividend[IP_WIDTH - 1]) - (IP_WIDTH - point_head_Divisor[IP_WIDTH - 1]) - j];
            else OUT_Quotient[4*j+:4] = 4'd15;
        end
        else OUT_Quotient[4*j+:4] = 4'd15;
    end
end

endmodule