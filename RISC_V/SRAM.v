/////////////////////////////////////////////////////////
// This module is to create a SRAM inside the project. //
// The SRAM have variable data size depth that can be  //
// adjusted using the parameters "DATA_SIZE" and       //
// "SRAM_DEPTH_LOG2" respectively. It is 1R1W SRAM.    //
// Both operations can work parallely but take care of //
// data coherency.                                     //
/////////////////////////////////////////////////////////

`default_nettype none

// Main module for SRAM
module SRAM #(
	parameter DATA_SIZE = 16,			// SRAM data size
	parameter SRAM_DEPTH_LOG2 = 5,		// SRAM address size
	parameter SRAM_DEPTH = 2**SRAM_DEPTH_LOG2	// SRAM depth
	)(
	// Power pins
	`ifdef USE_POWER_PINS
	inout vccd1,			// User area 1 1.8V supply
	inout vssd1,			// User area 1 digital ground
	`endif
	// Ports
	input wire clock,		// Main clk for sram
	input wire reset_n,		// Master reset for sram
	
	input wire data_rden,		// Data read flag
	input wire data_wren,		// Data write flag
	
	input wire [(DATA_SIZE-1):0] data_in,	 // Data input to sram
	output reg [(DATA_SIZE-1):0] data_out, // Data output from sram
	
	input wire [(SRAM_DEPTH_LOG2 - 1):0] addr_in,	 // Input data address
	input wire [(SRAM_DEPTH_LOG2 - 1):0] addr_out, // Output data address
	
	output wire sram_full		// High when addr_in is max.
	);
	
	reg [(DATA_SIZE-1):0] memory [(SRAM_DEPTH-1):0];	// Main memory
	
	integer i = 0;	// temp variable
	
	assign sram_full = &addr_in;
	
	initial begin
		data_out = {DATA_SIZE{1'b0}};
		
		for (i=0; i<SRAM_DEPTH; i=i+1)
			memory[i] = 0;
	end
	
	always @ (posedge clock, negedge reset_n) begin
		if (~reset_n) begin	// reset everything
			data_out = {DATA_SIZE{1'b0}};
		
			for (i=0; i<SRAM_DEPTH; i=i+1)
				memory[i] = 0;
		end
		else begin
			if (data_wren)
				memory[(addr_in/4)] <= data_in;
			
			if (data_rden)
				data_out <= memory[(addr_out/4)];
			
		end
	end

endmodule

`default_nettype wire

