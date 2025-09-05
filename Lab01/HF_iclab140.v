module HF(
    // Input signals
    input [24:0] symbol_freq,
    // Output signals
    output reg [19:0] out_encoded
);

wire [4:0] indata [4:0][1:0];
wire [4:0] sort1 [4:0][1:0];
wire [4:0] sort2 [4:0][1:0];
wire [4:0] sort3 [4:0][1:0];
wire [4:0] sort4 [4:0][1:0];
wire [4:0] sort5 [4:0][1:0];
wire [4:0] sort6 [4:0][1:0];

reg [3:0] out[4:0][1:0];

//================================================================
//    Wire & Registers 
//================================================================
assign indata[0][0] = symbol_freq[24:20];  // Assign the upper 5 bits to indata[0]
assign indata[1][0] = symbol_freq[19:15];  // Assign the next 5 bits to indata[1]
assign indata[2][0] = symbol_freq[14:10];  // Assign the next 5 bits to indata[2]
assign indata[3][0] = symbol_freq[9:5];  // Assign the next 5 bits to indata[3]
assign indata[4][0] = symbol_freq[4:0];  // Assign the lower 5 bits to indata[4]

assign indata[0][1] = 5'b00000;  // Assign the lower 5 bits to indata[0]
assign indata[1][1] = 5'b00001;  // Assign the next 5 bits to indata[1]
assign indata[2][1] = 5'b00010;  // Assign the next 5 bits to indata[2]
assign indata[3][1] = 5'b00011;  // Assign the next 5 bits to indata[3]
assign indata[4][1] = 5'b00100;  // Assign the upper 5 bits to indata[4]

///////////////////////////////sort freq//////////////////////////////////////////
assign sort1[0] = (indata[0][0] > indata[1][0]) ? indata[1] : indata[0];
assign sort1[1] = (indata[0][0] > indata[1][0]) ? indata[0] : indata[1];
assign sort1[2] = (indata[2][0] > indata[3][0]) ? indata[3] : indata[2];
assign sort1[3] = (indata[2][0] > indata[3][0]) ? indata[2] : indata[3];
assign sort1[4] = indata[4];  // unchanged


assign sort2[1] = (sort1[1][0] > sort1[2][0]) ? sort1[2] : sort1[1];
assign sort2[2] = (sort1[1][0] > sort1[2][0]) ? sort1[1] : sort1[2];
assign sort2[3] = (sort1[3][0] > sort1[4][0]) ? sort1[4] : sort1[3];
assign sort2[4] = (sort1[3][0] > sort1[4][0]) ? sort1[3] : sort1[4];
assign sort2[0] = sort1[0];  // unchanged

assign sort3[0] = (sort2[0][0] > sort2[1][0]) ? sort2[1] : sort2[0];
assign sort3[1] = (sort2[0][0] > sort2[1][0]) ? sort2[0] : sort2[1];
assign sort3[2] = (sort2[2][0] > sort2[3][0]) ? sort2[3] : sort2[2];
assign sort3[3] = (sort2[2][0] > sort2[3][0]) ? sort2[2] : sort2[3];
assign sort3[4] = sort2[4];  // unchanged

assign sort4[1] = (sort3[1][0] > sort3[2][0]) ? sort3[2] : sort3[1];
assign sort4[2] = (sort3[1][0] > sort3[2][0]) ? sort3[1] : sort3[2];
assign sort4[3] = (sort3[3][0] > sort3[4][0]) ? sort3[4] : sort3[3];
assign sort4[4] = (sort3[3][0] > sort3[4][0]) ? sort3[3] : sort3[4];
assign sort4[0] = sort3[0];  // unchanged

assign sort5[0] = (sort4[0][0] > sort4[1][0]) ? sort4[1] : sort4[0];
assign sort5[1] = (sort4[0][0] > sort4[1][0]) ? sort4[0] : sort4[1];
assign sort5[2] = (sort4[2][0] > sort4[3][0]) ? sort4[3] : sort4[2];
assign sort5[3] = (sort4[2][0] > sort4[3][0]) ? sort4[2] : sort4[3];
assign sort5[4] = sort4[4];  // unchanged

assign sort6[1] = (sort5[1][0] > sort5[2][0]) ? sort5[2] : sort5[1];
assign sort6[2] = (sort5[1][0] > sort5[2][0]) ? sort5[1] : sort5[2];
assign sort6[3] = (sort5[3][0] > sort5[4][0]) ? sort5[4] : sort5[3];
assign sort6[4] = (sort5[3][0] > sort5[4][0]) ? sort5[3] : sort5[4];
assign sort6[0] = sort5[0];  // unchanged


