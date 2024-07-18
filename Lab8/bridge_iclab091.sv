module bridge(input clk, INF.bridge_inf inf);

//================================================================
// Logic 
//================================================================
logic [63:0] data_reg;
logic [16:0] addr_reg;



//================================================================
// data and address 
//================================================================
always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) data_reg <= 0 ;
	else if (inf.R_VALID) data_reg <= inf.R_DATA ;
	else if (inf.C_in_valid) data_reg <= inf.C_data_w ;
	else data_reg <= data_reg ;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin 
	if (!inf.rst_n) addr_reg <= 0 ;
	else if (inf.C_in_valid) addr_reg <= 65536 + ({9'd0, (inf.C_addr)} << 3) ;
	else addr_reg <= addr_reg ;
end

//================================================================
// AXI 
//================================================================

//(1)Read Address 
always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) inf.AR_VALID <= 0 ;
	else if (inf.C_in_valid & inf.C_r_wb) inf.AR_VALID <= 1 ;
	else if (inf.AR_VALID) inf.AR_VALID <= 0 ;
    else inf.AR_VALID <= inf.AR_VALID ;
end

always_comb begin : AR_ADDR
	inf.AR_ADDR = addr_reg ;
end

//(2)Read Data
always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) inf.R_READY <= 0 ;
	else if (inf.AR_VALID) inf.R_READY <= 1 ;
	else if (inf.R_VALID) inf.R_READY <= 0 ;
	else inf.R_READY <= inf.R_READY ;
end


//(3)Write Address 
always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) inf.AW_VALID <= 0 ;
	else if (inf.C_in_valid & !inf.C_r_wb) inf.AW_VALID <= 1 ;
	else if (inf.AW_READY) inf.AW_VALID <= 0 ;
    else inf.AW_VALID <= inf.AW_VALID ;
end

always_comb begin : AW_ADDR
	inf.AW_ADDR = addr_reg ;
end

//(4)Write Data
always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) inf.W_VALID <= 0 ;
	else if (inf.AW_READY) inf.W_VALID <= 1 ;
	else if (inf.W_READY) inf.W_VALID <= 0 ;
	else inf.W_VALID <= inf.W_VALID ;
end

always_comb begin : W_DATA
	inf.W_DATA = data_reg ;
end


always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) inf.B_READY <= 0 ;
	else if (inf.W_READY) inf.B_READY <= 1 ;
	else if (inf.B_VALID) inf.B_READY <= 0 ;
	else inf.B_READY <= inf.B_READY ;
end

//================================================================
// Output
//================================================================
logic waiting_data;
always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin 
		waiting_data <= 0 ;
	end
	else if (inf.R_VALID & !inf.C_out_valid) waiting_data <= 1 ;
	else if (inf.B_VALID & !inf.C_out_valid) waiting_data <= 1 ;
	else if (inf.C_out_valid) waiting_data <= 0 ;
	else waiting_data <= waiting_data ;
end


always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin 
		inf.C_out_valid <= 0 ;
	end
	else if (waiting_data) inf.C_out_valid <= 1 ;
	else if (!waiting_data) inf.C_out_valid <= 0 ;
	else inf.C_out_valid <= inf.C_out_valid ;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin 
		inf.C_data_r <= 0 ;
	end
	else if (waiting_data) inf.C_data_r <= data_reg ;
	else if (!waiting_data) inf.C_data_r <= 0 ;
	else inf.C_data_r <= inf.C_data_r ;
end

endmodule