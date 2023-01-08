/////////////////////////////////////////////////////////
// This module is to test the HACK Computer project.   //
// For more details, please refer the "HACK_comp.v"    //
// design file.                                        //
/////////////////////////////////////////////////////////

`default_nettype none

`timescale 10 ns / 1 ps

module HACK_comp_tb();
	
	reg	clock;		// Main clock for the system
	reg	reset_n;	// Main reset for the system
	reg	mem_clr_n;	// Reset for memory
	
	reg	write_ins;	// Write into instruction memory
	//reg	read_ins;	// Read from instruction memory
	reg	write_data;	// Write into data memory
	reg	read_data;	// Read from data memory
	
	reg [15:0] addr_ins;	// Instruction memory address
	reg [15:0] dati_ins;	// Data into instruction memory
	//wire  [15:0] dato_ins;	// Data from instruction memory
	
	reg [15:0] addr_data;	// Data memory address
	reg [15:0] dati_data;	// Data into Data memory
	wire [15:0] dato_data;	// Data from Data memory
	
	wire	data_memfull;	// Data memory full flag
	wire	ins_memfull;	// Instruction memory full flag
	
	HACK_comp comp0 (.clock(clock), .reset_n(reset_n), .mem_clr_n(mem_clr_n),
			 .write_ins(write_ins), //.read_ins(read_ins),
			 .write_data(write_data), .read_data(read_data),
			 .addr_ins(addr_ins), .dati_ins(dati_ins),
			 //.dato_ins(dato_ins), 
			 .addr_data(addr_data),
			 .dati_data(dati_data), .dato_data(dato_data),
			 .data_memfull(data_memfull), .ins_memfull(ins_memfull));
	
	initial begin
		clock = 1'b0;
		reset_n = 1'b0;
		mem_clr_n = 1'b0;
		
		write_ins = 1'b0;
		//read_ins = 1'b0;
		write_data = 1'b0;
		read_data = 1'b0;
		
		addr_ins = 16'd0;
		dati_ins = 16'd0;
		addr_data = 16'd0;
		dati_data = 16'd0;
	end
	
	always #1 clock <= ~clock;
	
	initial begin
	
		#2 mem_clr_n = 1'b1;
		// Find max. of two numbers from Mem[0] and Mem[1]
		// Save max in Mem[2]
		#2 write_ins = 1'b1;			// Write instructions
		#2 addr_ins = 16'd0;			// Address
		#2 dati_ins = 16'b0000000000000000;	// Instruction
		#2 addr_ins = 16'd1;			// Address
		#2 dati_ins = 16'b1111110000010000;	// Instruction
		#2 addr_ins = 16'd2;			// Address
		#2 dati_ins = 16'b0000000000000001;	// Instruction
		#2 addr_ins = 16'd3;			// Address
		#2 dati_ins = 16'b1111010011010000;	// Instruction
		#2 addr_ins = 16'd4;			// Address
		#2 dati_ins = 16'b0000000000001010;	// Instruction
		#2 addr_ins = 16'd5;			// Address
		#2 dati_ins = 16'b1110001100000001;	// Instruction
		#2 addr_ins = 16'd6;			// Address
		#2 dati_ins = 16'b0000000000000001;	// Instruction
		#2 addr_ins = 16'd7;			// Address
		#2 dati_ins = 16'b1111110000010000;	// Instruction
		#2 addr_ins = 16'd8;			// Address
		#2 dati_ins = 16'b0000000000001100;	// Instruction
		#2 addr_ins = 16'd9;			// Address
		#2 dati_ins = 16'b1110101010000111;	// Instruction
		#2 addr_ins = 16'd10;			// Address
		#2 dati_ins = 16'b0000000000000000;	// Instruction
		#2 addr_ins = 16'd11;			// Address
		#2 dati_ins = 16'b1111110000010000;	// Instruction
		#2 addr_ins = 16'd12;			// Address
		#2 dati_ins = 16'b0000000000000010;	// Instruction
		#2 addr_ins = 16'd13;			// Address
		#2 dati_ins = 16'b1110001100001000;	// Instruction
		#2 addr_ins = 16'd14;			// Address
		#2 dati_ins = 16'b0000000000001110;	// Instruction
		#2 addr_ins = 16'd15;			// Address
		#2 dati_ins = 16'b1110101010000111;	// Instruction
		#2 write_ins = 1'b0;			// Instruction ends
		
		#2 write_data = 1'b1;			// Write data
		#2 addr_data = 16'd0;			// Address 0
		#2 dati_data = 16'd14;			// M[0]=14
		#2 addr_data = 16'd1;			// Address 1
		#2 dati_data = 16'd20;			// M[1]=20
		#2 write_data = 1'b0;			// Data ends
		
		#2 reset_n = 1'b1;			// Run code
		#50 read_data = 1'b1;			// Read data
		#2 addr_data = 16'd2;			// Address 2
		#2 $display(dato_data);		// Data
		#2 read_data = 1'b0;			// Read data ends
		if (dato_data == 16'd20)
			$display("All test cases passed!");
		else
			$display("Test failed!");
		$finish;
	
	/*
		#2 mem_clr_n = 1'b1;
		// Add number 5 and 10 and put them in RAM[0]
		#2 write_ins = 1'b1;			// Write instructions
		#2 addr_ins = 16'd0;			// Address
		#2 dati_ins = 16'b0000000000000101;	// Instruction
		#2 addr_ins = 16'd1;			// Address
		#2 dati_ins = 16'b1110110000010000;	// Instruction
		#2 addr_ins = 16'd2;			// Address
		#2 dati_ins = 16'b0000000000001010;	// Instruction
		#2 addr_ins = 16'd3;			// Address
		#2 dati_ins = 16'b1110000010010000;	// Instruction
		#2 addr_ins = 16'd4;			// Address
		#2 dati_ins = 16'b0000000000000000;	// Instruction
		#2 addr_ins = 16'd5;			// Address
		#2 dati_ins = 16'b1110001100001000;	// Instruction
		#2 write_ins = 1'b0;			// Instruction ends
		
		#2 reset_n = 1'b1;			// Run code
		#50 read_data = 1'b1;			// Read data
		#2 addr_data = 16'd0;			// Address 0
		#2 $display(dato_data);		// Data
		#2 read_data = 1'b0;			// Read data ends
		if (dato_data == 16'd15)
			$display("All test cases passed!");
		else
			$display("Test failed!");
		$finish;
	*/
	end
	
	initial begin
		$dumpfile("HACK_comp_tb.vcd");
		$dumpvars(0, HACK_comp_tb);
		
		repeat(300) @(posedge clock);
		$display("Monitor: Timeout; Test failed...");
		$finish;
	end
	
endmodule

`default_nettype wire

