/////////////////////////////////////////////////////////
// This module is to create a Fifo inside the project. //
// The Fifo's data size and depth can be adjusted      //
// using the parameters, "DATA_SIZE" and "FIFO_SIZE"   //
// respectively.                                       //
/////////////////////////////////////////////////////////

`default_nettype none

// Main module for Fifo
module Fifo#(
	parameter DATA_SIZE = 8,
	parameter FIFO_SIZE = 8	// Fifo size
	)(
	// Power pins
	`ifdef USE_POWER_PINS
	inout vccd1,			// User area 1 1.8V supply
	inout vssd1,			// User area 1 digital ground
	`endif
	// Ports
	input wire clock,		// Main clk for fifo
	input wire reset_n,		// Master reset for fifo
	
	input wire data_inen,		// Data in flag
	input wire data_outen,		// Data out flag
	
	output wire fifo_empty,	// Fifo empty flag
	output wire fifo_full,		// Fifo full flag
	
	input wire [(DATA_SIZE-1):0] data_in,	// Data input to fifo
	output reg [(DATA_SIZE-1):0] data_out	// Data output from fifo
	);
	
	reg [($clog2(FIFO_SIZE) - 1) : 0] wptr;	// Write pointer
	reg [($clog2(FIFO_SIZE) - 1) : 0] rptr;	// Read pointer
	
	reg fifo_emptyreg;				// Fifo empty reg
	reg fifo_fullreg;				// Fifo full reg
	
	reg [(DATA_SIZE-1):0] memory [(FIFO_SIZE - 1):0];	// Memory for the fifo
	
	integer i = 0;					// temp variable
	
	assign fifo_empty = fifo_emptyreg;
	assign fifo_full = fifo_fullreg;
	
	initial begin
		wptr = 0;
		rptr = 0;
		
		fifo_emptyreg = 1'b1;
		fifo_fullreg  = 1'b0;
		
		data_out = {DATA_SIZE{1'b0}};
		
		for (i=0; i<FIFO_SIZE; i=i+1)
			memory[i] = 0;
	end
	
	always @ (posedge clock, negedge reset_n) begin
		if (~reset_n) begin	// reset everything
			wptr = 0;
			rptr = 0;
			
			fifo_emptyreg = 1'b1;
			fifo_fullreg  = 1'b0;
			
			data_out = {DATA_SIZE{1'b0}};
			
			for (i=0; i<FIFO_SIZE; i=i+1)
				memory[i] = 0;
		end
		else begin
			if ((~fifo_fullreg) & (data_inen)) begin
				memory[wptr] <= data_in;
				wptr <= wptr + 1;
				fifo_emptyreg <= 1'b0;
				
				if ((wptr+1'b1)==rptr)
					fifo_fullreg <= 1'b1;
				else
					fifo_fullreg <= 1'b0;
			end
			
			if ((~fifo_emptyreg) & (data_outen)) begin
				data_out <= memory[rptr];
				rptr <= rptr + 1;
				fifo_fullreg <= 1'b0;
				
				if ((rptr+1'b1)==wptr)
					fifo_emptyreg <= 1'b1;
				else
					fifo_emptyreg <= 1'b0;
			end
		end
	end

endmodule

`default_nettype wire

