module MAZE(
    // input
    input clk,
    input rst_n,
	input in_valid,
	input [1:0] in,

    // output
    output reg out_valid,
    output reg [1:0] out
);
// --------------------------------------------------------------
// Reg & Wire
// --------------------------------------------------------------
reg [2:0] current_state, next_state ;
reg [2:0] graph [0:16][0:16] ;  //4 meant the path is already walked, but you can go again
reg [8:0] pointer_row, pointer_column ;

parameter IDLE = 0 ;
parameter INPUT = 1 ;
parameter NO_SWORD = 2 ;
parameter SWORD = 3 ;
parameter OUTDIRECT = 4 ;

parameter RIGHT = 0 ;
parameter DOWN  = 1 ;
parameter LEFT  = 2 ;
parameter UP    = 3 ;

integer i, j;


wire right_0, right_2, right_3, right_4, right_5, right_6 ;
assign  right_0 = (graph[pointer_row][pointer_column + 1] == 0 && pointer_column < 16 && out != LEFT) ;
assign  right_2 = (graph[pointer_row][pointer_column + 1] == 2 && pointer_column < 16 && out != LEFT) ;
assign  right_3 = (graph[pointer_row][pointer_column + 1] == 3 && pointer_column < 16 && out != LEFT) ;
assign  right_4 = (graph[pointer_row][pointer_column + 1] == 4 && pointer_column < 16 && out != LEFT) ;
assign  right_5 = (graph[pointer_row][pointer_column + 1] == 5 && pointer_column < 16 && out != LEFT) ;

wire down_0, down_2, down_3, down_4, down_5, down_6 ;
assign down_0 = (graph[pointer_row + 1][pointer_column] == 0 && pointer_row < 16 && out != UP) ;
assign down_2 = (graph[pointer_row + 1][pointer_column] == 2 && pointer_row < 16 && out != UP) ;
assign down_3 = (graph[pointer_row + 1][pointer_column] == 3 && pointer_row < 16 && out != UP) ;
assign down_4 = (graph[pointer_row + 1][pointer_column] == 4 && pointer_row < 16 && out != UP) ;
assign down_5 = (graph[pointer_row + 1][pointer_column] == 5 && pointer_row < 16 && out != UP) ;

wire up_0, up_2, up_3, up_4, up_5, up_6 ;
assign up_0 = (graph[pointer_row - 1][pointer_column] == 0 && pointer_row > 0 && out != DOWN) ;
assign up_2 = (graph[pointer_row - 1][pointer_column] == 2 && pointer_row > 0 && out != DOWN) ;
assign up_3 = (graph[pointer_row - 1][pointer_column] == 3 && pointer_row > 0 && out != DOWN) ;
assign up_4 = (graph[pointer_row - 1][pointer_column] == 4 && pointer_row > 0 && out != DOWN) ;
assign up_5 = (graph[pointer_row - 1][pointer_column] == 5 && pointer_row > 0 && out != DOWN) ;


wire left_0, left_2, left_3, left_4, left_5, left_6 ;
assign left_0 = (graph[pointer_row][pointer_column - 1] == 0 && pointer_column > 0 && out != RIGHT) ;
assign left_2 = (graph[pointer_row][pointer_column - 1] == 2 && pointer_column > 0 && out != RIGHT) ;
assign left_3 = (graph[pointer_row][pointer_column - 1] == 3 && pointer_column > 0 && out != RIGHT) ;
assign left_4 = (graph[pointer_row][pointer_column - 1] == 4 && pointer_column > 0 && out != RIGHT) ;
assign left_5 = (graph[pointer_row][pointer_column - 1] == 5 && pointer_column > 0 && out != RIGHT) ;

wire feedback_right_4, feedback_down_4, feedback_up_4, feedback_left_4 ;
assign feedback_right_4 = (graph[pointer_row][pointer_column + 1] == 4 && pointer_column  < 16) ;
assign feedback_down_4 = (graph[pointer_row + 1][pointer_column] == 4 && pointer_row  < 16) ;
assign feedback_up_4 = (graph[pointer_row - 1][pointer_column] == 4 && pointer_row > 0) ;
assign feedback_left_4 = (graph[pointer_row][pointer_column - 1] == 4 && pointer_column > 0) ;



// --------------------------------------------------------------
// Design
// --------------------------------------------------------------

