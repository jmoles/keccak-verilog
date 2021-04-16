// ============================================================================
// Project:   Keccak Verilog Module
// Author:    Josh Moles
// Created:   27 May 2013
//
// Description:
//   Top-level testbench for the Keccak module.
//
// This code is almost a straight translation of the VHDL high-speed module
// provided from http://keccak.noekeon.org/.
//
// The MIT License (MIT)
//
// Copyright (c) 2013 Josh Moles
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
// ============================================================================

import pkg_keccak::IN_BUF_SIZE;
module tb_keccak ();

// Main connections to design
logic                      clock;
logic                      reset;
logic  [IN_BUF_SIZE-1:0]   din;
logic                      din_valid;
logic                      last_block;
logic                      output_ready;


wire         ready;
wire         buffer_full;
wire [255:0] dout;
wire [31:0]  dout_blk_0;
wire [31:0]  dout_blk_1;
wire [31:0]  dout_blk_2;
wire [31:0]  dout_blk_3;
wire [31:0]  dout_blk_4;
wire [31:0]  dout_blk_5;
wire [31:0]  dout_blk_6;
wire [31:0]  dout_blk_7;

wire         dout_valid;
wire         intermediate_dout_valid;

keccak DUT (
            .clock(clock),
            .reset(reset),
            .din(din),
            .din_valid(din_valid),
            .last_block(last_block),
            .buffer_full(buffer_full),
            .ready(ready),
            .dout_all(dout),
            .dout_blk_0(dout_blk_0),
            .dout_blk_1(dout_blk_1),
            .dout_blk_2(dout_blk_2),
            .dout_blk_3(dout_blk_3),
            .dout_blk_4(dout_blk_4),
            .dout_blk_5(dout_blk_5),
            .dout_blk_6(dout_blk_6),
            .dout_blk_7(dout_blk_7),
            .dout_valid(dout_valid),
            .intermediate_dout_valid(intermediate_dout_valid)
);




parameter IDLE_CLOCKS   = 1;
parameter CLOCK_CYCLE   = 1ns;
localparam CLOCK_WIDTH = CLOCK_CYCLE / 2;

// Create a clock
initial begin
    clock = 1'b1;
    forever #CLOCK_WIDTH clock = ~clock;
end

// Items used for simulation
integer num_test, result;

// The main testing block
initial begin
	reset         = '1;
        din_valid   = '0;
        repeat (IDLE_CLOCKS) @(negedge clock);
        reset         = '0;
	$monitor("Ready:%b, Dout:%h, Dout_valid:%b, Intermediate_dout_valid:%b time is %0.2t", ready, dout, dout_valid, intermediate_dout_valid, $time);
	//$monitor("clk:%h, time is %4.2t", Clock, $time);
	$display ("start; time is %0.2t", $time);
	#2
	din = 32'h84BE2329;
	din_valid = '1;
        last_block = 0;
	#2
	din = 32'hAED66CE1;
	#2
	din = 32'hF1499052;
	#2
	din = 32'h00000010;	
        #2
        din_valid = 0;
        #12
        din_valid = 1;
	din = 32'h00000000;
	#52
	din = 32'h00000000;
	#2
	din = 32'h80000000;
	#2
	din = 32'h84BE2329; //second block
        last_block = 1;
	#2
	din = 32'hAED66CE1;
	#2
	din = 32'hF1499052;
	#2
	din = 32'h00000010;	
	#2
	din = 32'h00000000;
	#52
	din = 32'h00000000;
	#2
	din = 32'h80000000;
	#2
	din_valid = '0;
	#60
	#200 $finish;            // Quit the simulation
end


endmodule