wire [8:0]compute1, compute2, compute3, compute4, compute5, compute6, compute7, compute8, compute9, compute10;
assign compute1 = sort6[0][0] + sort6[1][0];
assign compute2 = sort6[3][0];
assign compute3 = sort6[2][0] + sort6[3][0];
assign compute4 = sort6[4][0];
assign compute5 = sort6[2][0] + sort6[3][0] + sort6[4][0];
assign compute6 = sort6[0][0] + sort6[1][0] + sort6[2][0];
assign compute7 = sort6[3][0] + sort6[4][0];
assign compute8 = sort6[2][0];
assign compute9 = sort6[0][0] + sort6[1][0] + sort6[2][0] + sort6[3][0];
assign compute10 = sort6[0][0] + sort6[1][0] + sort6[4][0];

always@(*) begin
    out[0][1][3:0] = sort6[0][1][3:0];
    out[1][1][3:0] = sort6[1][1][3:0];
    out[2][1][3:0] = sort6[2][1][3:0];
    out[3][1][3:0] = sort6[3][1][3:0];
    out[4][1][3:0] = sort6[4][1][3:0];
end


always@(*) begin
    if(compute1 > compute2) begin 
        if((compute1 <= compute3) && (compute4 < compute3)) begin
            //5
            if(compute1 > compute4) begin
                if(compute10 > compute3) begin
                    out[0][0] = 4'b0110; 
                    out[1][0] = 4'b0111;  
                    out[2][0] = 4'b0000; 
                    out[3][0] = 4'b0001; 
                    out[4][0] = 4'b0010;
                end
                else begin
                    out[0][0] = 4'b0010; 
                    out[1][0] = 4'b0011; 
                    out[2][0] = 4'b0010; 
                    out[3][0] = 4'b0011; 
                    out[4][0] = 4'b0000;
                end
            end
            else begin
                if(compute10 > compute3) begin
                    out[0][0] = 4'b0100; 
                    out[1][0] = 4'b0101; 
                    out[2][0] = 4'b0000; 
                    out[3][0] = 4'b0001; 
                    out[4][0] = 4'b0011; 
                end
                else begin
                    out[0][0] = 4'b0000; 
                    out[1][0] = 4'b0001; 
                    out[2][0] = 4'b0010; 
                    out[3][0] = 4'b0011; 
                    out[4][0] = 4'b0001; 
                end
            end
        end
        else if((compute1 > compute4))begin 
            //1
            if(compute3 <= compute4) begin 
                if(compute5 > compute1) begin
                    out[0][0] = 4'b0000; 
                    out[1][0] = 4'b0001; 
                    out[2][0] = 4'b0100; 
                    out[3][0] = 4'b0101; 
                    out[4][0] = 4'b0011; 
                end
                else begin
                    out[0][0] = 4'b0010; 
                    out[1][0] = 4'b0011; 
                    out[2][0] = 4'b0000; 
                    out[3][0] = 4'b0001; 
                    out[4][0] = 4'b0001; 
                end
            end
            else begin
                if(compute5 > compute1) begin//this
                    out[0][0] = 4'b0000; 
                    out[1][0] = 4'b0001; 
                    out[2][0] = 4'b0110; 
                    out[3][0] = 4'b0111; 
                    out[4][0] = 4'b0010; 
                end
                else begin
                    out[0][0] = 4'b0010; 
                    out[1][0] = 4'b0011; 
                    out[2][0] = 4'b0010; 
                    out[3][0] = 4'b0011; 
                    out[4][0] = 4'b0000; 
                end
            end
        end
        else begin
                //2
                if(compute1 > compute3) begin
                    if(compute9 > compute4) begin
                        out[0][0] = 4'b0110; 
                        out[1][0] = 4'b0111; 
                        out[2][0] = 4'b0100; 
                        out[3][0] = 4'b0101; 
                        out[4][0] = 4'b0000; 
                    end
                    else begin
                        out[0][0] = 4'b0010; 
                        out[1][0] = 4'b0011; 
                        out[2][0] = 4'b0000; 
                        out[3][0] = 4'b0001; 
                        out[4][0] = 4'b0001; 
                    end
                end
                else begin
                    if(compute9 > compute4) begin
                        out[0][0] = 4'b0100;
                        out[1][0] = 4'b0101;
                        out[2][0] = 4'b0110;
                        out[3][0] = 4'b0111;
                        out[4][0] = 4'b0000;
                    end
                    else begin
                        out[0][0] = 4'b0000; 
                        out[1][0] = 4'b0001; 
                        out[2][0] = 4'b0010; 
                        out[3][0] = 4'b0011; 
                        out[4][0] = 4'b0001; 
                    end
                end
            end
    end
    else begin
        if(compute6 > compute4) begin 
            //3
            if(compute1 > compute8) begin 
                if(compute6 > compute7) begin 
                    out[0][0] = 4'b0110; 
                    out[1][0] = 4'b0111; 
                    out[2][0] = 4'b0010; 
                    out[3][0] = 4'b0000; 
                    out[4][0] = 4'b0001; 
                end
                else begin
                    out[0][0] = 4'b0010; 
                    out[1][0] = 4'b0011; 
                    out[2][0] = 4'b0000; 
                    out[3][0] = 4'b0010; 
                    out[4][0] = 4'b0011; 
                end
            end
            else begin
                if(compute6 > compute7) begin 
                    out[0][0] = 4'b0100; 
                    out[1][0] = 4'b0101; 
                    out[2][0] = 4'b0011; 
                    out[3][0] = 4'b0000; 
                    out[4][0] = 4'b0001; 
                end
                else begin
                    out[0][0] = 4'b0000; 
                    out[1][0] = 4'b0001; 
                    out[2][0] = 4'b0001; 
                    out[3][0] = 4'b0010; 
                    out[4][0] = 4'b0011; 
                end
            end
        end
        else begin
            //4
            if(compute1 > compute8) begin
                if(compute6 > compute2) begin
                    if(compute9 > compute4) begin
                        out[0][0] = 4'b1110; 
                        out[1][0] = 4'b1111; 
                        out[2][0] = 4'b0110; 
                        out[3][0] = 4'b0010; 
                        out[4][0] = 4'b0000; 
                    end
                    else begin
                        out[0][0] = 4'b0110;
                        out[1][0] = 4'b0111;
                        out[2][0] = 4'b0010;
                        out[3][0] = 4'b0000;
                        out[4][0] = 4'b0001;
                    end
                end
                else begin
                    if(compute9 > compute4) begin
                        out[0][0] = 4'b1010; 
                        out[1][0] = 4'b1011; 
                        out[2][0] = 4'b0100; 
                        out[3][0] = 4'b0011; 
                        out[4][0] = 4'b0000; 
                    end
                    else begin
                        out[0][0] = 4'b0010; 
                        out[1][0] = 4'b0011; 
                        out[2][0] = 4'b0000; 
                        out[3][0] = 4'b0001; 
                        out[4][0] = 4'b0001; 
                    end
                end
            end
            else begin
                if(compute6 > compute2) begin
                    if(compute9 > compute4) begin
                        out[0][0] = 4'b1100; 
                        out[1][0] = 4'b1101; 
                        out[2][0] = 4'b0111; 
                        out[3][0] = 4'b0010; 
                        out[4][0] = 4'b0000; 
                    end
                    else begin
                        out[0][0] = 4'b0100;
                        out[1][0] = 4'b0101;
                        out[2][0] = 4'b0011;
                        out[3][0] = 4'b0000;
                        out[4][0] = 4'b0001;
                    end
                end
                else begin
                    if(compute9 > compute4) begin
                        out[0][0] = 4'b1000; 
                        out[1][0] = 4'b1001; 
                        out[2][0] = 4'b0101; 
                        out[3][0] = 4'b0011; 
                        out[4][0] = 4'b0000; 
                    end
                    else begin
                        out[0][0] = 4'b0000; 
                        out[1][0] = 4'b0001; 
                        out[2][0] = 4'b0001; 
                        out[3][0] = 4'b0001; 
                        out[4][0] = 4'b0001; 
                    end
                end
            end
        end
    end
