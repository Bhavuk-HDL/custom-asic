/////////////////////////////////////////////////////////
// This module is to test the SPI_cntrl project. For   //
// more details, please refer the "SPI_cntrl.v" design.//
/////////////////////////////////////////////////////////

`default_nettype none

`timescale 10 ns / 1 ps

module SPI_cntrl_tb();
	reg		clock;		// Main clock for module
	reg		reset_n;	// System reset
	
	reg		start;		// Start the SPI comm.
	reg  [7:0]	clk_ratio;	// Ratio of clock to SCLK
	
	reg		fifo_wren;	// Fifo write en
	reg  [31:0]	data_in;	// Data to the fifo
	
	wire		busy;		// SPI working signal
	
	wire		data_full;	// Fifo full flag
	wire		data_empty;	// Fifo empty flag
	
	// External ports
	wire		SEN;	// Serial Interface Enable; Active low
	wire		SCLK;	// Serial Interface Clock
	wire		SDATA;	// Serial Interface Data
	
	reg [23:0] check_reg_tb0;
	reg [23:0] check_reg_tb1;
	reg [23:0] check_reg_tb2;
	
	SPI_cntrl SPI_cntrl0(.clock(clock), .reset_n(reset_n), .start(start),
			      .clk_ratio(clk_ratio), .busy(busy),
			      .fifo_wren(fifo_wren), .data_in(data_in),
			      .data_full(data_full), .data_empty(data_empty),
			      .SEN(SEN), .SCLK(SCLK), .SDATA(SDATA));
	
	initial begin
		clock		= 1'b0;
		reset_n	= 1'b0;
		start		= 1'b0;
		clk_ratio	= 8'd0;
		
		fifo_wren	= 1'b0;
		data_in	= 32'd0;
	end
	
	always #1 clock <= ~clock;
	
	initial begin
		#10 reset_n	= 1'b1;
		#2 clk_ratio	= 8'd8;
		
		#2 data_in	= 32'h0019ac;
		fifo_wren	= 1'b1;
		#2 data_in	= 32'hffa5a5;
		#2 data_in	= 32'hf0abcd;
		#2 fifo_wren	= 1'b0;
		
		#2 start	= 1'b1;
		#2 start	= 1'b0;
	end
	
	always @(posedge SCLK)
	begin
		{check_reg_tb0, check_reg_tb1, check_reg_tb2} <= 
		{check_reg_tb0, check_reg_tb1, check_reg_tb2} << 1;
		check_reg_tb2[0] <= SDATA;
	end
	
	initial begin
		#1400;
		$display("check_reg_tb0 : ", check_reg_tb0);
		$display("check_reg_tb1 : ", check_reg_tb1);
		$display("check_reg_tb2 : ", check_reg_tb2);
		if ((check_reg_tb0 == 24'hac0019) &&
		    (check_reg_tb1 == 24'ha5ffa5) &&
		    (check_reg_tb2 == 24'hcdf0ab))
			$display("All Test casses passed!!!");
		else
			$display("Test Failed...");
		$finish;
	end
	
	initial begin
		$dumpfile("SPI_cntrl_tb.vcd");
		$dumpvars(0, SPI_cntrl_tb);
		
		repeat(2000) @(posedge clock);
		$display("Monitor: Timeout; Test failed...");
		$finish;
	end
	
endmodule

`default_nettype wire
