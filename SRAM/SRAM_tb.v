/////////////////////////////////////////////////////////
// This module is to test the SRAM project. For more   //
// details, please refer the "SRAM.v" design file.     //
/////////////////////////////////////////////////////////

`default_nettype none

`timescale 10 ns / 1 ps

module SRAM_tb();
	
	parameter DATA_SIZE = 16;			// SRAM data size
	parameter SRAM_DEPTH_LOG2 = 5;		// SRAM address size
	parameter SRAM_DEPTH = 2**SRAM_DEPTH_LOG2;	// SRAM depth
	
	reg clock;		// Main clk for fifo
	reg reset_n;		// Master reset for fifo
	
	reg data_rden;		// Data read flag
	reg data_wren;		// Data write flag
	
	reg [(DATA_SIZE-1):0] data_in;	 // Data input to sram
	wire [(DATA_SIZE-1):0] data_out;	 // Data output from sram
	
	reg [(SRAM_DEPTH_LOG2 - 1):0] addr_in;   // Input address to sram
	reg [(SRAM_DEPTH_LOG2 - 1):0] addr_out; // Output address to sram
	
	wire sram_full;		// High when addr_in is max.
	
	SRAM #(.DATA_SIZE(DATA_SIZE), .SRAM_DEPTH_LOG2(SRAM_DEPTH_LOG2))
	SRAM (.clock(clock), .reset_n(reset_n),
	      .data_rden(data_rden), .data_wren(data_wren),
	      .data_in(data_in), .data_out(data_out),
	      .addr_in(addr_in), .addr_out(addr_out),
	      .sram_full(sram_full));
	
	initial begin
		clock = 1'b0;
		reset_n = 1'b0;
		data_rden = 1'b0;
		data_wren = 1'b0;
		data_in = {DATA_SIZE{1'b0}};
		addr_in = {SRAM_DEPTH_LOG2{1'b0}};
	end
	
	always #1 clock <= ~clock;
	
	initial begin
		#100 reset_n = 1'b1;
		#10 data_in = 32;
		#2 addr_in = 0;
		#2 data_wren = 1'b1;
		#2 data_wren = 1'b0;
		#2 addr_out = 0;
		#2 data_rden = 1'b1;
		#2 data_rden = 1'b0;
		#10 data_in = 100;
		#2 addr_in = -2;
		#2 data_wren = 1'b1;
		#2 data_wren = 1'b0;
		#10 data_in = 200;
		#2 addr_in = -1;
		#2 data_wren = 1'b1;
		#2 data_wren = 1'b0;
		#2 addr_out = -2;
		#2 data_rden = 1'b1;
		#2 addr_out = -1;
		#2 data_rden = 1'b0;
		#10 $display("All test cases finished!");
		$finish;
	end
	
	initial begin
		$dumpfile("SRAM_tb.vcd");
		$dumpvars(0, SRAM_tb);
		
		repeat(200) @(posedge clock);
		$display("Monitor: Timeout; Test failed...");
		$finish;
	end

endmodule

`default_nettype wire
	
