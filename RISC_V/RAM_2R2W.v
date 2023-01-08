/////////////////////////////////////////////////////////
// This module is to create a RAM inside the project.  //
// The RAM have variable data size depth that can be   //
// adjusted using the parameters "DATA_SIZE" and       //
// "RAM_DEPTH_LOG2" respectively. It is 2R2W RAM.      //
// Both operations can work parallely but take care of //
// data coherency. Both RW use same clock.             //
/////////////////////////////////////////////////////////

`default_nettype none

// Main module for 2RAM
module RAM_2R2W #(
	parameter DATA_SIZE = 16,			// RAM data size
	parameter RAM_DEPTH_LOG2 = 5,			// RAM address size
	parameter RAM_DEPTH = 2**RAM_DEPTH_LOG2	// RAM depth
	)(
	// Power pins
	`ifdef USE_POWER_PINS
	inout vccd1,			// User area 1 1.8V supply
	inout vssd1,			// User area 1 digital ground
	`endif
	// Ports
	input wire clock,		// Main clk for RAM
	input wire reset_n,		// Master reset for RAM
	
	input wire data_rden1,		// Data read flag 1
	input wire data_wren1,		// Data write flag 1
	
	input wire data_rden2,		// Data read flag 2
	input wire data_wren2,		// Data write flag 2
	
	input wire [(DATA_SIZE-1):0] data_in1, // Data input 1 to RAM
	input wire [(DATA_SIZE-1):0] data_in2, // Data input 2 to RAM
	
	output reg [(DATA_SIZE-1):0] data_out1, // Data output 1 from RAM
	output reg [(DATA_SIZE-1):0] data_out2, // Data output 2 from RAM
	
	input wire [(RAM_DEPTH_LOG2 - 1):0] addr_in1rd, // Read address 1
	input wire [(RAM_DEPTH_LOG2 - 1):0] addr_in2rd, // Read address 2
	input wire [(RAM_DEPTH_LOG2 - 1):0] addr_in1wr, // Read address 1
	input wire [(RAM_DEPTH_LOG2 - 1):0] addr_in2wr, // Read address 2
	
	//input wire [(RAM_DEPTH_LOG2 - 1):0] addr_test, // Read address test
	//output reg [(DATA_SIZE-1):0] data_test, // Data output test
	
	output wire RAM_full		// High when addr_inwr is max. (Any one)
	);
	
	reg [(DATA_SIZE-1):0] memory [(RAM_DEPTH-1):0];	// Main memory
	
	integer i = 0;	// temp variable
	
	assign RAM_full = (&addr_in1wr) | (&addr_in2wr);
	
	initial begin
		data_out1 = {DATA_SIZE{1'b0}};
		data_out2 = {DATA_SIZE{1'b0}};
		
		for (i=0; i<RAM_DEPTH; i=i+1)
			memory[i] = 0;
	end
	
	always @ (posedge clock, negedge reset_n) begin
		if (~reset_n) begin	// reset everything
			data_out1 = {DATA_SIZE{1'b0}};
			data_out2 = {DATA_SIZE{1'b0}};
		
			for (i=0; i<RAM_DEPTH; i=i+1)
				memory[i] = 0;
		end
		else begin
			if (data_wren1)
				memory[addr_in1wr] <= data_in1;
			
			if (data_rden1)
				data_out1 <= memory[addr_in1rd];
			
			if (data_wren2)
				memory[addr_in2wr] <= data_in2;
			
			if (data_rden2)
				data_out2 <= memory[addr_in2rd];
			
			//data_test <= memory[addr_test];
			
		end
	end

endmodule

`default_nettype wire

