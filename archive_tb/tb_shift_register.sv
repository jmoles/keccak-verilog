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

parameter int unsigned IN_BUF_OUTPUT = 256;

// Main connections to design
logic                        clock;
logic                        reset;
logic  [IN_BUF_SIZE-1:0]     buffer_input;
logic                        input_valid;
logic                        output_ready;
logic                        last_block;

wire                       buffer_full;
wire [IN_BUF_OUTPUT-1:0]              buffer_output;

shift_register #(
                 .INPUT_BUFFER_SIZE(IN_BUF_SIZE), 
                 .OUTPUT_BUFFER_SIZE(IN_BUF_OUTPUT)) 
       DUT (
			.clock(clock),
			.reset(reset),
			.buffer_input(buffer_input),
			.input_valid(input_valid),
			.output_ready(output_ready),
                        .last_block(last_block),
			.buffer_full(buffer_full),
			.buffer_output(buffer_output)
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
        buffer_input  = '0;
        input_valid   = '0;
        output_ready         = '0;
        repeat (IDLE_CLOCKS) @(negedge clock);
        reset         = '1;
	$monitor("buffer_full:%b, buffer_output:%h, time is %t", buffer_full, buffer_output, $time);
	//$monitor("clk:%h, time is %4.2t", Clock, $time);
	$display ("start; time is %0.2t", $time);
	#2
	output_ready = 0;
	input_valid = '1;
	last_block = 0;
	buffer_input = 32'h84BE2329;
	#2
	buffer_input = 32'hAED66CE1;
	#2
	buffer_input = 32'h00000000;
	#2
	buffer_input = 32'hFFFFFFFF;
        reset = '0;
	#2
	buffer_input = 32'h84BE2329;
	#2
	buffer_input = 32'hAED66CE1;
        reset = '1;
	#2
	buffer_input = 32'h00011000;
        reset = '0;
	#2
	buffer_input = 32'hFFFFFFFF;
	#2
	buffer_input = 32'h84BE2329;
	#2
	buffer_input = 32'hAED66CE1;
	#2
	buffer_input = 32'h00000000;
	#2
	buffer_input = 32'hFFFFFFFF;
	#2
	buffer_input = 32'h84BE2329;
	#2
	buffer_input = 32'hAED66CE1;
	#2
	buffer_input = 32'h00000000;
	#2
	buffer_input = 32'hFFFFFFFF;
	#2
	buffer_input = 32'h84BE2329;
	output_ready = 1;
	#2
	buffer_input = 32'hAED66CE1;
	#2
	buffer_input = 32'h00000000;
	#2
	buffer_input = 32'hFFFFFFFF;
	#2
	buffer_input = 32'h84BE2329;
	#2
	buffer_input = 32'hAED66CE1;
	#2
	buffer_input = 32'h00000000;
	#2
	buffer_input = 32'hFFFFFFFF;
	#2
	buffer_input = 32'h84BE2329;
	#2
	buffer_input = 32'hAED66CE1;
	#2
	buffer_input = 32'h00000000;
	#2
	buffer_input = 32'hFFFFFFFF;
	#2
	buffer_input = 32'h84BE2329;
	#2
	buffer_input = 32'hAED66CE1;
	#2
	buffer_input = 32'h00000000;
	#2
	buffer_input = 32'hFFFFFFFF;
	#2
	buffer_input = 32'h84BE2329;
	#2
	buffer_input = 32'hAED66CE1;
	#2
	buffer_input = 32'h00000000;
	#2
	buffer_input = 32'hFFFFFFFF;
	#2
	buffer_input = 32'h84BE2329;
	#2
	buffer_input = 32'hAED66CE1;
	#2
	buffer_input = 32'h00000000;
	#2
	buffer_input = 32'hFFFFFFFF;
	#2
	buffer_input = 32'h84BE2329;
	#2
	buffer_input = 32'hAED66CE1;
	#2
	buffer_input = 32'h00000000;
	output_ready = 0;
	#2
	buffer_input = 32'hFFFFFFFF;
	#2 $finish;            // Quit the simulation	#20 $finish;            // Quit the simulation

end


endmodule
