
/*********************************************************************************************
* 
* VSI CONFIDENTIAL
* __________________
* 
*  [2014] - [2022] Vehicular Solutions Innvated
*  All Rights Reserved.
* 
* NOTICE:  All information contained herein is, and remains
* the property of VSI and its suppliers, if any.
* The intellectual and technical concepts contained
* herein are proprietary to VSI 
* and its suppliers and may be covered by U.S. and Foreign Patents,
* patents in process, and are protected by trade secret or copyright law.
* Dissemination of this information or reproduction of this material
* is strictly forbidden unless prior written permission is obtained from VSI
*******************************************************************************/

/*************************************************
async_fifo_tb.v
working condition:
**************************************************/
`timescale 1ns/1ps
`include "define.v"

`define	RST_REL	100	// Reset release
`define SENDER_CLK  40
`define RECEIVER_CLK  30
`define 	DW				8	
module async_fifo_tb();
parameter DW=`DW;
reg 	rstn;
reg 	tx_clk;
reg   rx_clk;
reg   tx_rstn;
reg   rx_rstn;


reg [DW-1:0]   tx_i_data;
reg            tx_i_valid;
reg            rx_rd_en;


wire           tx_fifo_full;
wire [DW-1:0]  rx_o_data;
wire           rx_o_valid;
wire           rx_o_empty;

// RESET Release
initial begin
	tx_rstn=1'b0;
	rx_rstn=1'b0;
   tx_clk = 1'b0;
   rx_clk = 1'b0;
	#(`RST_REL);
	tx_rstn=1'b1;
	rx_rstn=1'b1;
end

always begin
   #(`SENDER_CLK)   tx_clk <= ~tx_clk;
end
always begin
   #(`RECEIVER_CLK)   rx_clk <= ~rx_clk;
end



async_fifo_template #(
) u_async_fifo (
   .wr_clk(tx_clk),
   .wr_rstn(tx_rstn),
   .wr_sw_rst(1'b0),

   .i_wr_data(tx_i_data),
   .i_wr_valid(tx_i_valid),
   .o_wr_fifo_full(tx_fifo_full),

   .rd_clk(rx_clk),
   .rd_rstn(rx_rstn),
   .rd_sw_rst(1'b0),

   .i_rd_en(rx_rd_en),
   .o_rd_data(rx_o_data),
   .o_rd_valid(rx_o_valid),
   .o_rd_fifo_empty(rx_o_empty)

);

integer i;
reg [7:0]      input_data = 8'd4;
// Write Domain


initial begin
   tx_i_data   =  DW*{1'b0};
   tx_i_valid  =  1'b0;
   rx_rd_en = 1'b0;
end

initial begin
   wait(tx_i_data == 40);
   // force tx_i_data   = 0;
   // force tx_i_valid  =  1'b0;
   tx_rstn = 1'b0;
   #2000
   $finish;
end


always @(posedge tx_clk or negedge rstn) begin
   if(~rstn) begin
      tx_i_data   <= DW*{1'b0};
      tx_i_valid  <= 1'b0;
   end
   else if(~tx_fifo_full) begin
      tx_i_data   <= tx_i_data + 1;
      tx_i_valid  <= 1'b1;
   end
   else begin
      tx_i_data   <= tx_i_data;
      tx_i_valid  <= 1'b1;
   end
end


always @(posedge rx_clk or negedge rstn) begin
   if(~rstn) begin
      rx_rd_en <= 1'b0;
   end
   else if(rx_o_empty) begin
      rx_rd_en <= 1'b0;
   end
   else begin
      rx_rd_en <= 1'b1;
   end
end
// // Read Domain
// initial begin
//    rx_rd_en = 1'b0;
//    #(20*`RECEIVER_CLK)
//    forever begin
//       wait(rx_o_empty == 1'b0)
//       #(1);
//       #(2*`RECEIVER_CLK)
//       rx_rd_en = 1'b0;
//       #(2*`RECEIVER_CLK);
//    end
// end

endmodule