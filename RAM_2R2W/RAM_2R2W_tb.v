/////////////////////////////////////////////////////////
// This module is to test the RAM project. For more    //
// details, please refer the "RAM_2R2W.v" design file. //
/////////////////////////////////////////////////////////

`default_nettype none

`timescale 10 ns / 1 ps

module RAM_2R2W_tb();
	
	parameter DATA_SIZE = 16;			// RAM data size
	parameter RAM_DEPTH_LOG2 = 5;			// RAM address size
	parameter RAM_DEPTH = 2**RAM_DEPTH_LOG2;	// RAM depth
	
	reg clock;		// Main clk for fifo
	reg reset_n;		// Master reset for fifo
	
	reg data_rden1;	// Data read flag 1
	reg data_rden2;	// Data read flag 2
	
	reg data_wren1;	// Data write flag 1
	reg data_wren2;	// Data write flag 2
	
	reg [(DATA_SIZE-1):0] data_in1;	 // Data input 1 to RAM
	reg [(DATA_SIZE-1):0] data_in2;	 // Data input 2 to RAM
	
	wire [(DATA_SIZE-1):0] data_out1;	 // Data output 1 from RAM
	wire [(DATA_SIZE-1):0] data_out2;	 // Data output 2 from RAM
	
	reg [(RAM_DEPTH_LOG2 - 1):0] addr_in1;   // Input address 1 to RAM
	reg [(RAM_DEPTH_LOG2 - 1):0] addr_in2;   // Input address 2 to RAM
	
	wire RAM_full;		// High when addr_in is max.
	
	RAM_2R2W #(.DATA_SIZE(DATA_SIZE), .RAM_DEPTH_LOG2(RAM_DEPTH_LOG2))
	RAM (.clock(clock), .reset_n(reset_n),
	      .data_rden1(data_rden1), .data_rden2(data_rden2), 
	      .data_wren1(data_wren1), .data_wren2(data_wren2),
	      .data_in1(data_in1), .data_in2(data_in2),
	      .data_out1(data_out1), .data_out2(data_out2),
	      .addr_in1(addr_in1), .addr_in2(addr_in2),
	      .RAM_full(RAM_full));
	
	initial begin
		clock = 1'b0;
		reset_n = 1'b0;
		data_rden1 = 1'b0;
		data_rden2 = 1'b0;
		data_wren1 = 1'b0;
		data_wren2 = 1'b0;
		data_in1 = {DATA_SIZE{1'b0}};
		data_in2 = {DATA_SIZE{1'b0}};
		addr_in1 = {RAM_DEPTH_LOG2{1'b0}};
		addr_in2 = {RAM_DEPTH_LOG2{1'b0}};
	end
	
	always #1 clock <= ~clock;
	
	initial begin
		#100 reset_n = 1'b1;
		
		#2 addr_in1 = 16'd0;
		#2 data_wren1 = 1'b1;
		#2 data_in1 = 16'habcd;
		#2 data_wren1 = 1'b0;
		
		#2 addr_in2 = 16'd1;
		#2 data_wren2 = 1'b1;
		#2 data_in2 = 16'hef01;
		#2 data_wren2 = 1'b0;
		
		#2 addr_in1 = 16'd1;
		#2 data_rden1 = 1'b1;
		#2 $display(data_in2, " : ", data_out1);
		#2 data_rden1 = 1'b0;
		
		
		#2 addr_in2 = 16'd0;
		#2 data_rden2 = 1'b1;
		#2 $display(data_in1, " : ", data_out2);
		#2 data_rden2 = 1'b0;
		
		if ((data_out1==data_in2) & (data_out2==data_in1))
			$display("All test cases passed!");
		else
			$display("Test failed...");
		$finish;
	end
	
	initial begin
		$dumpfile("RAM_2R2W_tb.vcd");
		$dumpvars(0, RAM_2R2W_tb);
		
		repeat(200) @(posedge clock);
		$display("Monitor: Timeout; Test failed...");
		$finish;
	end

endmodule

`default_nettype wire
	
