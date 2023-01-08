/////////////////////////////////////////////////////////
// This module is to create the ALU of the computer.   //
// The ALU takes two variables x and y, along with six //
// operations to produce output and two flags.         //
/////////////////////////////////////////////////////////

`default_nettype none

// Main module for ALU
module ALU_hc(
	// Power pins
	`ifdef USE_POWER_PINS
	inout vccd1,			// User area 1 1.8V supply
	inout vssd1,			// User area 1 digital ground
	`endif
	// Ports
	 input wire	[15:0]    x,	// Variable x
	 input wire	[15:0]    y,	// Variable y
	 
	 input wire              zx,	// zero the x input?
	 input wire              nx,	// negate the x input?
	 input wire              zy,	// zero the y input?
	 input wire              ny,	// negate the y input?
	 input wire              f,	// compute out = f ? (x + y) : (x & y)
	 input wire              no,	// negate the out output?
	 
	 output wire	[15:0]    out,	// Result out
	 
	 output wire             zr,	// 1 iff out == 0
	 output wire             ng	// 1 iff out < 0
	);

	wire [15:0] x1;
	wire [15:0] x1not;
	wire [15:0] x2;
	wire [15:0] y1;
	wire [15:0] y1not;
	wire [15:0] y2;
	wire [15:0] sum;
	wire [15:0] x2andy2;
	wire [15:0] out0;
	wire [15:0] out0not;
	wire [15:0] outtmp;

	wire        outor0;
	wire        outor1;
	wire        outor;

	assign x1      = zx ? 16'd0 : x;
	assign x1not   = ~x1;
	assign x2      = nx ? x1not : x1;
	assign y1      = zy ? 16'd0 : y;
	assign y1not   = ~y1;
	assign y2      = ny ? y1not : y1;
	assign sum     = x2 + y2;
	assign x2andy2 = x2 & y2;
	assign out0    = f ? sum : x2andy2;
	assign out0not = ~out0;
	assign out     = no ? out0not : out0;
	assign outtmp  = out;

	assign outor0  = |outtmp[7:0];
	assign outor1  = |outtmp[15:8];
	assign outor   = outor0 | outor1;
	assign zr      = ~outor;
	assign ng      = outtmp[15] | 1'b0;

endmodule

`default_nettype wire

