module Handshake_syn #(parameter WIDTH=32) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;

input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;



// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;
// -------------------------------------
reg [WIDTH-1:0] s_data;

assign clk1_handshake_flag3 = dack;

// two NDFF_syn sclk to dclk & dclk to sclk
NDFF_syn ndff0(.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn ndff1(.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));

//------------ DATA ----------------------
always @(posedge sclk or negedge rst_n) 
begin
  if (!rst_n) s_data <= 0;
  else if (sready && !sreq) s_data <= din; // only load data if not already in transaction
  else s_data <= s_data;
end

always @(posedge dclk or negedge rst_n) 
begin
  if (!rst_n)              dout <= 0;
  else if (!dbusy && dreq) dout <= s_data; //sent data to clk2 domain
  else                     dout <= 0;
end
always @(posedge dclk or negedge rst_n) 
begin
  if (!rst_n)              dvalid <= 0;
  else if (!dbusy && dreq) dvalid <= 1; //sent data to clk2 domain
  else                     dvalid <= 0;
end
//-------Src and Dest control-------------
always @(posedge sclk or negedge rst_n) 
begin
  if(!rst_n)       sreq <= 0; 
  else if (sack)   sreq <= 0;
  else if (sready) sreq <= 1; //sready is out_valid of clk domain 1
  else             sreq <= sreq;
end

reg dack_sync_1, dack_sync_2;

always @(posedge dclk or negedge rst_n) begin
  if (!rst_n)      dack_sync_1 <= 0;
  else if (dreq)   dack_sync_1 <= 1;
  else             dack_sync_1 <= 0;
end

always @(posedge dclk or negedge rst_n) begin
  if (!rst_n) begin
    dack_sync_2 <= 0;
  end else begin
    dack_sync_2 <= dack_sync_1;
  end
end


always @(posedge dclk or negedge rst_n) 
begin
  if (!rst_n)      dack <= 0;
  else dack <= dack_sync_2;
  // else if (dreq)   dack <= 1;
  // else             dack <= 0;
end
//------- SIDLE -------------
assign sidle = (sreq || sack)? 0:1 ;

//------- FLAG --------------

endmodule