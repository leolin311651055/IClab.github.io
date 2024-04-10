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
reg signed[9:0] inputdata0,inputdata1,inputdata2,inputdata3,inputdata4;
reg signed[9:0] input0,input1,input2,input3,input4;
reg signed[9:0] temp;
reg signed[9:0] avg,out2_temp,out1,out2;
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
always@(*) begin //temp
  if(1) begin
    input0 = in_n0;
    input1 = in_n1;
    input2 = in_n2;
    input3 = in_n3;
    input4 = in_n4;
    for(i=0;i<4;i++) begin
      if(input0 > input1) begin
        temp = input0;
        input0 = input1;
        input1 = temp;
      end 
      else begin
        temp = temp;
        input0 = input0;
        input1 = input1;
      end
      if(input1 > input2) begin
        temp = input1;
        input1 = input2;
        input2 = temp;
      end
      else begin
        temp = temp;
        input1 = input1;
        input2 = input2;
      end
      if(input2 > input3) begin
        temp = input2;
        input2 = input3;
        input3 = temp;
      end
      else begin
        temp = temp;
        input2 = input2;
        input3 = input3;
      end
      if(input3 > input4) begin
        temp = input3;
        input3 = input4;
        input4 = temp;
      end 
      else begin
        temp = temp;
        input3 = input3;
        input4 = input4;
      end
    end
  end
  else begin
  end

  if(opt[1] == 0) begin
    inputdata0 = input0;
    inputdata1 = input1;
    inputdata2 = input2;
    inputdata3 = input3;
    inputdata4 = input4;
  end
  else if(opt[1] == 1) begin
    inputdata0 = input4;
    inputdata1 = input3;
    inputdata2 = input2;
    inputdata3 = input1;
    inputdata4 = input0;
  end
  else begin
    inputdata0 = input0;
    inputdata1 = input1;
    inputdata2 = input2;
    inputdata3 = input3;
    inputdata4 = input4;
  end
// end

// always@(*) begin
  if(opt[0] == 1) begin
    temp = (inputdata0 + inputdata4)/2;
    inputdata0 = inputdata0 - temp;
    inputdata1 = inputdata1 - temp;
    inputdata2 = inputdata2 - temp;
    inputdata3 = inputdata3 - temp;
    inputdata4 = inputdata4 - temp;
  end
  else if(opt[0] == 0) begin
    inputdata0 = inputdata0;
    inputdata1 = inputdata1;
    inputdata2 = inputdata2;
    inputdata3 = inputdata3;
    inputdata4 = inputdata4;
  end
  else begin
    inputdata0 = inputdata0;
    inputdata1 = inputdata1;
    inputdata2 = inputdata2;
    inputdata3 = inputdata3;
    inputdata4 = inputdata4;
  end
end

Division Division1(.in1(inputdata0+inputdata1+inputdata2+inputdata3+inputdata4),.in2(10'd5),.out(avg));
Adder Adder1(.in1(inputdata0),.in2(inputdata1*inputdata2),.in3(avg*inputdata3),.out(out2_temp));
Adder Adder2(.in1((inputdata3<<<1)),.in2(inputdata3),.in3(~(inputdata0*inputdata4)+10'd1),.out(out1));
Division Division2(.in1(out2_temp),.in2(10'd3),.out(out2));
always@(*) begin
  if(opt[2] == 1) begin
    out_n = out1;
    if(out_n[9] == 1) begin
      out_n = ~(out_n)+1;
    end
    else if(out_n[9] == 0)begin
      out_n = out_n;
    end
  end
  else if(opt[2] == 0) begin
    out_n = out2;
  end
  else begin
    out_n = out_n;
  end

end


// --------------------------------------------------
// write your design here
// --------------------------------------------------

endmodule

module Adder(in1,in2,in3,out);
  input wire  signed[9:0]in1,in2,in3;
  output wire signed [9:0]out;
  assign out = in1 + in2 + in3;
endmodule


// module Multiplication(in1,in2,out);
//   input wire  signed[9:0]in1,in2;
//   output wire signed [9:0]out;
//   assign out = in1 * in2;
// endmodule

module Division(in1,in2,out);
  input wire  signed[9:0]in1,in2;
  output wire signed [9:0]out;
  assign out = in1 / in2;
endmodule