always@(*) begin
	if(!rst_n) next_state = IDLE;
    else if(current_state == IDLE) begin
        if(in_valid) next_state = INPUT ;
        else next_state = current_state ;
    end
    else if(current_state == INPUT) begin
        if(pointer_row[4] && pointer_column[4]) next_state = NO_SWORD ;
        else next_state = current_state ;
    end
    else if(current_state == NO_SWORD) begin
        if(pointer_row[4] && pointer_column[4]) next_state = IDLE ;
        else if(pointer_column == 0 && pointer_row == 0 && graph[pointer_row][pointer_column] == 2) next_state = SWORD ;
        else if(right_2) next_state = SWORD ;
        else if(down_2) next_state = SWORD ;
        else if(left_2) next_state = SWORD ;
        else if(up_2) next_state = SWORD ;
        else next_state = current_state ;
    end
    else if(current_state == SWORD) begin
        if(pointer_row[4] && pointer_column[4]) next_state = IDLE ;
        else next_state = current_state ;
    end
	else next_state = current_state;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) pointer_row <= 0;
    else if(next_state == IDLE) pointer_row <= 0 ;
    else if(current_state == INPUT && pointer_column[4] && pointer_row[4]) begin
        pointer_row <= 0 ;
    end
    else if(current_state == INPUT && pointer_column[4]) begin
        pointer_row <= pointer_row + 1 ;
    end
    else if(current_state == INPUT) begin
        pointer_row <= pointer_row ;
    end
    else if(current_state == NO_SWORD) begin
        if(pointer_column[4] && pointer_row[4]) pointer_row <= 0 ;
        //keep go right
        //pass path
        else if(graph[pointer_row][pointer_column] == 2 && right_3) begin 
            pointer_row <= pointer_row ;
        end
        else if(graph[pointer_row][pointer_column] == 2 && down_3) begin 
            pointer_row <= pointer_row + 1 ;
        end
        else if(graph[pointer_row][pointer_column] == 2 && left_3) begin 
            pointer_row <= pointer_row ;
        end
        else if(graph[pointer_row][pointer_column] == 2 && up_3) begin 
            pointer_row <= pointer_row - 1 ;
        end
        else if(right_2) begin 
            pointer_row <= pointer_row ;
        end
        else if(down_2) begin 
            pointer_row <= pointer_row + 1 ;
        end
        else if(left_2) begin 
            pointer_row <= pointer_row ;
        end
        else if(up_2) begin 
            pointer_row <= pointer_row - 1 ;
        end
        else if(right_0) begin 
            pointer_row <= pointer_row ;
        end
        else if(down_0) begin 
            pointer_row <= pointer_row + 1 ;
        end
        else if(left_0) begin 
            pointer_row <= pointer_row ;
        end
        else if(up_0) begin 
            pointer_row <= pointer_row - 1 ;
        end
        //pass the path is already walked
        else if(feedback_right_4) begin 
            pointer_row <= pointer_row ;
        end
        else if(feedback_down_4) begin 
            pointer_row <= pointer_row + 1 ;
        end
        else if(feedback_left_4) begin 
            pointer_row <= pointer_row ;
        end
        else if(feedback_up_4) begin 
            pointer_row <= pointer_row - 1 ;
        end
    end
    else if(current_state == SWORD) begin
        if(pointer_column[4] && pointer_row[4]) pointer_row <= 0 ;
        //keep go right
        //pass path
        else if(right_0 || right_2 || right_3 || right_5) begin 
            pointer_row <= pointer_row ;
        end
        else if(down_0 || down_2 || down_3 || down_5) begin 
            pointer_row <= pointer_row + 1 ;
        end
        else if(left_0 || left_2 || left_3 || left_5) begin 
            pointer_row <= pointer_row ;
        end
        else if(up_0 || up_2 || up_3 || up_5) begin 
            pointer_row <= pointer_row - 1 ;
        end
        //pass the path is already walked
        else if(feedback_right_4) begin 
            pointer_row <= pointer_row ;
        end
        else if(feedback_down_4) begin 
            pointer_row <= pointer_row + 1 ;
        end
        else if(feedback_left_4) begin 
            pointer_row <= pointer_row ;
        end
        else if(feedback_up_4) begin 
            pointer_row <= pointer_row - 1 ;
        end
    end
    else pointer_row <= pointer_row ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) pointer_column <= 0;
    else if(next_state == IDLE) pointer_column <= 0 ;
    else if(current_state == INPUT && pointer_column[4]) begin
        pointer_column <= 0 ;
    end
    else if((in_valid && current_state == IDLE) || current_state == INPUT) begin
        pointer_column <= pointer_column + 1 ;
    end
    else if(current_state == NO_SWORD) begin
        if(pointer_column[4] && pointer_row[4]) pointer_column <= 0 ;
        else if(graph[pointer_row][pointer_column] == 2 && right_3) begin 
            pointer_column <= pointer_row + 1 ;
        end
        else if(graph[pointer_row][pointer_column] == 2 && down_3) begin 
            pointer_column <= pointer_row ;
        end
        else if(graph[pointer_row][pointer_column] == 2 && left_3) begin 
                pointer_column <= pointer_row - 1 ;
        end
        else if(graph[pointer_row][pointer_column] == 2 && up_3) begin 
            pointer_column <= pointer_row ;
        end
        else if(right_2) begin 
            pointer_column <= pointer_column + 1 ;
        end
        else if(down_2) begin 
            pointer_column <= pointer_column ;
        end
        else if(left_2) begin 
            pointer_column <= pointer_column - 1 ;
        end
        else if(up_2) begin 
            pointer_column <= pointer_column ;
        end
        else if(right_0) begin 
            pointer_column <= pointer_column + 1 ;
        end
        else if(down_0) begin 
            pointer_column <= pointer_column ;
        end
        else if(left_0) begin 
            pointer_column <= pointer_column - 1 ;
        end
        else if(up_0) begin 
            pointer_column <= pointer_column ;
        end
        //pass the path is already walked
        else if(feedback_right_4) begin 
            pointer_column <= pointer_column + 1 ;
        end
        else if(feedback_down_4) begin 
            pointer_column <= pointer_column ;
        end
        else if(feedback_left_4 ) begin 
            pointer_column <= pointer_column - 1 ;
        end
        else if(feedback_up_4) begin 
            pointer_column <= pointer_column ;
        end
    end
    else if(current_state == SWORD) begin
        if(pointer_column[4] && pointer_row[4]) pointer_column <= 0 ;
        //keep go right
        //pass path
        else if(right_0 || right_2 || right_3 || right_5) begin 
            pointer_column <= pointer_column + 1 ;
        end
        else if(down_0 || down_2 || down_3 || down_5) begin 
            pointer_column <= pointer_column ;
        end
        else if(left_0 || left_2 || left_3 || left_5) begin 
            pointer_column <= pointer_column - 1 ;
        end
        else if(up_0 || up_2 || up_3 || up_5) begin 
            pointer_column <= pointer_column ;
        end
        //pass the path is already walked
        else if(feedback_right_4) begin 
            pointer_column <= pointer_column + 1 ;
        end
        else if(feedback_down_4) begin 
            pointer_column <= pointer_column ;
        end
        else if(feedback_left_4 ) begin 
            pointer_column <= pointer_column - 1 ;
        end
        else if(feedback_up_4) begin 
            pointer_column <= pointer_column ;
        end
    end
    else pointer_column <= pointer_column ;
