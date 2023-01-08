`default_nettype none

// Module for TX comm.
module uart_tx #(
	// Max. size of register
	parameter RATIO_REG_SIZE = 8,
	parameter DATA_BITS = 8
	)(
	// Power pins
	`ifdef USE_POWER_PINS
	inout vccd1,			// User area 1 1.8V supply
	inout vssd1,			// User area 1 digital ground
	`endif
	// Ports
	input wire			clk,
	input wire			reset_n,
	input wire [RATIO_REG_SIZE - 1:0]	ratio,
	
	input wire			tx_enb,
	output reg			busy,
	output reg			done,
	input wire [DATA_BITS - 1:0]	data,
	
	input wire			parity_en,	// 1 to enable parity bit
	input wire			parity_odd,	// 0 for odd parity; 1 for even parity;
	
	output reg			UART_TX
	);

	reg [RATIO_REG_SIZE - 1:0] 			prescaler;
	reg [RATIO_REG_SIZE - 1:0] 			ratio_reg;
	reg [($clog2(DATA_BITS + 2)) - 1:0]	index;
	reg [DATA_BITS + 2:0]			data_reg;	// start bit + data + parity + stop bit
	
	reg [1:0] curr_wrk;
	localparam
		idle = 1'b0,
		data_tx = 1'b1;
		
	initial
	begin
		curr_wrk = idle;
	end
	
	always @(posedge clk, posedge reset_n)
	begin
		if (~reset_n)
		begin
			prescaler <= {RATIO_REG_SIZE{1'b0}};
			ratio_reg <= {RATIO_REG_SIZE{1'b0}};
			data_reg <= {(DATA_BITS + 3){1'b0}};
			index <= {($clog2(DATA_BITS + 2)){1'b0}};
			busy <= 1'b0;
			done <= 1'b0;
			UART_TX <= 1'b1;
			curr_wrk <= idle;
		end
		else
		begin
			case(curr_wrk)
				idle:
				begin
					prescaler <= {RATIO_REG_SIZE{1'b0}};
					ratio_reg <= {RATIO_REG_SIZE{1'b0}};
					data_reg <= {(DATA_BITS + 3){1'b0}};
					index <= {($clog2(DATA_BITS + 2)){1'b0}};
					busy <= 1'b0;
					done <= 1'b0;
					UART_TX <= 1'b1;
					if (tx_enb)
					begin
						ratio_reg <= ratio;
						data_reg[0] <= 1'b0;	// Start bit
						data_reg[DATA_BITS:1] <= data;
						data_reg[DATA_BITS + 2] <= 1'b1;	// Stop bit
						if (parity_en)
						begin
							if (parity_odd)
								data_reg[DATA_BITS + 1] <= ~(^data);
							else
								data_reg[DATA_BITS + 1] <= ^data;
						end
						else
						data_reg[DATA_BITS + 1] <= 1'b1;	// Stop bit
						
						busy <= 1'b1;
						curr_wrk <= data_tx;
					end
				end
				
				data_tx:
				begin
					if (prescaler < (ratio_reg - 1))
						prescaler <= prescaler + 1;
					else
						prescaler <= 1'b0;
					if (prescaler == (ratio_reg >> 1))
					begin
						if (index < (DATA_BITS + 3))
						begin
							UART_TX <= data_reg[index];
							index <= index + 1;
							if ((~parity_en) & (index == DATA_BITS + 1)) begin
								done <= 1'b1;
								curr_wrk <= idle;
							end
						end
						else
						begin
							done <= 1'b1;
							curr_wrk <= idle;
						end
					end
				end
			
			endcase
		end
	end

endmodule

`default_nettype wire

