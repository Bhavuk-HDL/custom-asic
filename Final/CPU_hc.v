/////////////////////////////////////////////////////////
// This module is to create the CPU of the computer.   //
// The CPU takes in instruction and compute it using   //
// ALU, registers, program counter, memory and finally //
// takes the resultant data to it's desired location.  //
/////////////////////////////////////////////////////////

`default_nettype none

// Main module for CPU
module CPU_hc(
	// Power pins
	`ifdef USE_POWER_PINS
	inout vccd1,				// User area 1 1.8V supply
	inout vssd1,				// User area 1 digital ground
	`endif
	// Ports
	input wire		clock,		// Main input clock
	input wire		reset_n,	// Main reset_n
	 
	input wire	[15:0]	inM,		// Input from memory
	input wire	[15:0]	instruction,	// Input instruction
	 
	output wire	[15:0]	outM,		// Output from memory
	output wire		writeM,	// Write to memory flag
	output wire	[14:0]	addressM,	// Memory address
	
	output wire	[14:0]	pc		// Output of program counter
	);
	
	wire [15:0] ALUOP;
	wire [15:0] AR;
	wire [15:0] ALU0;
	wire        zr;
	wire        ng;
	wire        loadnot;

	wire        ins15not;
	wire        aload0;
	wire        aload;
	wire        dload;
	wire        muxsel;
	wire [15:0] Aregister;
	wire [15:0] ALU1;

	wire        j3not;
	wire        j2not;
	wire        j1not;
	wire        zrnot;
	wire        ngnot;

	wire        j1j2;
	wire        j315;
	wire        inc0;
	wire        incre0;
	wire        inc;

	wire        le0;
	wire        l0;
	wire        l1;
	wire        g0;
	wire        j1notj3;
	wire        l2;
	wire        j1j3;
	wire        l3;
	wire        jmp0;
	wire        jmp1;
	wire        l4;

	wire        jmpcon0;
	wire        jmpcon1;
	wire        jmpcon;

	wire        load0;
	wire        load;

	wire [15:0] pctmp;
	
	
	assign  ins15not   = ~instruction[15];
	assign  aload0     = instruction[15] & instruction[5];
	assign  aload      = aload0 | ins15not;
	assign  dload      = instruction[15] & instruction[4];
	assign  muxsel     = instruction[15] & instruction[12];
	assign  writeM     = instruction[15] & instruction[3];
	assign  Aregister  = instruction[15] ? ALUOP : instruction;
	assign  ALU1       = muxsel ? inM : AR;
	assign  addressM   = AR[14:0];
	assign  outM       = ALUOP;
	
	assign  j3not      = ~instruction[0];
	assign  j2not      = ~instruction[1];
	assign  j1not      = ~instruction[2];
	assign  zrnot      = ~zr;
	assign  ngnot      = ~ng;

	assign  j1j2       = j1not & j2not;
	assign  j315       = j3not & instruction[15];
	assign  inc0       = j1j2 & j315;
	assign  incre0     = inc0 | ins15not;
	assign  inc        = incre0 | loadnot;		// PC inc

	assign  le0        = instruction[2] & ng;
	assign  l0         = le0 & j3not;			// OP < 0

	assign  l1         = zr & instruction[1];		// OP == 0

	assign  g0         = zrnot & ngnot;
	assign  j1notj3    = j1not & instruction[0];
	assign  l2         = j1notj3 & g0;			// OP > 0

	assign  j1j3       = instruction[2] & instruction[0];
	assign  l3         = j1j3 & zrnot;			// OP != 0

	assign  jmp0       = instruction[15] & instruction[2];
	assign  jmp1       = instruction[1] & instruction[0];
	assign  l4         = jmp0 & jmp1;			// JMP

	assign  jmpcon0    = instruction[0] | instruction[1];
	assign  jmpcon1    = jmpcon0 | instruction[2];
	assign  jmpcon     = jmpcon1 & instruction[15];

	assign  load0      = l0 | l1 | l2 | l3 | l4;
	assign  load       = load0 & jmpcon;
	assign  loadnot    = ~load;
	
	assign pc          = pctmp[14:0];

	Register_hc ARegister (
				`ifdef USE_POWER_PINS
				.vccd1(vccd1),	// User area 1 1.8V power
				.vssd1(vssd1),	// User area 1 digital ground
				`endif
				.clock(clock), .in(Aregister), 
			       .load(aload), .out(AR));
	Register_hc DRegister (`ifdef USE_POWER_PINS
				.vccd1(vccd1),	// User area 1 1.8V power
				.vssd1(vssd1),	// User area 1 digital ground
				`endif
				.clock(clock), .in(ALUOP), 
			       .load(dload), .out(ALU0));
	ALU_hc	 ALU       (`ifdef USE_POWER_PINS
			    .vccd1(vccd1),	// User area 1 1.8V power
			    .vssd1(vssd1),	// User area 1 digital ground
			    `endif
			    .x(ALU0), .y(ALU1), 
			    .zx(instruction[11]), .nx(instruction[10]), 
			    .zy(instruction[9]), .ny(instruction[8]), 
			    .f(instruction[7]), .no(instruction[6]), 
			    .zr(zr), .ng(ng), .out(ALUOP));
	Program_counter_hc PC0 (`ifdef USE_POWER_PINS
				.vccd1(vccd1),	// User area 1 1.8V power
				.vssd1(vssd1),	// User area 1 digital ground
				`endif
				.clock(clock), .reset_n(reset_n), .in(AR), 
			        .load(load), .inc(inc), .out(pctmp));


endmodule

`default_nettype wire

