/////////////////////////////////////////////////////////
// This module is to create a Program Counter inside   //
// the project. The co unter have variable data size   //
// that can be adjusted using the parameters           //
// "DATA_SIZE". It can be loaded, incremented or set   //
// to give the previous value.                         //
/////////////////////////////////////////////////////////

`default_nettype none

// Main module for Register
module Program_counter #(
	parameter DATA_SIZE = 16		// Data size of the register
	)(
	// Power pins
	`ifdef USE_POWER_PINS
	inout vccd1,				// User area 1 1.8V supply
	inout vssd1,				// User area 1 digital ground
	`endif
	// Ports
	input wire clock,			// Main clock
	input wire reset_n,			// Main reset_n
	
	
	input wire [(DATA_SIZE-1):0] in,	// Input data
	output reg [(DATA_SIZE-1):0] out,	// Output data
	
	input wire inc,			// Increment operation
	input wire load			// Load operation
	);
	
	initial begin
		out = {DATA_SIZE{1'b0}};
	end
	
	always @(posedge clock, negedge reset_n) begin
		if (~reset_n)
			out <= 0;
		else begin
			if (load)
				out <= in;
			else if (inc)
				out <= out + 1;
			else
				out <= out;
		end
	end
	
endmodule

`default_nettype wire