end

////////////////////////////graph////////////////////////////////
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0 ; i < 17 ; i ++) begin
           for(j = 0 ; j < 17 ; j ++) graph[i][j] <= 0 ;
        end
    end
    else if(current_state == INPUT || (current_state == IDLE && in_valid)) begin
        graph[pointer_row][pointer_column][1:0] <= in[1:0] ;
        graph[pointer_row][pointer_column][2:2] <= 0 ;
    end
    else if(current_state == NO_SWORD) begin
        //keep go right
        if(pointer_column[4] && pointer_row[4]) graph[pointer_row][pointer_column] <= 3'b100 ;
        //pass path
        else if(graph[pointer_row][pointer_column] == 2 && right_3) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        else if(graph[pointer_row][pointer_column] == 2 && down_3) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        else if(graph[pointer_row][pointer_column] == 2 && left_3) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        else if(graph[pointer_row][pointer_column] == 2 && up_3) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        else if(right_2) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        else if(down_2) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        else if(left_2) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        else if(up_2) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        else if(right_0) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        else if(down_0) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        else if(left_0) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        else if(up_0) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        //pass the path is already walked
        else if(feedback_right_4) begin 
            graph[pointer_row][pointer_column] <= 3'b101 ;
        end
        else if(feedback_down_4) begin 
            graph[pointer_row][pointer_column] <= 3'b101 ;
        end
        else if(feedback_left_4) begin 
            graph[pointer_row][pointer_column] <= 3'b101 ;
        end
        else if(feedback_up_4) begin 
            graph[pointer_row][pointer_column] <= 3'b101 ;
        end
    end
    else if(current_state == SWORD) begin
        //keep go right
        if(pointer_column[4] && pointer_row[4]) graph[pointer_row][pointer_column] <= 3'b100 ;
        //pass path
        else if(right_0 || right_2 || right_3 || right_5) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        else if(down_0 || down_2 || down_3 || down_5) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        else if(left_0 || left_2 || left_3 || left_5) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        else if(up_0 || up_2 || up_3 || up_5) begin 
            graph[pointer_row][pointer_column] <= 3'b100 ;
        end
        //pass the path is already walked
        else if(feedback_right_4) begin 
            graph[pointer_row][pointer_column] <= 3'b001 ;
        end
        else if(feedback_down_4) begin 
            graph[pointer_row][pointer_column] <= 3'b001 ;
        end
        else if(feedback_left_4) begin 
            graph[pointer_row][pointer_column] <= 3'b001 ;
        end
        else if(feedback_up_4) begin 
            graph[pointer_row][pointer_column] <= 3'b001 ;
        end
    end
    else graph <= graph ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) out_valid <= 0 ;
    else if(pointer_row[4] && pointer_column[4] && (current_state == SWORD || current_state == NO_SWORD)) out_valid <= 0;
    else if(current_state == NO_SWORD || current_state == SWORD) out_valid <= 1 ;
    else out_valid <= 0 ;
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) out <= 0 ; 
    else if(current_state == IDLE) out <= 0 ;
    else if(pointer_row[4] && pointer_column[4] && (current_state == SWORD || current_state == NO_SWORD)) out <= 0;
    else if(current_state == NO_SWORD) begin
        if(graph[pointer_row][pointer_column] == 2 && right_3) begin 
            out <= RIGHT ;
        end
        else if(graph[pointer_row][pointer_column] == 2 && down_3) begin 
            out <= DOWN ;
        end
        else if(graph[pointer_row][pointer_column] == 2 && left_3) begin 
            out <= LEFT ;
        end
        else if(graph[pointer_row][pointer_column] == 2 && up_3) begin 
            out <= UP ;
        end
        else if(right_2) begin 
            out <= RIGHT ;
        end
        else if(down_2) begin 
            out <= DOWN ;
        end
        else if(left_2) begin 
            out <= LEFT ;
        end
        else if(up_2) begin 
            out <= UP ;
        end
        else if(right_0) begin 
            out <= RIGHT ;
        end
        else if(down_0) begin 
            out <= DOWN ;
        end
        else if(left_0) begin 
            out <= LEFT ;
        end
        else if(up_0) begin 
            out <= UP ;
        end
        //pass the path is already walked
        else if(feedback_right_4) begin 
            out <= RIGHT ;
        end
        else if(feedback_down_4) begin 
            out <= DOWN ;
        end
        else if(feedback_left_4 ) begin 
            out <= LEFT ;
        end
        else if(feedback_up_4) begin 
            out <= UP ;
        end
    end
    else if(current_state == SWORD) begin
        if(right_0 || right_2 || right_3 || right_5) begin 
            out <= RIGHT ;
        end
        else if(down_0 || down_2 || down_3 || down_5) begin 
            out <= DOWN ;
        end
        else if(left_0 || left_2 || left_3 || left_5) begin 
            out <= LEFT ;
        end
        else if(up_0 || up_2 || up_3 || up_5) begin 
            out <= UP ;
        end
        //pass the path is already walked
        else if(feedback_right_4) begin 
            out <= RIGHT ;
        end
        else if(feedback_down_4) begin 
            out <= DOWN ;
        end
        else if(feedback_left_4 ) begin 
            out <= LEFT ;
        end
        else if(feedback_up_4) begin 
            out <= UP ;
        end
    end
    else out <= 0 ;
end

endmodule