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

import pkg_keccak::N;

module tb_keccak ();

// Main connections to design
logic           Clock;
logic           Reset;
logic           Start;
logic  [N-1:0]  Din;
logic           Din_valid;
logic           Last_block;

wire            Buffer_full;
wire            Ready;
wire   [N-1:0]  Dout;
wire            Dout_valid;

keccak DUT(
			.Clock(Clock),
			.Reset(Reset),
			.Start(Start),
			.Din(Din),
			.Din_valid(Din_valid),
			.Last_block(Last_block),
			.Buffer_full(Buffer_full),
			.Ready(Ready),
			.Dout(Dout),
			.Dout_valid(Dout_valid)
	   );

parameter IDLE_CLOCKS   = 1;
parameter CLOCK_CYCLE   = 1ns;
localparam CLOCK_WIDTH = CLOCK_CYCLE / 2;

// Create a clock
initial begin
    Clock = 1'b1;
    forever #CLOCK_WIDTH Clock = ~Clock;
end

// Items used for simulation
integer num_test, result;

task do_reset;
    Reset       = '1;
    Din         = '0;
    Din_valid   = '0;
    Last_block  = '0;
    repeat (IDLE_CLOCKS) @(negedge Clock);
    Reset       = '0;
endtask

// The main testing block
initial begin
    do_reset();
	$monitor("buffer_full:%b, Ready:%b, Dout:%h, Dout_valid:%b, time is %0.2t", Buffer_full, Ready, Dout, Dout_valid, $time);
	//$monitor("clk:%h, time is %4.2t", Clock, $time);
	$display ("start; time is %0.2t", $time);
	Start = '1; Last_block = '0;
	#2
	Start = '0;
	#2
	Din = 64'hAED66CE184BE2329;
	Din_valid = '1;
	#2
	Din = 64'h00000010F1499052;
	#2
	Din = 64'h0000000000000000;
	#26
	Din = 64'h8000000000000000;
	#2
	Din_valid = '0; //Buffer is full, so it will not accept any more inputs right now.
	#62
	Last_block = 1;
	#2
	Last_block = 0;
	Din_valid = '1; Din = 64'hAED66CE184BE2329;
	#2
	Din = 64'h00000010F1499052;
	#2
	Din = 64'h0000000000000000;
	#26
	Din = 64'h8000000000000000;
	#2
	Din_valid = '0;
	#62
	Last_block = 1;
	#2
	Last_block = 0;
	#200 $finish;            // Quit the simulation

end


endmodule
