/////////////////////////////////////////////////////////
// This module is the top module of HACK computer.     //
// Here CPU, data memory and instruction memory are    //
// integrated. Different clocks are provided to memory //
// and the CPU to have data integrity.                 //
/////////////////////////////////////////////////////////

`default_nettype none

// Main module for HACK_comp
module HACK_comp(
	// Power pins
	`ifdef USE_POWER_PINS
	inout vccd1,			// User area 1 1.8V supply
	inout vssd1,			// User area 1 digital ground
	`endif
	// Ports
	input wire	clock,		// Main clock for the system
	input wire	reset_n,	// Main reset for the system
	input wire	mem_clr_n,	// Reset for memory
	
	input wire	write_ins,	// Write into instruction memory
	//input wire	read_ins,	// Read from instruction memory
	input wire	write_data,	// Write into data memory
	input wire	read_data,	// Read from data memory
	
	input wire [15:0] addr_ins,	// Instruction memory address
	input wire [15:0] dati_ins,	// Data into instruction memory
	//output wire [15:0] dato_ins,	// Data from instruction memory
	
	input wire [15:0] addr_data,	// Data memory address
	input wire [15:0] dati_data,	// Data into Data memory
	output wire [15:0] dato_data,	// Data from Data memory
	
	output wire	data_memfull,	// Data memory full flag
	output wire	ins_memfull	// Instruction memory full flag
	);
	
	reg clock_cpu;	// Clock for the CPU
	
	wire [14:0] pc;
	wire [15:0] instruction;
	
	wire writeM;
	wire [14:0] addressM;
	wire [15:0] outM;
	wire [15:0] inM;
	
	// Data memory ports
	wire data_rden;
	wire data_wren;
	wire [15:0] data_in;
	wire [15:0] data_out;
	wire [14:0] dati_addr;
	wire [14:0] dato_addr;
	
	// Instruction memory ports
	wire inst_rden;
	wire inst_wren;
	wire [15:0] inst_in;
	wire [15:0] inst_out;
	wire [14:0] insi_addr;
	wire [14:0] inso_addr;
	
	
	SRAM #(.DATA_SIZE(16), .SRAM_DEPTH_LOG2(15))
	ins_mem0 (`ifdef USE_POWER_PINS
		  .vccd1(vccd1),	// User area 1 1.8V power
		  .vssd1(vssd1),	// User area 1 digital ground
		  `endif
		  .clock(clock), .reset_n(mem_clr_n),
		  .data_rden(inst_rden), .data_wren(inst_wren),
		  .data_in(inst_in), .data_out(inst_out),
		  .addr_in(insi_addr), .addr_out(inso_addr),
		  .sram_full(ins_memfull));
	
	SRAM #(.DATA_SIZE(16), .SRAM_DEPTH_LOG2(15))
	dat_mem0 (`ifdef USE_POWER_PINS
		  .vccd1(vccd1),	// User area 1 1.8V power
		  .vssd1(vssd1),	// User area 1 digital ground
		  `endif
		  .clock(clock), .reset_n(mem_clr_n),
		  .data_rden(data_rden), .data_wren(data_wren),
		  .data_in(data_in), .data_out(data_out),
		  .addr_in(dati_addr), .addr_out(dato_addr),
		  .sram_full(data_memfull));
	
	CPU_hc CPU0 (`ifdef USE_POWER_PINS
		     .vccd1(vccd1),	// User area 1 1.8V power
		     .vssd1(vssd1),	// User area 1 digital ground
		     `endif
		     .clock(clock_cpu), .reset_n(reset_n),
		     .inM(inM), .instruction(instruction),
		     .outM(outM), .writeM(writeM),
		     .addressM(addressM), .pc(pc));
	
	assign data_rden = 1'b1;
	assign data_wren = write_data ? 1'b1 : writeM;
	assign dati_addr = write_data ? addr_data[14:0] : addressM;
	assign dato_addr = read_data ? addr_data[14:0] : addressM;
	assign data_in = write_data ? dati_data : outM;
	assign dato_data = data_out;
	assign inM = data_out;
	
	assign inst_rden = 1'b1;
	assign inst_wren = write_ins ? 1'b1 : 1'b0;
	assign insi_addr = addr_ins[14:0];
	assign inso_addr = pc;
	//assign inso_addr = read_ins ? addr_ins[14:0] : pc;
	assign inst_in = dati_ins;
	assign instruction = inst_out;
	//assign dato_ins = inst_out;
		  
	initial begin
		clock_cpu = 1'b0;
	end
	
	always @(posedge clock, negedge reset_n) begin
		if (~reset_n)
			clock_cpu <= 1'b0;
		else
			clock_cpu <= ~clock_cpu;
	end
	
endmodule

`default_nettype wire
