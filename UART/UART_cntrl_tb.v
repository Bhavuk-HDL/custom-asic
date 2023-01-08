/////////////////////////////////////////////////////////
// This module is to test the UART_cntrl project. For  //
// more details, please refer "UART_cntrl.v" design.   //
/////////////////////////////////////////////////////////

`default_nettype none

`timescale 10 ns / 1 ps

module UART_cntrl_tb();
	reg	clock;		// Main clock for module
	reg	reset_n;	// System reset
	
	reg	start_tx;	// Start the UART-Tx
	reg	start_rx;	// Start the UART-Rx
	reg [7:0] clk_ratio;	// Ratio of clock to baudrate
	
	reg	fifo_wren;	// Fifo write en
	reg	fifo_rden;	// Fifo read en
	reg [7:0] data_in;	// Data to the fifo
	wire [7:0] data_out;	// Data from the fifo
	
	reg	parityen;	// 1 to enable parity bit
	reg	parityodd;	// 0 for odd parity; 1 for even parity;
	
	wire	busy_tx;	// UART_Tx working signal
	wire	busy_rx;	// UART_Rx working signal
	
	wire	data_fulltx;	// Tx fifo full flag
	wire	data_emptytx;	// Tx fifo empty flag
	
	wire	data_fullrx;	// Rx fifo full flag
	wire	data_emptyrx;	// Rx fifo empty flag
	// External ports
	wire	UART_Tx;	// Serial Interface Enable; Active low
	reg	UART_Rx;	// Serial Interface Clock
	
	reg [7:0] check_reg_tb0;
	reg [7:0] check_reg_tb1;
	reg [7:0] check_reg_tb2;
	
	UART_cntrl UART0 (.clock(clock), .reset_n(reset_n),
			  .start_tx(start_tx), .start_rx(start_rx), .clk_ratio(clk_ratio),
			  .fifo_wren(fifo_wren), .fifo_rden(fifo_rden),
			  .data_in(data_in), .data_out(data_out),
			  .parityen(parityen), .parityodd(parityodd),
			  .busy_tx(busy_tx), .busy_rx(busy_rx),
			  .data_fulltx(data_fulltx), .data_emptytx(data_emptytx),
			  .data_fullrx(data_fullrx), .data_emptyrx(data_emptyrx),
			  .UART_Tx(UART_Tx), .UART_Rx(UART_Rx));
	
	initial begin
		clock		= 1'b0;
		reset_n	= 1'b0;
		start_tx	= 1'b0;
		start_rx	= 1'b0;
		
		fifo_wren	= 1'b0;
		fifo_rden	= 1'b0;
		
		parityen	= 1'b0;
		parityodd	= 1'b0;
		
		UART_Rx	= 1'b0;
		
		clk_ratio	= 8'd0;
		data_in	= 8'd0;
	end
	
	always #1 clock <= ~clock;
	
	always @(posedge clock) UART_Rx <= UART_Tx;
	
	initial begin
		// Starting setup
		#10 reset_n	= 1'b1;
		#2 clk_ratio	= 8'd8;
		parityen	= 1'b1;
		parityodd	= 1'b1;
		#2 data_in	= 8'ha5;
		fifo_wren	= 1'b1;
		#2 data_in	= 8'h21;
		#2 data_in	= 8'h3d;
		#2 fifo_wren	= 1'b0;
		// Starting Tx and Rx
		#2 start_rx	= 1'b1;
		start_tx	= 1'b1;
		#800 start_tx = 1'b0;
		start_rx	= 1'b0;
		// Starting validation
		#2 fifo_rden	= 1'b1;
		#2 check_reg_tb0 = data_out;
		#2 check_reg_tb1 = data_out;
		#2 check_reg_tb2 = data_out;
		#2 fifo_rden	= 1'b0;
		$display("check_reg_tb0 : ", check_reg_tb0);
		$display("check_reg_tb1 : ", check_reg_tb1);
		$display("check_reg_tb2 : ", check_reg_tb2);
		if ((check_reg_tb0 == 8'ha5) &&
		    (check_reg_tb1 == 8'h21) &&
		    (check_reg_tb2 == 8'h3d))
			$display("All Test casses passed!!!");
		else
			$display("Test Failed...");
		$finish;
	end
	
	initial begin
		$dumpfile("UART_cntrl_tb.vcd");
		$dumpvars(0, UART_cntrl_tb);
		
		repeat(1000) @(posedge clock);
		$display("Monitor: Timeout; Test failed...");
		$finish;
	end
	
endmodule

`default_nettype wire
