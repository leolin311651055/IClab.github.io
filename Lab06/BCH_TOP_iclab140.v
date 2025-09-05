//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2025
//		Version		: v1.0
//   	File Name   : BCH_TOP.v
//   	Module Name : BCH_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`include "Division_IP.v"

module BCH_TOP(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_syndrome, 
    // Output signals
    out_valid, 
	out_location
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [3:0] in_syndrome;

output reg out_valid;
output reg [3:0] out_location;

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

parameter IDLE               = 0;
parameter INPUT              = 1;
parameter SORT               = 2;
parameter OMEGA_Q            = 3;
parameter OMEGA_Divisor      = 4;
parameter OMEGA              = 5;
parameter SIGMA_Q            = 6;
parameter SIGMA_S            = 7;
parameter SIGMA              = 8;
parameter COUNT_DEG          = 9;
parameter DIV_OR_NOT         = 10;
parameter COMPUTE_OUT        = 11;
parameter OUTPUT             = 12;

integer i;

reg [6:0] current_state;
reg [6:0] next_state;
reg [9:0] counter_1;
reg [9:0] counter_2;

reg  [27:0]  IN_Dividend;
reg  [27:0]  OUT_Quotient;
wire [27:0]  IN_Divisor;

reg  [3:0]  Divisor_coeff           [0:6];
wire [3:0] Quotient_coeff           [0:6];

reg  [3:0]   Sigma_0                [0:6];
reg  [3:0]   Sigma_1                [0:6];

reg [3:0]  mult_Omega                [0:6];
reg [3:0]  mult_Sigma                [0:6];

assign IN_Divisor[27:24]   = Divisor_coeff[0] ;
assign IN_Divisor[23:20]   = Divisor_coeff[1] ;
assign IN_Divisor[19:16]   = Divisor_coeff[2] ;
assign IN_Divisor[15:12]   = Divisor_coeff[3] ;
assign IN_Divisor[11:8]    = Divisor_coeff[4] ;
assign IN_Divisor[7:4]     = Divisor_coeff[5] ;
assign IN_Divisor[3:0]     = Divisor_coeff[6] ;
assign Quotient_coeff[0]   = OUT_Quotient[27:24];
assign Quotient_coeff[1]   = OUT_Quotient[23:20];
assign Quotient_coeff[2]   = OUT_Quotient[19:16];
assign Quotient_coeff[3]   = OUT_Quotient[15:12];
assign Quotient_coeff[4]   = OUT_Quotient[11:8] ;
assign Quotient_coeff[5]   = OUT_Quotient[7:4]  ;
assign Quotient_coeff[6]   = OUT_Quotient[3:0]  ;


reg [3:0]   Quotient_degree_sort    [0:6];
reg [3:0]   Divisor_degree_sort     [0:6];
reg [3:0]   Omega_degree_sort       [0:6];
reg [3:0]   Sigma_degree_sort       [0:6];


reg [3:0]   out_parameters          [0:3];
reg [3:0]   out_total;
reg [3:0]   out_data                [0:2];

wire [3:0]   Quotient_degree;
wire [3:0]   Divisor_degree;
reg [3:0]   Omega_degree;
reg [3:0]   Sigma_degree;

reg [3:0] debug_a [0:6];
reg [3:0] debug_b [0:6];

// always@(posedge clk or negedge rst_n) begin
//     if(!rst_n) Omega_degree <= 0;
//     else if(in_valid) Omega_degree <= 1;
//     else if(current_state == OMEGA) Omega_degree <= 6- (Quotient_degree + Omega_degree);
// end

// always@(posedge clk or negedge rst_n) begin
//     if(!rst_n) Sigma_degree <= 0;
//     else if(in_valid) Sigma_degree <= 6;
//     else if(current_state == SIGMA) Sigma_degree <= 6 - (Quotient_degree + Sigma_degree);
// end

assign Quotient_degree = Quotient_degree_sort[6];
assign Divisor_degree  = Divisor_degree_sort[6];
always@(*) begin
    Omega_degree_sort[0] = 0;
    for(i = 0 ; i < 6 ; i ++ ) begin
        if(mult_Omega[Omega_degree_sort[i]] == 4'b1111) Omega_degree_sort[i + 1] = Omega_degree_sort[i] + 1;
        else Omega_degree_sort[i + 1] = Omega_degree_sort[i];
    end
end

always@(*) begin
    Sigma_degree_sort[0] = 0;
    for(i = 0 ; i < 6 ; i ++ ) begin
        if(mult_Sigma[Sigma_degree_sort[i]] == 4'b1111) Sigma_degree_sort[i + 1] = Sigma_degree_sort[i] + 1;
        else Sigma_degree_sort[i + 1] = Sigma_degree_sort[i];
    end
end
// assign Omega_degree    = Omega_degree_sort[6];
// assign Sigma_degree    = Sigma_degree_sort[6];

// ===============================================================
// SOFT IP
// ===============================================================
Division_IP #(.IP_WIDTH(7)) I_Division_IP(.IN_Dividend(IN_Dividend), .IN_Divisor(IN_Divisor), .OUT_Quotient(OUT_Quotient)); 

// ===============================================================
// FSM
// ===============================================================
always@(*) begin
    if(!rst_n) next_state = IDLE;
    else if(current_state == IDLE) begin
        if(in_valid) next_state = INPUT;
        else next_state = current_state;
    end
    else if(current_state == INPUT) begin
        if(counter_1 == 5) next_state = SORT;
        else next_state = current_state;
    end
    else if(current_state == SORT) begin
        if(Quotient_degree >= (6 - Divisor_degree)) next_state = OMEGA_Q ;
        else if(Quotient_degree < (6 - Divisor_degree)) next_state = OMEGA_Divisor;
        else next_state = current_state;
    end
    else if(current_state == OMEGA_Q) begin
        if(counter_1 == (6 - Quotient_degree)) next_state = OMEGA;
        else next_state = current_state;
    end
    else if(current_state == OMEGA_Divisor) begin
        if(counter_1 == (6 - Divisor_degree)) next_state = OMEGA;
        else next_state = current_state;
    end
    else if(current_state == OMEGA) begin
        if(Quotient_degree >= (6 - Sigma_degree)) next_state = SIGMA_Q;
        else if(Quotient_degree < (6 - Sigma_degree)) next_state = SIGMA_S;
        else next_state = current_state;
    end

    else if(current_state == SIGMA_Q) begin
        if(counter_1 == (6 - Quotient_degree)) next_state = SIGMA;
        else next_state = current_state;
    end
    else if(current_state == SIGMA_S) begin
        if(counter_1 == Sigma_degree) next_state = SIGMA;
        else next_state = current_state;
    end
    else if(current_state == SIGMA) begin
        next_state = COUNT_DEG;
    end
    else if(current_state == COUNT_DEG) begin
        next_state = DIV_OR_NOT;
    end
    else if(current_state == DIV_OR_NOT) begin
        if(Sigma_degree <= 3 && Omega_degree <= 2) next_state = COMPUTE_OUT;
        else next_state = SORT;
    end
    else if(current_state == COMPUTE_OUT) begin
        if(counter_2 == 3 || counter_1 == 14) next_state = OUTPUT;
        else next_state = current_state;
    end
    else if(current_state == OUTPUT) begin
        if(counter_1 == 2) next_state = IDLE;
        else next_state = current_state;
    end
    else next_state = current_state;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter_1 <= 0;
    // else if(current_state == IDLE && !in_valid) counter_1 <= 1;
    else if(current_state == INPUT && counter_1 == 5) counter_1 <= 0;
    else if((current_state == INPUT || (in_valid && current_state == IDLE)) && counter_1 != 5) counter_1 <= counter_1 + 1;
    else if(current_state == OMEGA_Q && counter_1 == (6 - Quotient_degree)) counter_1 <= 0;
    else if(current_state == OMEGA_Q && counter_1 != (6 - Quotient_degree)) counter_1 <= counter_1 + 1;
    else if(current_state == OMEGA_Divisor && counter_1 == (6 - Divisor_degree)) counter_1 <= 0;
    else if(current_state == OMEGA_Divisor && counter_1 != (6 - Divisor_degree)) counter_1 <= counter_1 + 1;
    else if(current_state == SIGMA_Q && counter_1 == (6 - Quotient_degree)) counter_1 <= 0;
    else if(current_state == SIGMA_Q && counter_1 != (6 - Quotient_degree)) counter_1 <= counter_1 + 1;
    else if(current_state == SIGMA_S && counter_1 == Sigma_degree) counter_1 <= 0;
    else if(current_state == SIGMA_S && counter_1 != Sigma_degree) counter_1 <= counter_1 + 1;
    else if(current_state == COMPUTE_OUT && (counter_1 == 14 || counter_2 == 3)) counter_1 <= 0;
    else if(current_state == COMPUTE_OUT && !(counter_1 == 14 || counter_2 == 3)) counter_1 <= counter_1 + 1;
    else if(current_state == OUTPUT && counter_1 == 2) counter_1 <= 0;
    else if(current_state == OUTPUT && counter_1 != 2) counter_1 <= counter_1 + 1;
    else counter_1 <= counter_1;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) counter_2 <= 0;
    else if(current_state == IDLE) counter_2 <= 0;
    else if(current_state == COMPUTE_OUT && out_total == 0) counter_2 <= counter_2 + 1;
    else counter_2 <= counter_2;
end
// ===============================================================
// INPUT
// ===============================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) IN_Dividend <= 0;
    else if(current_state == INPUT || (in_valid && current_state == IDLE)) begin
        IN_Dividend <= 'h0ffffff;
    end 
    else if(current_state == SIGMA) IN_Dividend <= IN_Divisor;
    else IN_Dividend <= IN_Dividend;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 7 ; i ++ ) Divisor_coeff[i] <= 0;
    else if(current_state == INPUT || (in_valid && current_state == IDLE)) begin
       Divisor_coeff[6 - counter_1] <= in_syndrome;
       Divisor_coeff[0] <= 'hf;
    end 
    else if(current_state == SIGMA) for(i = 0 ; i < 7 ; i ++ ) Divisor_coeff[i] <= mult_Omega[i];
    else for(i = 0 ; i < 7 ; i ++ ) Divisor_coeff[i] <= Divisor_coeff[i];
end
// ===============================================================
// SORT
// ===============================================================
always@(*) begin
    Quotient_degree_sort[0] = 0;
    for(i = 0 ; i < 6 ; i ++ ) begin
        if(Quotient_coeff[Quotient_degree_sort[i]] == 4'b1111) Quotient_degree_sort[i + 1] = Quotient_degree_sort[i] + 1;
        else Quotient_degree_sort[i + 1] = Quotient_degree_sort[i];
    end
end

always@(*) begin
    Divisor_degree_sort[0] = 0;
    for(i = 0 ; i < 6 ; i ++ ) begin
        if(Divisor_coeff[Divisor_degree_sort[i]] == 4'b1111) Divisor_degree_sort[i + 1] = Divisor_degree_sort[i] + 1;
        else Divisor_degree_sort[i + 1] = Divisor_degree_sort[i];
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) Omega_degree <= 0;
    else if(in_valid) Omega_degree <= 1;
    else if(current_state == COUNT_DEG) begin
        Omega_degree <= 6 - Omega_degree_sort[6];
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) Sigma_degree <= 0;
    else if(in_valid) Sigma_degree <= 6;
    else if(current_state == COUNT_DEG) begin
        Sigma_degree <= 6 - Sigma_degree_sort[6];
    end
end

// ===============================================================
// Find Omega
// ===============================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 7 ; i ++ ) mult_Omega[i] <= 'hf;
    else if(current_state == SORT) for(i = 0 ; i < 7 ; i ++ ) mult_Omega[i] <= 'hf;
    else if(current_state == OMEGA_Q) begin
        for(i = 0 ; i < 7 ; i ++ ) begin
            if(i >= (Divisor_degree - counter_1) && i <= (6 - counter_1)) begin 
                if(Divisor_coeff[i + counter_1] != 15 && Quotient_coeff[6 - counter_1] != 15) begin
                    if(Divisor_coeff[i + counter_1] + Quotient_coeff[6 - counter_1] < 15) begin
                        mult_Omega[i] <= tables_int_to_idx[tables_idx_to_int[mult_Omega[i]]^tables_idx_to_int[Divisor_coeff[i + counter_1] + Quotient_coeff[6 - counter_1]]];
                    end
                    else if(Divisor_coeff[i + counter_1] + Quotient_coeff[6 - counter_1] == 15) begin
                        mult_Omega[i] <= tables_int_to_idx[tables_idx_to_int[mult_Omega[i]]^tables_idx_to_int[0]];
                        
                    end
                    else
                        mult_Omega[i] <= tables_int_to_idx[tables_idx_to_int[mult_Omega[i]]^tables_idx_to_int[Divisor_coeff[i + counter_1] + Quotient_coeff[6 - counter_1] - 15]];
                end
                else mult_Omega[i] <= tables_int_to_idx[tables_idx_to_int[mult_Omega[i]]^tables_idx_to_int[4'hf]];
            end
            else if(i < (Divisor_degree - counter_1)) mult_Omega[i] <= 4'hf;
            else mult_Omega[i] <= mult_Omega[i];
        end
    end
    else if(current_state == OMEGA_Divisor) begin
        for(i = 0 ; i < 7 ; i ++ ) begin
            if(i >= (Quotient_degree - counter_1) && i <= (6 - counter_1)) begin 
                if(Quotient_coeff[i + counter_1] != 15 && Divisor_coeff[6 - counter_1] != 15) begin
                    if(Quotient_coeff[i + counter_1] + Divisor_coeff[6 - counter_1] < 15) begin
                        mult_Omega[i] <= tables_int_to_idx[tables_idx_to_int[mult_Omega[i]]^tables_idx_to_int[Quotient_coeff[i + counter_1] + Divisor_coeff[6 - counter_1]]];
                    end
                    else if(Quotient_coeff[i + counter_1] + Divisor_coeff[6 - counter_1] == 15) begin
                        mult_Omega[i] <= tables_int_to_idx[tables_idx_to_int[mult_Omega[i]]^tables_idx_to_int[0]];
                        
                    end
                    else
                        mult_Omega[i] <= tables_int_to_idx[tables_idx_to_int[mult_Omega[i]]^tables_idx_to_int[Quotient_coeff[i + counter_1] + Divisor_coeff[6 - counter_1] - 15]];
                end
                else mult_Omega[i] <= tables_int_to_idx[tables_idx_to_int[mult_Omega[i]]^tables_idx_to_int[4'hf]];
            end
            else if(i < (Quotient_degree - counter_1)) mult_Omega[i] <= 4'hf;
            else mult_Omega[i] <= mult_Omega[i];
        end
    end
    else if(current_state == OMEGA) for(i = 0 ; i < 7 ; i ++ ) mult_Omega[6 - i] <= tables_int_to_idx[tables_idx_to_int[mult_Omega[6 - i]]^tables_idx_to_int[IN_Dividend[i*4+:4]]];
    else for(i = 0 ; i < 7 ; i ++ ) mult_Omega[i] <= mult_Omega[i];
end

// ===============================================================
// Find Sigma
// ===============================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 7 ; i ++ ) mult_Sigma[i] <= 'hf;
    else if(current_state == SORT) for(i = 0 ; i < 7 ; i ++ ) mult_Sigma[i] <= 'hf;
    else if(current_state == SIGMA_Q) begin
        for(i = 0 ; i < 7 ; i ++ ) begin
            if(i >= (Sigma_degree - counter_1) && i <= (6 - counter_1)) begin 
                if(Sigma_1[i + counter_1] != 15 && Quotient_coeff[6 - counter_1] != 15) begin
                    if(Sigma_1[i + counter_1] + Quotient_coeff[6 - counter_1] < 15) begin
                        mult_Sigma[i] <= tables_int_to_idx[tables_idx_to_int[mult_Sigma[i]]^tables_idx_to_int[Sigma_1[i + counter_1] + Quotient_coeff[6 - counter_1]]];
                    end
                    else if(Sigma_1[i + counter_1] + Quotient_coeff[6 - counter_1] == 15) begin
                        mult_Sigma[i] <= tables_int_to_idx[tables_idx_to_int[mult_Sigma[i]]^tables_idx_to_int[0]];
                        
                    end
                    else
                        mult_Sigma[i] <= tables_int_to_idx[tables_idx_to_int[mult_Sigma[i]]^tables_idx_to_int[Sigma_1[i + counter_1] + Quotient_coeff[6 - counter_1] - 15]];
                end
                else mult_Sigma[i] <= tables_int_to_idx[tables_idx_to_int[mult_Sigma[i]]^tables_idx_to_int[4'hf]];
            end
            else if(i < (Sigma_degree - counter_1)) mult_Sigma[i] <= 4'hf;
            else mult_Sigma[i] <= mult_Sigma[i];
        end
    end
    else if(current_state == SIGMA_S) begin
        for(i = 0 ; i < 7 ; i ++ ) begin
            if(i >= (Quotient_degree - counter_1) && i <= (6 - counter_1)) begin 
                if(Quotient_coeff[i + counter_1] != 15 && Sigma_1[6 - counter_1] != 15) begin
                    if(Quotient_coeff[i + counter_1] + Sigma_1[6 - counter_1] < 15) begin
                        mult_Sigma[i] <= tables_int_to_idx[tables_idx_to_int[mult_Sigma[i]]^tables_idx_to_int[Quotient_coeff[i + counter_1] + Sigma_1[6 - counter_1]]];
                    end
                    else if(Quotient_coeff[i + counter_1] + Sigma_1[6 - counter_1] == 15) begin
                        mult_Sigma[i] <= tables_int_to_idx[tables_idx_to_int[mult_Sigma[i]]^tables_idx_to_int[0]];
                        
                    end
                    else
                        mult_Sigma[i] <= tables_int_to_idx[tables_idx_to_int[mult_Sigma[i]]^tables_idx_to_int[Quotient_coeff[i + counter_1] + Sigma_1[6 - counter_1] - 15]];
                end
                else mult_Sigma[i] <= tables_int_to_idx[tables_idx_to_int[mult_Sigma[i]]^tables_idx_to_int[4'hf]];
            end
            else if(i < (Quotient_degree - counter_1)) mult_Sigma[i] <= 4'hf;
            else mult_Sigma[i] <= mult_Sigma[i];
        end
    end
    else if(current_state == SIGMA) for(i = 0 ; i < 7 ; i ++ ) mult_Sigma[i] <= tables_int_to_idx[tables_idx_to_int[mult_Sigma[i]]^tables_idx_to_int[Sigma_0[i]]];
    else for(i = 0 ; i < 7 ; i ++ ) mult_Sigma[i] <= mult_Sigma[i];
end

// ===============================================================
// Sigma
// ===============================================================
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 7 ; i ++ ) Sigma_0[i] <= 0;
    else if(current_state == INPUT) begin
        Sigma_0[6] <= 4'hf;
        for(i = 0 ; i < 6 ; i ++ ) Sigma_0[i] <= 'hf;
    end
    else if(current_state == SIGMA) for(i = 0 ; i < 7 ; i ++ ) Sigma_0[i] <= Sigma_1[i];
    else for(i = 0 ; i < 7 ; i ++ ) Sigma_0[i] <= Sigma_0[i];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 7 ; i ++ ) Sigma_1[i] <= 0;
    else if(current_state == INPUT) begin
        Sigma_1[6] <= 4'h0;
        for(i = 0 ; i < 6 ; i ++ ) Sigma_1[i] <= 'hf;
    end
    else if(current_state == SIGMA) for(i = 0 ; i < 7 ; i ++ ) Sigma_1[i] <= tables_int_to_idx[tables_idx_to_int[mult_Sigma[i]]^tables_idx_to_int[Sigma_0[i]]];
    else for(i = 0 ; i < 7 ; i ++ ) Sigma_1[i] <= Sigma_1[i];
end




// ===============================================================
// OUTPUT
// ===============================================================
always@(*) begin

    out_parameters[0] = mult_Sigma[6];

    if(mult_Sigma[5] == 15) out_parameters[1] = 15;
    else begin
        if(mult_Sigma[5] >= (1*counter_1)) out_parameters[1] = mult_Sigma[5] - (1*counter_1);
        else out_parameters[1] = 15 - (1*counter_1) + mult_Sigma[5];
    end


    if(mult_Sigma[4] == 15) out_parameters[2] = 15;
    else begin
        if(mult_Sigma[4] >= (2*counter_1)) out_parameters[2] = mult_Sigma[4] - (2*counter_1);
        else if(mult_Sigma[4] < (2*counter_1) && mult_Sigma[4] + 15 >= (2*counter_1)) out_parameters[2] = 15 - (2*counter_1) + mult_Sigma[4];
        else out_parameters[2] = 30 - (2*counter_1) + mult_Sigma[4];
    end
    

    if(mult_Sigma[3] == 15) out_parameters[3] = 15;
    else begin
        if(mult_Sigma[3] >= (3*counter_1)) out_parameters[3] = mult_Sigma[3] - (3*counter_1);
        else if(mult_Sigma[3] < (3*counter_1) && mult_Sigma[3] + 15 >= (3*counter_1)) out_parameters[3] = 15 - (3*counter_1) + mult_Sigma[3];
        else if(mult_Sigma[3] + 15 < (3*counter_1) && mult_Sigma[3] + 30 >= (3*counter_1)) out_parameters[3] = 30 - (3*counter_1) + mult_Sigma[3];
        else out_parameters[3] =  45 - (3*counter_1) + mult_Sigma[3];
    end


    // for(i = 0 ; i < 4 ; i ++) begin
    //     if(mult_Sigma[6 - i] == 15) out_parameters[i] = 15;
    //     else begin
    //         if(mult_Sigma[6 - i] >= (i*counter_1)) out_parameters[i] = mult_Sigma[6 - i] - (i*counter_1);
    //         else out_parameters[i] = 15 - (i*counter_1) + mult_Sigma[6 - i];
    //     end
    // end

    if(current_state == DIV_OR_NOT) out_total = 4'hf;
    else out_total = tables_idx_to_int[out_parameters[0]]^tables_idx_to_int[out_parameters[1]]^tables_idx_to_int[out_parameters[2]]^tables_idx_to_int[out_parameters[3]];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) for(i = 0 ; i < 3 ; i ++ ) out_data[i] <= 4'hf;
    else if(current_state == IDLE ) for(i = 0 ; i < 3 ; i ++ ) out_data[i] <= 4'hf;
    else if(current_state == COMPUTE_OUT) begin
        if(out_total == 0) out_data[counter_2] <= counter_1;;
    end
    else for(i = 0 ; i < 3 ; i ++ ) out_data[i] <= out_data[i];
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid <= 0;
    else if(current_state == OUTPUT) out_valid <= 1;
    else out_valid <= 0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) out_location <= 0;
    else if(current_state == OUTPUT) out_location <= out_data[counter_1];
    else out_location <= 0;
end


endmodule