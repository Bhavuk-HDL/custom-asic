/////////////////////////////////////////////////////////
// This module is to create a upper level control of   //
// the SPI module. It is used to set the parameters of //
// the module and also to attach the FIFO to it. FIFO  //
// is used to collect the data from user and to save   //
// it before forwarding to the SPI.                    //
/////////////////////////////////////////////////////////

`default_nettype none

// Main module for the SPI_cntrl
module SPI_cntrl (
	// Power pins
	`ifdef USE_POWER_PINS
	inout vccd1,				// User area 1 1.8V supply
	inout vssd1,				// User area 1 digital ground
	`endif
	// Ports
	input	wire		clock,		// Main clock for module
	input	wire		reset_n,	// System reset
	
	input	wire		start,		// Start the SPI comm.
	input	wire [7:0]	clk_ratio,	// Ratio of clock to SCLK
	
	input	wire		fifo_wren,	// Fifo write en
	input	wire [31:0]	data_in,	// Data to the fifo
	
	output reg		busy,		// SPI working signal
	
	output wire		data_full,	// Fifo full flag
	output wire		data_empty,	// Fifo empty flag
	
	// External ports
	output	wire			SEN,	// Serial Interface Enable; Active low
	output	wire			SCLK,	// Serial Interface Clock
	output	wire			SDATA	// Serial Interface Data
	);
	
	wire [31:0] spi_data;
	
	reg	spi_dataen;
	
	wire	fifo_empty;
	wire	fifo_full;
	
	reg	spi_start;
	wire	spi_done;
	wire	spi_busy;
	
	reg [1:0] curr_st;
	localparam [1:0]
		idle_st	= 2'b00,
		read_st	= 2'b01,
		write_st	= 2'b10,
		stop_st	= 2'b11;
	
	SPI #(.DATA_BITS(16), .ADDR_BITS(8), .CLK_RATIO(8))
	SPI0 (`ifdef USE_POWER_PINS
	      .vccd1(vccd1),	// User area 1 1.8V power
	      .vssd1(vssd1),	// User area 1 digital ground
	      `endif
	      .clk(clock), .reset_n(reset_n), .start(spi_start),
	      .address(spi_data[7:0]), .data(spi_data[23:8]), .ratio(clk_ratio),
	      .done_o(spi_done), .busy(spi_busy),
	      .SEN(SEN), .SCLK(SCLK), .SDATA(SDATA));
	
	Fifo #(.DATA_SIZE(32), .FIFO_SIZE(8))
	Fifo0 (`ifdef USE_POWER_PINS
	       .vccd1(vccd1),	// User area 1 1.8V power
	       .vssd1(vssd1),	// User area 1 digital ground
	       `endif
	       .clock(clock), .reset_n(reset_n),
	       .data_inen(fifo_wren), .data_outen(spi_dataen),
	       .fifo_empty(fifo_empty), .fifo_full(fifo_full),
	       .data_in(data_in), .data_out(spi_data));
	
	assign data_full = fifo_full;
	assign data_empty = fifo_empty;
	
	initial begin
		busy = 1'b0;
		spi_dataen = 1'b0;
		spi_start = 1'b0;
		curr_st = 2'b00;
	end
	
	always @(posedge clock , negedge reset_n) begin
		if (~reset_n) begin
			curr_st = 2'b00;
		end
		else begin
			case(curr_st)
				idle_st: begin
					busy		<= 1'b0;
					spi_dataen	<= 1'b0;
					spi_start	<= 1'b0;
					if ((start) && (~fifo_empty)) begin
						busy <= 1'b1;
						curr_st <= read_st;
					end
				end
				
				read_st: begin
					if (~spi_busy) begin
						spi_dataen <= 1'b1;
						curr_st <= write_st;
					end
				end
				
				write_st: begin
					spi_dataen <= 1'b0;
					spi_start <= 1'b1;
					curr_st <= stop_st;
				end
				
				stop_st: begin
					spi_dataen <= 1'b0;
					spi_start <= 1'b0;
					if (spi_done) begin
						if (fifo_empty)
							curr_st <= idle_st;
						else
							curr_st <= read_st;
					end
				end
			endcase
		end
	end
	
endmodule

`default_nettype wire

