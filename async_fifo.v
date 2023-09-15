`timescale 1ns/1ps
`include "define.v"

module async_fifo_template #(
	parameter
	DW = 8,
	AW = 3,
	ALMOST_TH = 4
)(
	//Write Domain
	input		wire				wr_clk,
	input		wire				wr_rstn,
	input		wire				wr_sw_rst,

	input 	wire	[DW-1:0]	i_wr_data,
	input 	wire				i_wr_valid,
	output 	wire				o_wr_fifo_full,

	//Read Domain
	input		wire				rd_clk,
	input		wire				rd_rstn,
	input		wire				rd_sw_rst,

	input		wire				i_rd_en,

	output	wire	[DW-1:0] o_rd_data,
	output	wire				o_rd_valid,
	output	wire				o_rd_fifo_empty
);
// Wrie Domain Variable
wire 				w_wr_en;
wire [AW-1:0]	w_wr_addr;
wire [AW:0]		w_wr_gray_ptr;
wire 				w_fifo_full;
wire				w_fifo_almost_full;


// Read Domain Variable
wire [AW-1:0]	w_rd_addr;
wire [AW:0]		w_rd_gray_ptr;
wire 				w_fifo_empty;
wire 				w_fifo_almost_empty;
wire				w_rd_en_q;
wire				w_rd_en_valid;


// Common Variable			[0] => use to Write domain  /   [1] => use to Read domain
reg 	[AW:0]	r_gray_ptr_q[0:1];
reg 	[AW:0]	r_gray_ptr_q2[0:1];
reg				r_rst_q[0:1];
reg				r_rst_q2[0:1];
wire	[AW:0]	w_gray2bin_ptr[0:1];

// FIFO Variable
reg	[DW-1:0]	fifo_data[0:(2**(AW))-1];

integer i;

// //////////////////////////////////////////////
// 				Write Domain Function
// //////////////////////////////////////////////

// Write CTRL Module
assign w_wr_en = i_wr_valid & (~w_fifo_full);

reg [AW:0]	r_wr_ptr, r_wr_ptr_next;

