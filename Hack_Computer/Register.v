/////////////////////////////////////////////////////////
// This module is to create a Register inside the      //
// Project. The Register have variable data size that  //
// can be adjusted using the parameters "DATA_SIZE".   //
/////////////////////////////////////////////////////////

`default_nettype none

// Main module for Register
module Register #(
	parameter DATA_SIZE = 16		// Data size of the register
	)(
	// Power pins
	`ifdef USE_POWER_PINS
	inout vccd1,				// User area 1 1.8V supply
	inout vssd1,				// User area 1 digital ground
	`endif
	// Ports
	input wire clock,			// Main clock
	
	input wire [(DATA_SIZE-1):0] in,	// Input data
	output reg [(DATA_SIZE-1):0] out,	// Output data
	
	input wire load			// Load operation
	);
	
	initial
		out = {DATA_SIZE{1'b0}};
		
	always @(posedge clock)
		out <= load ? in : out;

endmodule

`default_nettype wire

