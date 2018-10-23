//Written by Zhang zhekai
//Modified by Bohan Hou
`timescale 1ns / 1ps

`include "defines.v"

module cpu(
	input wire EXCLK,
	input  wire button,
	output wire Tx,
	input  wire Rx
);

	localparam MEM_PORT_CNT = 1;

	reg RST;
	reg RST_delay;
	
	reg CLK;
	
	always @(posedge EXCLK or posedge button) begin
		if (button) begin
			CLK = 0;
		end CLK = ~CLK;
	end
	
	always @(posedge CLK or posedge button) begin
		if(button) begin
			RST <= 1;
			RST_delay <= 1;
		end else begin
			RST_delay <= 0;
			RST <= RST_delay;
		end
	end
	
	wire 		UART_send_flag;
	wire [7:0]	UART_send_data;
	wire 		UART_recv_flag;
	wire [7:0]	UART_recv_data;
	wire		UART_sendable;
	wire		UART_receivable;
	
	uart #(.BAUDRATE(12500000), .CLOCKRATE(50000000)) UART(
		CLK, RST,
		UART_send_flag, UART_send_data,
		UART_recv_flag, UART_recv_data,
		UART_sendable, UART_receivable,
		Tx, Rx);
	
	localparam CHANNEL_BIT = 1;
	localparam MESSAGE_BIT = 72;
	localparam CHANNEL = 1 << CHANNEL_BIT;
	
	wire 					COMM_read_flag[CHANNEL-1:0];
	wire [MESSAGE_BIT-1:0]	COMM_read_data[CHANNEL-1:0];
	wire [4:0]				COMM_read_length[CHANNEL-1:0];
	wire 					COMM_write_flag[CHANNEL-1:0];
	wire [MESSAGE_BIT-1:0]	COMM_write_data[CHANNEL-1:0];
	wire [4:0]				COMM_write_length[CHANNEL-1:0];
	wire					COMM_readable[CHANNEL-1:0];
	wire					COMM_writable[CHANNEL-1:0];
	
	multichannel #(.MESSAGE_BIT(MESSAGE_BIT), .CHANNEL_BIT(CHANNEL_BIT)) COMM(
		CLK, RST,
		UART_send_flag, UART_send_data,
		UART_recv_flag, UART_recv_data,
		UART_sendable, UART_receivable,
		{COMM_read_flag[1], COMM_read_flag[0]},
		{COMM_read_length[1], COMM_read_data[1], COMM_read_length[0], COMM_read_data[0]},
		{COMM_write_flag[1], COMM_write_flag[0]},
		{COMM_write_length[1], COMM_write_data[1], COMM_write_length[0], COMM_write_data[0]},
		{COMM_readable[1], COMM_readable[0]},
		{COMM_writable[1], COMM_writable[0]});
	
	wire [MEM_PORT_CNT * 2  - 1 : 0]		MEM_rw_flag;
	wire [MEM_PORT_CNT * 32 - 1 : 0]		MEM_addr;
	wire [MEM_PORT_CNT * 32 - 1 : 0]		MEM_read_data;
	wire [MEM_PORT_CNT * 32 - 1 : 0]		MEM_write_data;
	wire [MEM_PORT_CNT * 4  - 1 : 0]		MEM_write_mask;
	wire [MEM_PORT_CNT -      1 : 0]		MEM_busy;
	wire [MEM_PORT_CNT -      1 : 0]		MEM_done;
	
	memory_controller #(.PORT_COUNT(MEM_PORT_CNT)) MEM_CTRL(
		CLK, RST,
		COMM_write_flag[0], COMM_write_data[0], COMM_write_length[0],
		COMM_read_flag[0], COMM_read_data[0], COMM_read_length[0],
		COMM_writable[0], COMM_readable[0],
		MEM_rw_flag, MEM_addr,
		MEM_read_data, MEM_write_data, MEM_write_mask,
		MEM_busy, MEM_done);
	
	cpu_core CORE(
		CLK, RST, EXCLK,
		MEM_rw_flag, 
		MEM_addr,
		MEM_read_data, 
		MEM_write_data, 
		MEM_write_mask,
		MEM_busy, MEM_done);
endmodule