/////////////////////////////////////////////////////////
// This module is the top module of RISC V CORE.       //
// Here all the core parts are developed and then      //
// integrated. Three memories are used, one for data,  //
// one for instructions, and one for register memory.  //
/////////////////////////////////////////////////////////

`default_nettype none

// Main module for RISC_V
module RISC_V_core(
	// Power pins
	`ifdef USE_POWER_PINS
	inout vccd1,			// User area 1 1.8V supply
	inout vssd1,			// User area 1 digital ground
	`endif
	// Ports
	input wire clock,		// Main clock for the system
	input wire reset_n,		// Main reset for the system
	input wire mem_clr_n,		// Reset for memory
	
	input wire	write_ins,	// Write into instruction memory
	//input wire	read_ins,	// Read from instruction memory
	input wire	write_data,	// Write into data memory
	input wire	read_data,	// Read from data memory
	
	input wire  [7:0] addr_ins,	// Instruction memory address
	input wire  [31:0] dati_ins,	// Data into instruction memory
	//output wire [31:0] dato_ins,	// Data from instruction memory
	
	input wire  [7:0] addr_data,	// Data memory address
	input wire  [31:0] dati_data,	// Data into Data memory
	output wire [31:0] dato_data,	// Data from Data memory
	
	//input wire  [7:0] addr_reg,	// Register memory address
	//output wire [31:0] dato_reg,	// Data from register memory
	
	output wire	data_memfull,	// Data memory full flag
	output wire	ins_memfull	// Instruction memory full flag
	//output wire 	RAM_full	// Reg memory full flag
	);

	wire [31:0] next_pc;
	reg [31:0] pc;
	reg clock_hf;
	reg clock_pc;

	wire [31:0] instr;

	wire [6:0] opcode;
	wire [4:0] opcode0;
	wire [2:0] funct3;
	wire [4:0] rs1;
	wire [4:0] rs2;
	wire [4:0] rd;
	wire [6:0] funct7;
	wire [31:0] imm;
	wire opcode_valid;
	wire funct3_valid;
	wire rs1_valid;
	wire rs2_valid;
	wire rd_valid;
	wire funct7_valid;
	wire imm_valid;

	wire [10:0] dec_bits;
	wire [9:0] dec_bits0;

	wire is_u_instr;
	wire is_i_instr;
	wire is_s_instr;
	wire is_r_instr;
	wire is_j_instr;
	wire is_b_instr;
	wire is_r4_instr;

	wire is_lui;
	wire is_auipc;
	wire is_jal;
	wire is_load;
	wire is_store;
	wire is_jalr;
	wire is_beq;
	wire is_bne;
	wire is_blt;
	wire is_bge;
	wire is_bltu;
	wire is_bgeu;
	wire is_addi;
	wire is_slti;
	wire is_sltiu;
	wire is_xori;
	wire is_ori;
	wire is_andi;
	wire is_slli;
	wire is_srli;
	wire is_srai;
	wire is_add;
	wire is_sub;
	wire is_sll;
	wire is_slt;
	wire is_sltu;
	wire is_xor;
	wire is_srl;
	wire is_sra;
	wire is_or;
	wire is_and;

	wire reg_wr_en;
	wire [31:0] reg_wr_data;
	wire [31:0] src1_value;
	wire [31:0] src2_value;

	wire [31:0] sltu_rslt;
	wire [31:0] sltiu_rslt;
	wire [63:0] sext_src1;
	wire [63:0] sra_rslt;
	wire [63:0] srai_rslt;


	wire [31:0] result;

	wire taken_br;
	wire [31:0] br_tgt_pc;

	wire [31:0] jalr_tgt_pc;

	wire [31:0] ld_data;

	// Instruction memory ports
	wire inst_rden;
	wire inst_wren;
	wire [31:0] inst_in;
	wire [31:0] inst_out;
	wire [7:0] insi_addr;
	wire [7:0] inso_addr;

	// Data memory ports
	wire data_rden;
	wire data_wren;
	wire [31:0] data_in;
	wire [31:0] data_out;
	wire [7:0] dati_addr;
	wire [7:0] dato_addr;
		

	// Program counter
	// Evaluates pc and next_pc
	assign next_pc = (~reset_n) ? 32'd0 : 
			  taken_br ? br_tgt_pc :
			  is_jal ? br_tgt_pc :
			  is_jalr ? jalr_tgt_pc :
			  (pc + 32'd4);	// Default
	
	always @(posedge clock, reset_n) begin
		if (~reset_n)
			clock_hf <= 1'b0;		// Reset to 0
		else
			clock_hf <= (~clock_hf);	// Half rate to clock
	end
	
	always @(posedge clock_hf, reset_n) begin
		if (~reset_n)
			clock_pc <= 1'b0;		// Reset to 0
		else
			clock_pc <= (~clock_pc);	// Half rate to clock_hf
	end
	
	always @(posedge clock_pc, reset_n) begin
		if (~reset_n)
			pc <= 32'd0;		// Reset to 0
		else
			pc <= next_pc;		// Registering value
	end

	// Instruction memory
	/*
	`READONLY_MEM(.addr(pc), .read_data(instr));
	*/

	SRAM #(.DATA_SIZE(32), .SRAM_DEPTH_LOG2(8))
	ins_mem0 (`ifdef USE_POWER_PINS
		  .vccd1(vccd1),	// User area 1 1.8V power
		  .vssd1(vssd1),	// User area 1 digital ground
		  `endif
		  .clock(clock), .reset_n(mem_clr_n),
		  .data_rden(inst_rden), .data_wren(inst_wren),
		  .data_in(inst_in), .data_out(inst_out),
		  .addr_in(insi_addr), .addr_out(inso_addr),
		  .sram_full(ins_memfull));

	assign inst_rden = 1'b1;
	assign inst_wren = write_ins ? 1'b1 : 1'b0;
	assign insi_addr = addr_ins;
	assign inso_addr = pc[7:0];
	//assign inso_addr = read_ins ? addr_ins : pc[7:0];
	assign inst_in = dati_ins;
	assign instr = inst_out;
	//assign dato_ins = inst_out;

	// Decoding logic
	// Takes the instruction from Instruction memory and decodes it
	// Opcode decoding
	assign opcode = instr[6:0];
	assign opcode0 = instr[6:2];
	assign opcode_valid = (instr[1:0] == 2'b11);
	assign is_u_instr = (opcode0 == 5'b00101) || 
			     (opcode0 == 5'b01101);
	assign is_i_instr = (opcode0 == 5'b00000) ||
			     (opcode0 == 5'b00001) ||
			     (opcode0 == 5'b00100) ||
			     (opcode0 == 5'b00110) ||
			     (opcode0 == 5'b11001) ||
			     (opcode0 == 5'b11100);	// Not used in this case
	assign is_s_instr = (opcode0 == 5'b01000) ||
			     (opcode0 == 5'b01001);
	assign is_r_instr = (opcode0 == 5'b01011) ||
			     (opcode0 == 5'b01100) ||
			     (opcode0 == 5'b01110) ||
			     (opcode0 == 5'b10100);
	assign is_j_instr = (opcode0 == 5'b11011);
	assign is_b_instr = (opcode0 == 5'b11000);
	//assign is_r4_instr = (instr[6:5] == 3'100);	// Not used in this case

	// funct3 decoding
	assign funct3 = instr[14:12];
	assign funct3_valid = is_r_instr || is_i_instr ||
						  is_s_instr || is_b_instr;

	// rs1 decoding (OP1 for ALU)
	assign rs1 = instr[19:15];
	assign rs1_valid = is_r_instr || is_i_instr ||
					   is_s_instr || is_b_instr;

	// rs2  decoding (OP2 for ALU)
	assign rs2 = instr[24:20];
	assign rs2_valid = is_r_instr || is_s_instr ||
					   is_b_instr;

	// rd decoding (Destination reg addr)
	assign rd = instr[11:7];
	assign rd_valid = is_r_instr || is_i_instr ||
					  is_u_instr || is_j_instr;

	// funct7 decoding
	assign funct7 = instr[31:25];
	assign funct7_valid = is_r_instr;

	// immediate decoding
	assign imm = is_i_instr ? {{21{instr[31]}}, instr[30:20]} :
		     is_s_instr ? {{21{instr[31]}}, instr[30:25], instr[11:7]} :
		     is_b_instr ? {{20{instr[31]}}, instr[7],  instr[30:25], instr[11:8], 1'b0} :
		     is_u_instr ? {instr[31], instr[30:12], {12{1'b0}}} :
		     is_j_instr ? {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0} :
		     32'd0;		// Default
	assign imm_valid = is_i_instr || is_s_instr ||
					   is_b_instr || is_u_instr ||
					   is_j_instr;

	// Instruction decoding
	assign dec_bits = {instr[30], funct3, opcode};
	assign dec_bits0 = {funct3, opcode};
	assign is_lui = 	(opcode == 7'b0110111);
	assign is_auipc = 	(opcode == 7'b0010111);
	assign is_jal = 	(opcode == 7'b1101111);
	assign is_load = 	(opcode == 7'b0000011);
	assign is_store = 	(opcode == 7'b0100011);
	assign is_jalr = 	(dec_bits0 == 10'b000_1100111);
	assign is_beq = 	(dec_bits0 == 10'b000_1100011);
	assign is_bne = 	(dec_bits0 == 10'b001_1100011);
	assign is_blt = 	(dec_bits0 == 10'b100_1100011);
	assign is_bge = 	(dec_bits0 == 10'b101_1100011);
	assign is_bltu = 	(dec_bits0 == 10'b110_1100011);
	assign is_bgeu = 	(dec_bits0 == 10'b111_1100011);
	assign is_addi = 	(dec_bits0 == 10'b000_0010011);
	assign is_slti = 	(dec_bits0 == 10'b010_0010011);
	assign is_sltiu = 	(dec_bits0 == 10'b011_0010011);
	assign is_xori = 	(dec_bits0 == 10'b100_0010011);
	assign is_ori = 	(dec_bits0 == 10'b110_0010011);
	assign is_andi = 	(dec_bits0 == 10'b111_0010011);
	assign is_slli = 	(dec_bits == 11'b0_001_0010011);
	assign is_srli = 	(dec_bits == 11'b0_101_0010011);
	assign is_srai = 	(dec_bits == 11'b1_101_0010011);
	assign is_add = 	(dec_bits == 11'b0_000_0110011);
	assign is_sub = 	(dec_bits == 11'b1_000_0110011);
	assign is_sll = 	(dec_bits == 11'b0_001_0110011);
	assign is_slt = 	(dec_bits == 11'b0_010_0110011);
	assign is_sltu = 	(dec_bits == 11'b0_011_0110011);
	assign is_xor = 	(dec_bits == 11'b0_100_0110011);
	assign is_srl = 	(dec_bits == 11'b0_101_0110011);
	assign is_sra = 	(dec_bits == 11'b1_101_0110011);
	assign is_or = 	(dec_bits == 11'b0_110_0110011);
	assign is_and = 	(dec_bits == 11'b0_111_0110011);

	// Register memory
	// Memory have 32 addresses each having 32 bits
	// 2-read, 1-write register file
	/*
	`REG_MEM(.reset_n(reset_n), .wr_en(reg_wr_en),
			 .wr_index(rd), .wr_data(reg_wr_data),
			 .rd_en1(rs1_valid), rd_index1(rs1),
			 .rd_en2(rs2_valid), .rd_index2(rs2),
			 .rd_data1(src1_value), rd_data2(src2_value));
	*/
	
	RAM_2R2W #(.DATA_SIZE(32), .RAM_DEPTH_LOG2(5))
	reg_mem0 (`ifdef USE_POWER_PINS
		  .vccd1(vccd1),	// User area 1 1.8V power
		  .vssd1(vssd1),	// User area 1 digital ground
		  `endif
		  .clock(clock_hf), .reset_n(mem_clr_n),
		  .data_rden1(rs1_valid), .data_wren1(reg_wr_en),
		  .data_rden2(rs2_valid), .data_wren2(1'b0),
		  .data_in1(reg_wr_data), .data_in2(32'd0),
		  .data_out1(src1_value), .data_out2(src2_value),
		  .addr_in1rd(rs1), .addr_in2rd(rs2),
		  .addr_in1wr(rd), .addr_in2wr(5'd0),
		  //.addr_test(addr_reg[4:0]), .data_test(dato_reg),
		  //.RAM_full(RAM_full)
		  .RAM_full());

	assign reg_wr_en = (rd == 5'd0) ? 1'b0 : rd_valid;

	// Arithmetic logic unit (ALU)
	// Takes two inputs and produces one result based on the control signals
	// Subexpressions for ALU
	assign sltu_rslt = {31'b0, src1_value < src2_value};
	assign sltiu_rslt = {31'b0, src1_value < imm};
	assign sext_src1 = {{32{src1_value[31]}}, src1_value};
	assign sra_rslt = sext_src1 >> src2_value[4:0];
	assign srai_rslt = sext_src1 >> imm[4:0];

	assign result = is_andi ? (src1_value & imm) :
			is_ori ? (src1_value | imm) :
			is_xori ? (src1_value ^ imm) :
			is_addi ? (src1_value + imm) :
			is_slli ? (src1_value << imm[5:0]) :
			is_srli ? (src1_value >> imm[5:0]) :
			is_and ? (src1_value & src2_value) :
			is_or ? (src1_value | src2_value) :
			is_xor ? (src1_value ^ src2_value) :
			is_add ? (src1_value + src2_value) :
			is_sub ? (src1_value - src2_value) :
			is_sll ? (src1_value << src2_value[4:0]) :
			is_srl ? (src1_value >> src2_value[4:0]) :
			is_sltu ? sltu_rslt :
			is_sltiu ? sltiu_rslt :
			is_lui ? {imm[31:12], 12'b0} :
			is_auipc ? (pc + imm) :
			is_jal ? (pc + 32'd4) :
			is_jalr ? (pc + 32'd4) :
			is_slt ? ((src1_value[31] == src2_value[31]) ? sltu_rslt :
				 {31'b0, src1_value[31]}) :
			is_slti ? ((src1_value[31] == imm[31]) ? sltiu_rslt :
				 {31'b0, src1_value[31]}) :
			is_sra ? sra_rslt[31:0] :
			is_srai ? srai_rslt :
			is_load ? (src1_value + imm) :
			is_s_instr ? (src1_value + imm) :
			32'd0;	// Default

	// Branch logic
	// Logic for conditional branching
	assign taken_br = is_beq ? (src1_value == src2_value) :	// Branch if equal
			  is_bne ? (src1_value != src2_value) :	// Branch if not equal
			  is_blt ? ((src1_value < src2_value) ^ (src1_value[31] != src2_value[31])) :	// Branch if less than
			  is_bge ? ((src1_value >= src2_value) ^ (src1_value[31] != src2_value[31])) :	// Branch if greater than or equal
			  is_bltu ? (src1_value < src2_value) :	// Branch if less than unsigned
			  is_bgeu ? (src1_value >= src2_value) :	// Branch if greater than or equal unsigned
			  1'b0;		// Default

	assign br_tgt_pc = pc + imm;

	// Logic for unconditional branching (jump)
	assign jalr_tgt_pc = src1_value + imm;


	// Logic for data memory
	// Data memory is of 8KB
	/*
	`DATA_MEM(.reset_n(reset_n), .addr(result),
			 .wr_en(is_s_instr), .wr_data(src2_value),
			 .rd_en(is_load), rd_data(ld_data));
	*/

	assign data_rden = read_data ? 1'b1 : is_load;
	assign data_wren = write_data ? 1'b1 : is_s_instr;
	assign dati_addr = write_data ? addr_data[7:0] : result[7:0];
	assign dato_addr = read_data ? addr_data[7:0] : result[7:0];
	assign data_in = write_data ? dati_data : src2_value;
	assign dato_data = data_out;
	assign ld_data = data_out;

	SRAM #(.DATA_SIZE(32), .SRAM_DEPTH_LOG2(8))
	dat_mem0 (`ifdef USE_POWER_PINS
		  .vccd1(vccd1),	// User area 1 1.8V power
		  .vssd1(vssd1),	// User area 1 digital ground
		  `endif
		  .clock(clock_hf), .reset_n(mem_clr_n),
		  .data_rden(data_rden), .data_wren(data_wren),
		  .data_in(data_in), .data_out(data_out),
		  .addr_in(dati_addr), .addr_out(dato_addr),
		  .sram_full(data_memfull));

	assign reg_wr_data = is_load ? ld_data : result;

endmodule

`default_nettype wire

