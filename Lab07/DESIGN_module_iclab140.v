module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
    seed_in,
    out_idle,
    out_valid,
    seed_out,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4
);

input clk;
input rst_n;
input in_valid;
input [31:0] seed_in;
input out_idle;
output reg out_valid;
output reg [31:0] seed_out;
reg [31:0] seed_reg;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;

parameter IDLE          = 0;
parameter WAIT_OUT_IDLE = 1;

reg [1:0] current_state;
reg [1:0] next_state;

always@(*) begin
    if(!rst_n) next_state = IDLE;
    else if(current_state == IDLE) begin
        if(in_valid) next_state = WAIT_OUT_IDLE;
        else next_state = current_state;
    end
    else if(current_state == WAIT_OUT_IDLE) begin
        if(out_idle) next_state = IDLE;
        else next_state = current_state;
    end
    else next_state = current_state;
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end


// always@(posedge clk or negedge rst_n) begin
//     if(!rst_n) seed_out <= 0;
//     else if(in_valid) seed_out <= seed_in;
//     else seed_out <= seed_out;
// end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) seed_reg <= 0;
    else if(in_valid) seed_reg <= seed_in;
    else seed_reg <= seed_reg;
end

always@(*) begin
    if(!rst_n) seed_out = 0;
    else if(current_state == WAIT_OUT_IDLE && out_idle) seed_out = seed_reg;
    else seed_out = 0;
end


always@(*) begin
    if(!rst_n) out_valid = 0;
    else if(current_state == WAIT_OUT_IDLE && out_idle) out_valid = 1;
    else out_valid = 0;
end

endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    seed,
    out_valid,
    rand_num,
    busy,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [31:0] seed;
output out_valid;
output [31:0] rand_num;
output busy;

reg out_valid;
reg busy;

// You can change the input / output of the custom flag ports
input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

input clk2_fifo_flag1;
input clk2_fifo_flag2;
input clk2_fifo_flag3;
input clk2_fifo_flag4;


///////////////////////////FSM///////////////////////////////
parameter IDLE    = 0;
parameter COMPUTE = 1;

reg  [5:0] current_state;
reg  [5:0] next_state;

always@(*) begin
    if(!rst_n) next_state = IDLE;
    else if(current_state == IDLE) begin
        if(in_valid) next_state = COMPUTE;
        else next_state = current_state;
    end
    else if(current_state == COMPUTE) begin
        if(clk2_fifo_flag3) next_state = IDLE;
        else next_state = current_state;
    end
    else next_state = current_state;
end
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end
///////////////////////////FSM///////////////////////////////

reg  [31:0] x_seed ;
wire [31:0] x_seed_1, x_seed_2 ;

assign x_seed_1 = x_seed  ^ (x_seed << 13) ; 
assign x_seed_2 = x_seed_1 ^ (x_seed_1 >> 17) ;
assign rand_num    = x_seed_2 ^ (x_seed_2 << 5) ;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) x_seed <= 0;
    else if(current_state == IDLE && !in_valid) x_seed <= 0;
    else if(current_state == IDLE && in_valid) x_seed <= seed;
    else if(current_state == COMPUTE && ~fifo_full) x_seed <= rand_num;
    else x_seed <= x_seed;
end

always@(*) begin
    if(!rst_n) busy = 0;
    else if(current_state == COMPUTE && ~fifo_full) busy = 1;
    else if(current_state == COMPUTE && fifo_full) busy = 0;
    else busy = 0;
end

always@(*) begin
    if(!rst_n) out_valid = 0;
    else if(current_state == COMPUTE && ~fifo_full) out_valid = 1;
    else if(current_state == COMPUTE && fifo_full) out_valid = 0;
    else out_valid = 0;
end

endmodule


module CLK_3_MODULE (
    clk,
    rst_n,
    fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    rand_num,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input clk;
input rst_n;
input fifo_empty;
input [31:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [31:0] rand_num;

// You can change the input / output of the custom flag ports
input fifo_clk3_flag1;
input fifo_clk3_flag2;
input fifo_clk3_flag3;
input fifo_clk3_flag4;

wire fifo_rinc;

assign fifo_rinc = (fifo_empty) ? 0 : 1 ;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid <= 0;
    else if(fifo_clk3_flag4) out_valid <= 1;
    else out_valid <= 0;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) rand_num <= 0;
    else if(fifo_clk3_flag4) rand_num <= fifo_rdata;
    else rand_num <= 0;
end


endmodule