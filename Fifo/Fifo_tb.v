/////////////////////////////////////////////////////////
// This module is to test the Fifo project. For more   //
// details, please refer the "FIFO.v" design file.     //
/////////////////////////////////////////////////////////

`default_nettype none

`timescale 10 ns / 1 ps

module Fifo_tb();

	reg clock;		// Main clk for fifo
	reg reset_n;		// Master reset for fifo
	
	reg data_inen;		// Data in flag
	reg data_outen;	// Data out flag
	
	wire fifo_empty;	// Fifo empty flag
	wire fifo_full;	// Fifo full flag
	
	reg [7:0] data_in;	// Data input to fifo
	wire [7:0] data_out;	// Data output from fifo
	
	Fifo #(.DATA_SIZE(16), .FIFO_SIZE(16))
	Fifo (.clock(clock), .reset_n(reset_n),
	      .data_inen(data_inen), .data_outen(data_outen),
	      .fifo_empty(fifo_empty), .fifo_full(fifo_full),
	      .data_in(data_in), .data_out(data_out));
	
	initial begin
		clock = 1'b0;
		reset_n = 1'b0;
		data_inen = 1'b0;
		data_outen = 1'b0;
		data_in = 8'd0;
	end
	
	always #1 clock <= ~clock;
	
	initial begin
		#100 reset_n = 1'b1;
		#10 data_in = 8'b11110000;
		#10 data_inen = 1'b1;
		#2 data_inen = 1'b0;
		#2 data_outen = 1'b1;
		#5 data_outen = 1'b0;
		#10 data_inen = 1'b1;
		#2 data_in = 8'd1;
		#2 data_in = 8'd2;
		#2 data_in = 8'd3;
		#2 data_in = 8'd4;
		#2 data_in = 8'd5;
		#2 data_in = 8'd6;
		#2 data_in = 8'd7;
		#2 data_in = 8'd8;
		#2 data_in = 8'd9;
		#2 data_in = 8'd10;
		#2 data_in = 8'd11;
		#2 data_in = 8'd12;
		#2 data_in = 8'd13;
		#2 data_in = 8'd14;
		#2 data_in = 8'd15;
		#2 data_in = 8'd16;
		#2 data_in = 8'd17;
		#2 data_in = 8'd18;
		#2 data_inen = 1'b0;
		#2 data_outen = 1'b1;
		#50 $display("All test cases finished!");
		$finish;
	end
	
	initial begin
		$dumpfile("Fifo_tb.vcd");
		$dumpvars(0, Fifo_tb);
		
		repeat(250) @(posedge clock);
		$display("Monitor: Timeout; Test failed...");
		$finish;
	end

endmodule

`default_nettype wire
	
