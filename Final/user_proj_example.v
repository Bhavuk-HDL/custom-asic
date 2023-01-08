// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire [31:0] rdata; 
    wire [31:0] wdata;
    wire [BITS-1:0] count;

    wire valid;
    wire [3:0] wstrb;
    wire [31:0] la_write;

    // WB MI A
    assign valid = wbs_cyc_i && wbs_stb_i; 
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};
    assign wbs_dat_o = rdata;
    assign wdata = wbs_dat_i;

    // IO
    assign io_out = count;
    assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};

    // IRQ
    assign irq = 3'b000;	// Unused

    // LA
    assign la_data_out = {{(127-BITS){1'b0}}, count};
    // Assuming LA probes [63:32] are for controlling the count register  
    assign la_write = ~la_oenb[63:32] & ~{BITS{valid}};
    // Assuming LA probes [65:64] are for controlling the count clk & reset  
    assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
    assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;

	reg [127:0] la_data_out_reg;
	
	wire clock;		// System clock
	wire reset_n;	// System reset
	
	// ****************** //
	// UART ports
	reg	start_tx;		// Start the UART-Tx
	reg	start_rx;		// Start the UART-Rx
	reg [7:0] clk_ratio_uart;	// Ratio of clock to baudrate
	
	reg	fifo_wren_uart;		// Fifo write en
	reg	fifo_rden_uart;		// Fifo read en
	reg [7:0] data_in_uart;	// Data to the fifo
	wire [7:0] data_out_uart;	// Data from the fifo
	
	reg	parityen;		// 1 to enable parity bit
	reg	parityodd;		// 0 for odd parity; 1 for even parity;
	
	wire	busy_tx;		// UART_Tx working signal
	wire	busy_rx;		// UART_Rx working signal
	
	wire	data_fulltx;	// Tx fifo full flag
	wire	data_emptytx;	// Tx fifo empty flag
	
	wire	data_fullrx;	// Rx fifo full flag
	wire	data_emptyrx;	// Rx fifo empty flag
	// External ports
	wire	UART_Tx;		// Serial Interface Enable; Active low
	wire	UART_Rx;		// Serial Interface Clock
	
	// ****************** //
	// SPI ports
	reg		start_spi;		// Start the SPI comm.
	reg [7:0]	clk_ratio_spi;	// Ratio of clock to SCLK
	
	reg		fifo_wren_spi;	// Fifo write en
	reg [31:0]	data_in_spi;	// Data to the fifo
	
	wire		busy_spi;		// SPI working signal
	
	wire		data_full_spi;	// Fifo full flag
	wire		data_empty_spi;	// Fifo empty flag
	
	// External ports
	wire		SEN;	// Serial Interface Enable; Active low
	wire		SCLK;	// Serial Interface Clock
	wire		SDATA;	// Serial Interface Data
	
	// ****************** //
	// HACK comp ports
	reg	mem_clr_n_hc;	// Reset for memory
	
	reg	write_ins_hc;	// Write into instruction memory
	//reg	read_ins;	// Read from instruction memory
	reg	write_data_hc;	// Write into data memory
	reg	read_data_hc;	// Read from data memory
	
	reg [15:0] addr_ins_hc;	// Instruction memory address
	reg [15:0] dati_ins_hc;	// Data into instruction memory
	//wire  [15:0] dato_ins;	// Data from instruction memory
	
	reg [15:0] addr_data_hc;	// Data memory address
	reg [15:0] dati_data_hc;	// Data into Data memory
	wire [15:0] dato_data_hc;	// Data from Data memory
	
	wire	data_memfull_hc;	// Data memory full flag
	wire	ins_memfull_hc;	// Instruction memory full flag
	
	// ****************** //
	// RISC V ports
	reg 	mem_clr_n_rv;	// Reset for memory
	
	reg 	write_ins_rv;	// Write into instruction memory
	//reg 	read_ins;	// Read from instruction memory
	reg 	write_data_rv;	// Write into data memory
	reg 	read_data_rv;	// Read from data memory
	
	reg  [7:0] addr_ins_rv;	// Instruction memory address
	reg  [31:0] dati_ins_rv;	// Data into instruction memory
	//wire [31:0] dato_ins;	// Data from instruction memory
	
	reg  [7:0] addr_data_rv;	// Data memory address
	reg  [31:0] dati_data_rv;	// Data into Data memory
	wire [31:0] dato_data_rv;	// Data from Data memory
	
	//reg  [7:0] addr_reg;		// Register memory address
	//wire [31:0] dato_reg;	// Data from register memory
	
	wire	data_memfull_rv;	// Data memory full flag
	wire	ins_memfull_rv;		// Instruction memory full flag
	//wire	RAM_full;		// Reg memory full flag
	
	
	localparam [1:0]
		sys_uart	= 2'b00,
		sys_spi		= 2'b01,
		sys_hc		= 2'b10,
		sys_rv		= 2'b11;
		
	wire [1:0] sys_sel;
	
	UART_cntrl uart0 (`ifdef USE_POWER_PINS
					  .vccd1(vccd1),	// User area 1 1.8V power
					  .vssd1(vssd1),	// User area 1 digital ground
				      `endif
				      .clock(clock), .reset_n(reset_n),
					  .start_tx(start_tx), .start_rx(start_rx), .clk_ratio(clk_ratio_uart),
					  .fifo_wren(fifo_wren_uart), .fifo_rden(fifo_rden_uart),
					  .data_in(data_in_uart), .data_out(data_out_uart),
					  .parityen(parityen), .parityodd(parityodd),
					  .busy_tx(busy_tx), .busy_rx(busy_rx),
					  .data_fulltx(data_fulltx), .data_emptytx(data_emptytx),
					  .data_fullrx(data_fullrx), .data_emptyrx(data_emptyrx),
					  .UART_Tx(UART_Tx), .UART_Rx(UART_Rx)
					  );
	
	SPI_cntrl spi0 (`ifdef USE_POWER_PINS
					.vccd1(vccd1),	// User area 1 1.8V power
					.vssd1(vssd1),	// User area 1 digital ground
				    `endif
				    .clock(clock), .reset_n(reset_n), .start(start_spi),
			        .clk_ratio(clk_ratio_spi), .busy(busy_spi),
			        .fifo_wren(fifo_wren_spi), .data_in(data_in_spi),
			        .data_full(data_full_spi), .data_empty(data_empty_spi),
			        .SEN(SEN), .SCLK(SCLK), .SDATA(SDATA)
			        );
	
	HACK_comp hc0 (`ifdef USE_POWER_PINS
				   .vccd1(vccd1),	// User area 1 1.8V power
				   .vssd1(vssd1),	// User area 1 digital ground
				   `endif
				   .clock(clock), .reset_n(reset_n), .mem_clr_n(mem_clr_n_hc),
				   .write_ins(write_ins_hc), //.read_ins(read_ins),
				   .write_data(write_data_hc), .read_data(read_data_hc),
				   .addr_ins(addr_ins_hc), .dati_ins(dati_ins_hc),
				   //.dato_ins(dato_ins), 
				   .addr_data(addr_data_hc),
				   .dati_data(dati_data_hc), .dato_data(dato_data_hc),
				   .data_memfull(data_memfull_hc), .ins_memfull(ins_memfull_hc)
				   );
	
	RISC_V_core rv0 (`ifdef USE_POWER_PINS
					 .vccd1(vccd1),	// User area 1 1.8V power
					 .vssd1(vssd1),	// User area 1 digital ground
				     `endif
				     .clock(clock), .reset_n(reset_n), .mem_clr_n(mem_clr_n_rv),
				     .write_ins(write_ins_rv), //.read_ins(read_ins),
				     .write_data(write_data_rv), .read_data(read_data_rv),
				     .addr_ins(addr_ins_rv), .dati_ins(dati_ins_rv), //.dato_ins(dato_ins),
				     .addr_data(addr_data_rv), .dati_data(dati_data_rv), .dato_data(dato_data_rv),
				     //.addr_reg(addr_reg), .dato_reg(dato_reg), .RAM_full(RAM_full),
				     .ins_memfull(ins_memfull_rv), .data_memfull(data_memfull_rv)
				     );
	
	assign la_data_out = la_data_out_reg;
	
	assign clock = wb_clk_i;
	assign reset_n = (~wb_rst_i);
	
	assign UART_Rx = io_in[0];
	assign io_out[1] = UART_Tx;
	
	assign io_out[2] = SEN;
	assign io_out[3] = SCLK;
	assign io_out[4] = SDATA;
	
	assign io_oeb[0] = 1'b1;		// Input
	assign io_oeb[4:1] = 4'b1111;	// Output
	
	always @(*) begin
		case(sys_sel)
			sys_uart: begin
				// la_oenb[31:0]	= 32'hFFFFFFFF	// Input
				// la_oenb[63:32]	= 32'hFFFFFFFF	// Input
				// la_oenb[95:64]	= 32'h00000000	// Output
				// la_oenb[127:96]	= 32'h00000000	// Output
				start_tx		= la_data_in[44];
				start_rx		= la_data_in[45];
				clk_ratio_uart	= la_data_in[7:0];
				fifo_wren_uart	= la_data_in[40];
				fifo_rden_uart	= la_data_in[41];
				data_in_uart	= la_data_in[39:32];
				parityen		= la_data_in[8];
				parityodd		= la_data_in[9];
				la_data_out_reg[71:64]	= data_out_uart;
				la_data_out_reg[96]		= busy_tx;
				la_data_out_reg[97]		= busy_rx;
				la_data_out_reg[100]	= data_fulltx;
				la_data_out_reg[101]	= data_emptytx;
				la_data_out_reg[102]	= data_fullrx;
				la_data_out_reg[103]	= data_emptyrx;
			end
			sys_spi: begin
				// la_oenb[31:0]	= 32'hFFFFFFFF	// Input
				// la_oenb[63:32]	= 32'hFFFFFFFF	// Input
				// la_oenb[95:64]	= 32'h00000000	// Output
				// la_oenb[127:96]	= 32'h00000000	// Output
				start_spi		= la_data_in[8];
				clk_ratio_spi	= la_data_in[7:0];
				fifo_wren_spi	= la_data_in[9];
				data_in_spi		= la_data_in[63:32];
				la_data_out_reg[64]	= busy_spi;
				la_data_out_reg[68]	= data_full_spi;
				la_data_out_reg[69]	= data_empty_spi;
			end
			sys_hc: begin
				// la_oenb[31:0]	= 32'hFFFFFFFF	// Input
				// la_oenb[63:32]	= 32'hFFFFFFFF	// Input
				// la_oenb[95:64]	= 32'hFFFFFFFF	// Input
				// la_oenb[127:96]	= 32'h00000000	// Output
				mem_clr_n_hc 	= la_data_in[0];
				write_ins_hc 	= la_data_in[4];
				write_data_hc	= la_data_in[8];
				read_data_hc 	= la_data_in[12];
				addr_ins_hc 	= la_data_in[47:32];
				dati_ins_hc 	= la_data_in[63:48];
				addr_data_hc 	= la_data_in[79:64];
				dati_data_hc 	= la_data_in[95:80];
				la_data_out_reg[111:96]		= dato_data_hc;
				la_data_out_reg[116]		= data_memfull_hc;
				la_data_out_reg[120]		= ins_memfull_hc;
			end
			sys_rv: begin
				// la_oenb[31:0]	= 32'hFFFFFFFF	// Input
				// la_oenb[63:32]	= 32'hFFFFFFFF	// Input
				// la_oenb[95:64]	= 32'h00000000	// Output
				// la_oenb[127:96]	= 32'h00000000	// Output
				mem_clr_n_rv 	= la_data_in[0];
				write_ins_rv 	= la_data_in[4];
				write_data_rv 	= la_data_in[8];
				read_data_rv 	= la_data_in[12];
				addr_ins_rv 	= la_data_in[23:16];
				addr_data_rv 	= la_data_in[31:24];
				dati_ins_rv 	= write_ins_rv ? la_data_in[63:32] : 32'd0;
				dati_data_rv 	= write_data_rv ? la_data_in[63:32] : 32'd0;
				la_data_out_reg[95:64]		= dato_data_rv;
				la_data_out_reg[96] 		= ins_memfull_rv;
				la_data_out_reg[100]		= data_memfull_rv;
			end
		endcase
	end
	
endmodule

`default_nettype wire

