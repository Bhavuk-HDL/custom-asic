/////////////////////////////////////////////////////////
// This module is to create a SPI communication module //
// inside the project. This is a CPOL=0 & CPHA=0 mode. //
// Data bits and Address bits can be changed using     //
// parametes. Input to SPI clock ratio can also vary   //
// using CLK_RATIO (>=2). This is used only to send    //
// the data and not to receive it.                     //
/////////////////////////////////////////////////////////

`default_nettype none

// Main module for the SPI
module SPI #(
	parameter DATA_BITS = 16,
	parameter ADDR_BITS = 8,
	parameter CLK_RATIO = 8
		)(
	// Power pins
	`ifdef USE_POWER_PINS
	inout vccd1,				// User area 1 1.8V supply
	inout vssd1,				// User area 1 digital ground
	`endif
	// Internal ports
	input	wire			clk,
	input	wire			reset_n,
	input	wire			start,
	input	wire [ADDR_BITS - 1:0]	address,
	input	wire [DATA_BITS - 1:0]	data,
	input	wire [CLK_RATIO - 1:0]	ratio,	// Ratio of IPCLK to SCLK (>=2)
	output	reg			done_o,
	output	reg			busy,
	
	// External ports
	output	reg			SEN,	// Serial Interface Enable; Active low
	output	reg			SCLK,	// Serial Interface Clock
	output	reg			SDATA	// Serial Interface Data
	);

	reg [ADDR_BITS - 1:0] addr_wr;
	reg [DATA_BITS - 1:0] data_wr;

	reg [$clog2(CLK_RATIO - 1): 0] ratio_reg;

	reg [$clog2(CLK_RATIO - 1): 0] sclk_ind;
	reg [$clog2(DATA_BITS - 1): 0] data_ind;
	reg [$clog2(ADDR_BITS - 1): 0] addr_ind;

	reg clk_sig;

	// State machine
	reg [2:0] curr_wrk;
	localparam [2:0]
		idle		= 3'b000,
		start_spi	= 3'b001,
		address_spi	= 3'b010,
		data_spi	= 3'b011,
		stop		= 3'b100;
	
	initial begin
		done_o = 1'b0;
		busy = 1'b0;
		SEN = 1'b1;
		SCLK = 1'b1;
		SDATA = 1'b1;
		
		addr_wr = 0;
		data_wr = 0;
		ratio_reg = 0;
		sclk_ind = 0;
		data_ind = 0;
		addr_ind = 0;
		clk_sig = 1'b0;
		curr_wrk = 3'd0;
	end
	
	// State register
	always @(posedge clk, negedge reset_n)
	begin
		if (~reset_n)
			curr_wrk <= idle;
		else
		begin
			case(curr_wrk)
				idle:
				begin
					SEN <= 1'b1;
					SCLK <= 1'b1;
					SDATA <=  1'b1;
					
					ratio_reg <= CLK_RATIO - 1;
					
					sclk_ind <= CLK_RATIO - 1;
					addr_ind <= ADDR_BITS - 1;
					data_ind <= DATA_BITS - 1;
					
					addr_wr <= {ADDR_BITS{1'b0}};
					data_wr <= {DATA_BITS{1'b0}};
					
					done_o <= 1'b0;
					busy <= 1'b0;
					if (start)
					begin
						curr_wrk <= start_spi;
						
						ratio_reg <= ratio;
						
						sclk_ind <= ratio;
						
						addr_wr <= address;
						data_wr <= data;
						
						busy <= 1'b1;
					end
				end
				
				start_spi:
				begin
					SEN <= 1'b0;
					SCLK <= 1'b0;
					
					SDATA <= addr_wr[addr_ind];
					sclk_ind <= sclk_ind - 1;
					
					curr_wrk <= address_spi;
				end
				
				address_spi:
				begin
					sclk_ind <= sclk_ind - 1;
					if (sclk_ind == (ratio_reg >> 1))
					begin
						SCLK <= 1'b1;
						addr_ind <= addr_ind - 1;
						if (addr_ind == 0)
						begin
							curr_wrk <= data_spi;
						end
					end
					if (sclk_ind == 0)
					begin
						sclk_ind <= ratio - 1;
						SCLK <= 1'b0;
						SDATA <= addr_wr[addr_ind];
					end
				end
				
				data_spi:
				begin
					sclk_ind <= sclk_ind - 1;
					if (sclk_ind == (ratio_reg >> 1))
					begin
						SCLK <= 1'b1;
						data_ind <= data_ind - 1;
						if (data_ind == 0)
							curr_wrk <= stop;
					end
					if (sclk_ind == 0)
					begin
						sclk_ind <= ratio - 1;
						SCLK <= 1'b0;
						SDATA <= data_wr[data_ind];
					end
				end
				
				stop:
				begin
					sclk_ind <= sclk_ind - 1;
					if (sclk_ind == 0)
					begin
						SEN <= 1'b1;
						SCLK <= 1'b1;
						SDATA <= 1'b1;
						
						done_o <= 1'b1;
						curr_wrk <= idle;
					end
				end
				
				default:
				begin
					curr_wrk <= idle;
				end
			endcase
		end
	end
	
endmodule

`default_nettype wire
