/////////////////////////////////////////////////////////
// This module is to test the RISC V CORE project.     //
// For more details, please refer the "RISC_V.v"       //
// design file.                                        //
/////////////////////////////////////////////////////////

`default_nettype none

`timescale 10 ns / 1 ps

module RISC_V_tb();
	
	reg 	clock;		// Main clock for the system
	reg 	reset_n;	// Main reset for the system
	reg 	mem_clr_n;	// Reset for memory
	
	reg 	write_ins;	// Write into instruction memory
	//reg 	read_ins;	// Read from instruction memory
	reg 	write_data;	// Write into data memory
	reg 	read_data;	// Read from data memory
	
	reg  [7:0] addr_ins;	// Instruction memory address
	reg  [31:0] dati_ins;	// Data into instruction memory
	//wire [31:0] dato_ins;	// Data from instruction memory
	
	reg  [7:0] addr_data;	// Data memory address
	reg  [31:0] dati_data;	// Data into Data memory
	wire [31:0] dato_data;	// Data from Data memory
	
	//reg  [7:0] addr_reg;	// Register memory address
	//wire [31:0] dato_reg;	// Data from register memory
	
	wire	data_memfull;	// Data memory full flag
	wire	ins_memfull;	// Instruction memory full flag
	//wire	RAM_full;	// Reg memory full flag
	
	wire [31:0]	instruction;	// Instructions
	reg  [7:0]	address;	// Addresses
	
	integer tmp;		// Temporary integer for loop
	integer tmp1;		// Temporary integer for sum
	
	codes instrs (.instruction(instruction), .address(address));
	
	RISC_V_core comp0 (.clock(clock), .reset_n(reset_n), .mem_clr_n(mem_clr_n),
			   .write_ins(write_ins), //.read_ins(read_ins),
			   .write_data(write_data), .read_data(read_data),
			   .addr_ins(addr_ins), .dati_ins(dati_ins), //.dato_ins(dato_ins),
			   .addr_data(addr_data), .dati_data(dati_data), .dato_data(dato_data),
			   //.addr_reg(addr_reg), .dato_reg(dato_reg), .RAM_full(RAM_full),
			   .ins_memfull(ins_memfull), .data_memfull(data_memfull));
	
	initial begin
		clock = 1'b0;
		reset_n = 1'b0;
		mem_clr_n = 1'b0;
		
		write_ins = 1'b0;
		//read_ins = 1'b0;
		write_data = 1'b0;
		read_data = 1'b0;
		
		addr_ins = 8'd0;
		dati_ins = 32'd0;
		addr_data = 8'd0;
		dati_data = 32'd0;
		//addr_reg = 8'd0;
		
		tmp1 = 0;
	end
	
	always #1 clock <= ~clock;
	
	initial begin
		#2 mem_clr_n = 1'b1;		// Running the memory
		/*
		#2 write_ins = 1'b1;		// Instruction starts
		#2 addr_ins = 8'd0;					// Address
		#2 dati_ins = 32'b00000000000000000000011100010011;	// ADDI X14, X0, 0
		#2 addr_ins = 8'd4;					// Address
		#2 dati_ins = 32'b00000000101000000000011000010011;	// ADDI X12, X0, 1010
		
		#2 addr_ins = 8'd8;					// Address
		#2 dati_ins = 32'b00000000000100000000011010010011;	// ADDI X13, X0, 1
		#2 addr_ins = 8'd12;					// Address
		#2 dati_ins = 32'b00000000111001101000011100110011;	// ADD X14, X13, X14
		#2 addr_ins = 8'd16;					// Address
		#2 dati_ins = 32'b00000000000101101000011010010011;	// ADDI X13, X13, 1
		#2 addr_ins = 8'd20;					// Address
		#2 dati_ins = 32'b11111110110001101100110011100011;	// BLT X13, X12, 1111111111000
		#2 addr_ins = 8'd24;					// Address
		#2 dati_ins = 32'b11111101010001110000111100010011;	// ADDI X30, X14, 111111010100
		#2 addr_ins = 8'd28;					// Address
		#2 dati_ins = 32'b00000000000000000101000001100011;	// BGE X0, X0, 0
		
		#2 write_ins = 1'b0;		// Instruction ends
		*/
		
		#2 write_ins = 1'b1;		// Instruction starts
		for (tmp=0; tmp<58; tmp=tmp+1) begin
			#2 addr_ins = (tmp*4);
			address = tmp;
			#2 dati_ins = instruction;
		end
		#2 write_ins = 1'b0;		// Instruction ends
		
		#4 reset_n = 1'b1;		// CPU starts
		#500;				// Code ends
		/*
		$display("Data from register memory");
		for(tmp=0; tmp<32; tmp=tmp+1) begin
			#2 addr_reg = tmp;			// Address
			#2 $display(tmp, " : ", dato_reg);	// Data
			if ((tmp > 4) & (tmp < 31))
				tmp1 = tmp1 + dato_reg;
		end
		*/
		$display("Data from memory");
		#2 addr_data = 8'd8;		// Address
		#2 read_data = 1'b1;		// Data memory read
		#6 read_data = 1'b0;		// Data read end
		#2 $display(addr_data, " : ", dato_data);	// Data
		
		//if ((tmp1 == 26) && (dato_data == 21))
		if (dato_data == 21)
			$display("All tests are passed!!!");
		else
			$display("Test failed...");
		
		#2 $finish;
	end
	
	initial begin
		$dumpfile("RISC_V_tb.vcd");
		$dumpvars(0, RISC_V_tb);
		
		repeat(1000) @(posedge clock);
		$display("Monitor: Timeout; Test failed...");
		$finish;
	end
	
endmodule

`default_nettype wire

