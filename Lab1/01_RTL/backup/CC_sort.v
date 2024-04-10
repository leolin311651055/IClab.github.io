//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Spring
//   Lab01 Exercise		: Code Calculator
//   Author     		  : Jhan-Yi LIAO
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CC.v
//   Module Name : CC
//   Release version : V1.0 (Release Date: 2024-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


module CC(
  // Input signals
    opt,
    in_n0, in_n1, in_n2, in_n3, in_n4,  
  // Output signals
    out_n
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input[3:0] in_n0, in_n1, in_n2, in_n3, in_n4;
input [2:0] opt;
output reg [9:0] out_n;
integer i;        					
reg sort_done,test;
reg signed[3:0] inputdata0,inputdata1,inputdata2,inputdata3,inputdata4;
reg signed[3:0] temp;
//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment


//================================================================
//    DESIGN
//================================================================
// always(*) begin
//   if(opt[0] == 0 | opt[0] == 1) begin //?
//     inputdata4 = in_n00;
//     inputdata3 = in_n10;
//     inputdata2 = in_n20;
//     inputdata1 = in_n30;
//     inputdata0 = in_n40;
//   end
// end

always@(*) begin //sort
  if(1) begin //?
    inputdata0 = in_n0;
    inputdata1 = in_n1;
    inputdata2 = in_n2;
    inputdata3 = in_n3;
    inputdata4 = in_n4;
    test = 0;
  end
  if(opt[1] == 1) begin
    sort_done = 0;
    while (~sort_done) begin
      sort_done = 1;
      test = 1;
      if(inputdata0 > inputdata1) begin
        temp = inputdata0;
        inputdata0 = inputdata1;
        inputdata1 = temp;
        sort_done = 0;
      end 
      else if(inputdata1 > inputdata2) begin
        temp = inputdata1;
        inputdata1 = inputdata2;
        inputdata2 = temp;
        sort_done = 0;
      end
      else if(inputdata2 > inputdata3) begin
        temp = inputdata2;
        inputdata2 = inputdata3;
        inputdata3 = temp;
        sort_done = 0;
      end
      else if(inputdata3 > inputdata4) begin
        temp = inputdata3;
        inputdata3 = inputdata4;
        inputdata4 = temp;
        sort_done = 0;
      end 
    end
  end
  else if(opt[1] == 0) begin
    sort_done = 0;
    while (~sort_done) begin
      sort_done = 1;
      if(inputdata0 < inputdata1) begin
        temp = inputdata0;
        inputdata0 = inputdata1;
        inputdata1 = temp;
        sort_done = 0;
      end 
      else if(inputdata1 < inputdata2) begin
        temp = inputdata1;
        inputdata1 = inputdata2;
        inputdata2 = temp;
        sort_done = 0;
      end
      else if(inputdata2 < inputdata3) begin
        temp = inputdata2;
        inputdata2 = inputdata3;
        inputdata3 = temp;
        sort_done = 0;
      end
      else if(inputdata3 < inputdata4) begin
        temp = inputdata3;
        inputdata3 = inputdata4;
        inputdata4 = temp;
        sort_done = 0;
      end 
    end
  end
  else begin
  end
end


// --------------------------------------------------
// write your design here
// --------------------------------------------------

endmodule
