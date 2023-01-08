`default_nettype none

// Module for RX comm.
module uart_rx #(
	// Max. size of register
	parameter RATIO_REG_SIZE = 8,
	parameter DATA_BITS = 8
	)(
	input wire			clk,
	input wire			reset_n,
	input wire [RATIO_REG_SIZE - 1:0]	ratio,
	
	input wire			rx_enb,
	output reg			busy,
	output reg			new_data,
	output reg [DATA_BITS - 1:0]	data,
	
	input wire			parity_en,	// 1 to enable parity bit
	input wire			parity_odd,	// 0 for odd parity; 1 for even parity;
	output reg			parity_err,	// 1 for error in parity
	
	input wire			UART_RX
	);

	reg [RATIO_REG_SIZE - 1:0] 			prescaler;
	reg [RATIO_REG_SIZE - 1:0] 			ratio_reg;
	reg [($clog2(DATA_BITS + 2)) - 1:0]	index;
	reg [DATA_BITS + 2:0]			data_reg;	// start bit + data + parity + stop bit
	
	reg [1:0] curr_wrk;
	localparam [1:0]
		idle = 2'b00,
		data_rx = 2'b01,
		verify_st = 2'b10;
		
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
			new_data <= 1'b0;
			data = {DATA_BITS{1'b0}};
			parity_err = 1'b0;
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
					new_data <= 1'b0;
					//data = {DATA_BITS{1'b0}};
					parity_err = 1'b0;
					if ((~UART_RX) & (rx_enb))
					begin
						ratio_reg <= ratio;
						busy <= 1'b1;
						curr_wrk <= data_rx;
					end
				end
				
				data_rx:
				begin
					if (prescaler < (ratio_reg - 1))
						prescaler <= prescaler + 1;
					else
						prescaler <= 1'b0;
					if (prescaler == (ratio_reg >> 1))
					begin
						if (index < (DATA_BITS + 3))
						begin
							data_reg[index] <= UART_RX;
							index <= index + 1;
							if ((~parity_en) & (index == DATA_BITS + 1))
							begin
								if (UART_RX)
									curr_wrk <= verify_st;
								else
									curr_wrk <= idle;
							end
						end
						else
						begin
							if (UART_RX)
								curr_wrk <= verify_st;
							else
								curr_wrk <= idle;
						end
					end
				end
				
				verify_st:
				begin
					data <= data_reg[DATA_BITS:1];
					if (parity_en)
					begin
						if (parity_odd)
							parity_err = (data_reg[DATA_BITS + 1] == ~(^data_reg[DATA_BITS:1])) ? 1'b0 : 1'b1 ;
						else
							parity_err = (data_reg[DATA_BITS + 1] == (^data_reg[DATA_BITS:1])) ? 1'b0 : 1'b1 ;
					end
					new_data <= 1'b1;
					curr_wrk <= idle;
				end
				
				default:
					curr_wrk <= idle;
			endcase
		end
	end

endmodule

`default_nettype wire