always @(*) begin
	r_wr_ptr_next = r_wr_ptr;
	if(w_wr_en) begin
		if(r_wr_ptr == ((2**(AW+1))-1))
			r_wr_ptr_next = AW*{1'b0};
		else
			r_wr_ptr_next = r_wr_ptr + 1'b1;
	end
end

//	Full Detector
assign w_fifo_full = (w_wr_gray_ptr[AW] != r_gray_ptr_q2[0][AW]) 
							&& (w_wr_gray_ptr[AW-1] != r_gray_ptr_q2[0][AW-1]) 
							&& (w_wr_gray_ptr[AW-2:0] == r_gray_ptr_q2[0][AW-2:0]);
assign w_fifo_almost_full = (r_wr_ptr<w_gray2bin_ptr[0]) 
										? ((r_wr_ptr+ALMOST_TH) >= w_gray2bin_ptr[0]) 
										: (r_wr_ptr+ALMOST_TH) >= (((2**AW)-1)+w_gray2bin_ptr[0]);

always @(posedge wr_clk or negedge wr_rstn) begin
	if(~wr_rstn) begin
		r_wr_ptr 			<= AW*{1'b0};
		r_gray_ptr_q[0] 	<= AW*{1'b0};
		r_gray_ptr_q2[0] 	<= AW*{1'b0};
		r_rst_q[0]			<=	1'b0;
		r_rst_q2[0]			<=	1'b0;
	end
	else if(wr_sw_rst|r_rst_q2[0]) begin
		r_wr_ptr 			<= AW*{1'b0};
		r_gray_ptr_q[0] 	<= AW*{1'b0};
		r_gray_ptr_q2[0] 	<= AW*{1'b0};
		r_rst_q[0]			<=	1'b0;
		r_rst_q2[0]			<=	1'b0;
	end
	else begin
		r_wr_ptr 			<= r_wr_ptr_next;
		r_gray_ptr_q[0] 	<= w_rd_gray_ptr;
		r_gray_ptr_q2[0] 	<= r_gray_ptr_q[0];
		r_rst_q[0]			<=	rd_sw_rst;
		r_rst_q2[0]			<=	r_rst_q[0];
	end
end

always @(posedge wr_clk or negedge wr_rstn) begin
	if(~wr_rstn) begin
		for(i=0;i<(2**AW);i=i+1) begin
			fifo_data[i] <= DW*{1'b0};
		end
	end
	else if(wr_sw_rst|r_rst_q2[0]) begin
		for(i=0;i<(2**AW);i=i+1) begin
			fifo_data[i] <= DW*{1'b0};
		end
	end
	else 
		if(w_wr_en)
			fifo_data[w_wr_addr]	<= i_wr_data;
end

assign w_wr_addr = r_wr_ptr[AW-1:0];

// //////////////////////////////////////////////
// 				Read Domain Function
// //////////////////////////////////////////////
reg [AW:0]	r_rd_ptr, r_rd_ptr_next;


always @(*) begin
	r_rd_ptr_next = r_rd_ptr;

	if(w_rd_en_valid)
		if(r_rd_ptr == ((2**(AW+1))-1))
			r_rd_ptr_next = AW*{1'b0};
		else
			r_rd_ptr_next = r_rd_ptr + 1'b1;
end

assign w_fifo_empty = (w_rd_gray_ptr == r_gray_ptr_q2[1]);
assign w_fifo_almost_empty = (r_rd_ptr<w_gray2bin_ptr[1]) 
										? ((r_rd_ptr+ALMOST_TH) >= w_gray2bin_ptr[1]) 
										: (r_rd_ptr+ALMOST_TH) >= (((2**AW)-1)+w_gray2bin_ptr[1]);


always @(posedge rd_clk or negedge rd_rstn) begin
	if(~rd_rstn) begin
		r_rd_ptr 			<= AW*{1'b0};
		r_gray_ptr_q[1] 	<= AW*{1'b0};
		r_gray_ptr_q2[1] 	<= AW*{1'b0};
		r_rst_q[1]			<= 1'b0;
		r_rst_q2[1]			<= 1'b0;
	end
	else if(rd_sw_rst|r_rst_q2[1]) begin	
		r_rd_ptr 			<= AW*{1'b0};
		r_gray_ptr_q[1] 	<= AW*{1'b0};
		r_gray_ptr_q2[1] 	<= AW*{1'b0};
		r_rst_q[1]			<= 1'b0;
		r_rst_q2[1]			<= 1'b0;
	end
	else begin
		r_rd_ptr 			<= r_rd_ptr_next;
		r_gray_ptr_q[1] 	<= w_wr_gray_ptr;
		r_gray_ptr_q2[1] 	<= r_gray_ptr_q[1];
		r_rst_q[1]			<= wr_sw_rst|(~wr_rstn);
		r_rst_q2[1]			<= r_rst_q[1];
	end
end

reg_out #(1) u_rd_en_q (.clk(rd_clk), .rstn(rd_rstn), .in(i_rd_en), .out(w_rd_en_q));

assign w_rd_en_valid = w_rd_en_q & ~w_fifo_empty;
assign w_rd_addr = r_rd_ptr[AW-1:0];


// Binary to Gray converter
assign w_wr_gray_ptr = r_wr_ptr^(r_wr_ptr >> 1);
assign w_rd_gray_ptr = r_rd_ptr^(r_rd_ptr >> 1);

//	Gray to Binary converter
genvar	gi, gj;
generate
	for(gi=0;gi<2;gi=gi+1)begin
		assign w_gray2bin_ptr[gi][AW] = r_gray_ptr_q2[gi][AW];
		for(gj=0;gj<AW;gj=gj+1) begin
				assign w_gray2bin_ptr[gi][AW-1-gj] = r_gray_ptr_q2[gi][AW-gj-1]^w_gray2bin_ptr[gi][AW-gj];
		end
	end
endgenerate

assign	o_wr_fifo_full = w_fifo_full;
assign	o_rd_data = fifo_data[w_rd_addr];
assign	o_rd_valid = w_rd_en_valid;
assign	o_rd_fifo_empty = w_fifo_empty;

endmodule