end

always@(*) begin
    if(out[0][1] == 4'b0000) out_encoded[19:16] = out[0][0];
    else if(out[1][1] == 4'b0000) out_encoded[19:16] = out[1][0];
    else if(out[2][1] == 4'b0000) out_encoded[19:16] = out[2][0];
    else if(out[3][1] == 4'b0000) out_encoded[19:16] = out[3][0];
    else out_encoded[19:16] = out[4][0];

    if(out[0][1] == 4'b0001) out_encoded[15:12] = out[0][0];
    else if(out[1][1] == 4'b0001) out_encoded[15:12] = out[1][0];
    else if(out[2][1] == 4'b0001) out_encoded[15:12] = out[2][0];
    else if(out[3][1] == 4'b0001) out_encoded[15:12] = out[3][0];
    else out_encoded[15:12] = out[4][0];

    if(out[0][1] == 4'b0010) out_encoded[11:8] = out[0][0];
    else if(out[1][1] == 4'b0010) out_encoded[11:8] = out[1][0];
    else if(out[2][1] == 4'b0010) out_encoded[11:8] = out[2][0];
    else if(out[3][1] == 4'b0010) out_encoded[11:8] = out[3][0];
    else out_encoded[11:8] = out[4][0];

    if(out[0][1] == 4'b0011) out_encoded[7:4] = out[0][0];
    else if(out[1][1] == 4'b0011) out_encoded[7:4] = out[1][0];
    else if(out[2][1] == 4'b0011) out_encoded[7:4] = out[2][0];
    else if(out[3][1] == 4'b0011) out_encoded[7:4] = out[3][0];
    else out_encoded[7:4] = out[4][0];

    if(out[0][1] == 4'b0100) out_encoded[3:0] = out[0][0];
    else if(out[1][1] == 4'b0100) out_encoded[3:0] = out[1][0];
    else if(out[2][1] == 4'b0100) out_encoded[3:0] = out[2][0];
    else if(out[3][1] == 4'b0100) out_encoded[3:0] = out[3][0];
    else out_encoded[3:0] = out[4][0];
end

// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment

//================================================================
//    DESIGN
//================================================================


endmodule