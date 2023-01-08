/////////////////////////////////////////////////////////
// This module is to create a upper level control of   //
// the UART module. It is used to set the parameters   //
// of the module and also to attach the FIFO to it.    //
// FIFO is used to collect the data from user and to   //
// save it before forwarding to the UART. Similarly,   //
// another FIFO is used to save data from UART before  //
// forwarding to user.                                 //
/////////////////////////////////////////////////////////

`default_nettype none

// Main module for the UART_cntrl
module UART_cntrl (
	input	wire		clock,		// Main clock for module
	input	wire		reset_n,	// System reset
	
	input	wire		start_tx,	// Start the UART-Tx
	input	wire		start_rx,	// Start the UART-Rx
	input	wire [7:0]	clk_ratio,	// Ratio of clock to baudrate
	
	input	wire		fifo_wren,	// Fifo write en
	input	wire		fifo_rden,	// Fifo read en
	input	wire [7:0]	data_in,	// Data to the fifo
	output	wire [7:0]	data_out,	// Data from the fifo
	
	input wire		parityen,	// 1 to enable parity bit
	input wire		parityodd,	// 0 for odd parity; 1 for even parity;
	
	output reg		busy_tx,	// UART_Tx working signal
	output reg		busy_rx,	// UART_Rx working signal
	
	output wire		data_fulltx,	// Tx fifo full flag
	output wire		data_emptytx,	// Tx fifo empty flag
	
	output wire		data_fullrx,	// Rx fifo full flag
	output wire		data_emptyrx,	// Rx fifo empty flag
	// External ports
	output	wire		UART_Tx,	// UART Transmission port
	input	wire		UART_Rx	// UART Receiving port
	);
	
	wire fifo_fulltx;
	wire fifo_emptytx;
	
	wire fifo_fullrx;
	wire fifo_emptyrx;
	
	reg dataen_tx;
	reg tx_start;
	wire busytx;
	wire done_tx;
	reg prty_entx;
	reg prty_oddtx;
	wire [7:0] data_tx;
	
	reg dataen_rx;
	wire parity_err;
	reg rx_start;
	wire busyrx;
	wire done_rx;
	reg prty_enrx;
	reg prty_oddrx;
	wire [7:0] data_rx;
	reg [7:0] data_rxfifo;
	
	reg [1:0] curr_tx, curr_rx;
	localparam [1:0]
		idle_st	= 2'b00,
		read_st	= 2'b01,
		write_st	= 2'b10,
		stop_st	= 2'b11;
	
	Fifo #(.DATA_SIZE(8), .FIFO_SIZE(8))
	Fifo_tx (.clock(clock), .reset_n(reset_n),
	        .data_inen(fifo_wren), .data_outen(dataen_tx),
	        .fifo_empty(fifo_emptytx), .fifo_full(fifo_fulltx),
	        .data_in(data_in), .data_out(data_tx));
	       
	Fifo #(.DATA_SIZE(8), .FIFO_SIZE(8))
	Fifo_rx (.clock(clock), .reset_n(reset_n),
	        .data_inen(dataen_rx), .data_outen(fifo_rden),
	        .fifo_empty(fifo_emptyrx), .fifo_full(fifo_fullrx),
	        .data_in(data_rxfifo), .data_out(data_out));
	
	uart_tx #(.RATIO_REG_SIZE(8), .DATA_BITS(8))
	tx0	 (.clk(clock), .reset_n(reset_n), .ratio(clk_ratio),
		  .tx_enb(tx_start), .busy(busytx), .done(done_tx),
		  .data(data_tx), .parity_en(prty_entx), .parity_odd(prty_oddtx),
		  .UART_TX(UART_Tx));
	
	uart_rx #(.RATIO_REG_SIZE(8), .DATA_BITS(8))
	rx0	 (.clk(clock), .reset_n(reset_n), .ratio(clk_ratio),
		  .rx_enb(rx_start), .busy(busyrx), .new_data(done_rx),
		  .data(data_rx), .parity_en(prty_enrx), .parity_odd(prty_oddrx),
		  .parity_err(parity_err), .UART_RX(UART_Rx));
	
	assign data_fulltx = fifo_fulltx;
	assign data_emptytx = fifo_emptytx;
	
	assign data_fullrx = fifo_fullrx;
	assign data_emptyrx = fifo_emptyrx;
	
	initial begin
		busy_tx = 1'b0;
		busy_rx = 1'b0;
		dataen_tx = 1'b0;
		tx_start = 1'b0;
		prty_entx = 1'b0;
		prty_oddtx = 1'b0;
		dataen_rx = 1'b0;
		rx_start = 1'b0;
		prty_enrx = 1'b0;
		prty_oddrx = 1'b0;
		curr_tx = 2'b00;
		curr_rx = 2'b00;
		data_rxfifo = 8'd0;
	end
	
	always @(posedge clock , negedge reset_n) begin
		if (~reset_n) begin
			curr_tx = 2'b00;
			curr_rx = 2'b00;	
		end
		else begin
			case(curr_tx)
				idle_st: begin
					busy_tx	<= 1'b0;
					dataen_tx	<= 1'b0;
					tx_start	<= 1'b0;
					prty_entx	<= 1'b0;
					prty_oddtx	<= 1'b0;
					if ((start_tx) && (~fifo_emptytx)) begin
						prty_entx <= parityen;
						prty_oddtx <= parityodd;
						busy_tx <= 1'b1;
						curr_tx <= read_st;
					end
				end
				
				read_st: begin
					if (~busytx) begin
						dataen_tx <= 1'b1;
						curr_tx <= write_st;
					end
				end
				
				write_st: begin
					dataen_tx <= 1'b0;
					tx_start <= 1'b1;
					curr_tx <= stop_st;
				end
				
				stop_st: begin
					dataen_tx <= 1'b0;
					tx_start <= 1'b0;
					if (done_tx) begin
						if (fifo_emptytx)
							curr_tx <= idle_st;
						else
							curr_tx <= read_st;
					end
				end
			endcase
			case(curr_rx)
				idle_st: begin
					busy_rx	<= 1'b0;
					dataen_rx	<= 1'b0;
					rx_start	<= 1'b0;
					prty_enrx	<= 1'b0;
					prty_oddrx	<= 1'b0;
					data_rxfifo	<= 8'd0;
					if ((start_rx) && (~fifo_fullrx)) begin
						prty_enrx <= parityen;
						prty_oddrx <= parityodd;
						rx_start <= 1'b1;
						curr_rx <= read_st;
					end
				end
				
				read_st: begin
					if ((busyrx) && (done_rx)) begin
						if (~parity_err) begin
							dataen_rx <= 1'b1;
							data_rxfifo <= data_rx;
						end
						curr_rx <= write_st;
					end
					if (busyrx)
						busy_rx <= 1'b1;
					else
						busy_rx <= 1'b0;
				end
				
				write_st: begin
					dataen_rx <= 1'b0;
					busy_rx <= 1'b0;
					curr_rx <= stop_st;
				end
				
				stop_st: begin
					if ((start_rx) && (~fifo_fullrx))
						curr_rx <= read_st;
					else
						curr_rx <= idle_st;
				end
			endcase
		end
	end
	
endmodule

`default_nettype wire

