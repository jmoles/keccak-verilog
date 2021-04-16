// ============================================================================
// Project:   Keccak Verilog Module
// Author:    Josh Moles
// Created:   2 June 2013
//
// Description:
//   Program to aid in testing the code.
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

import pkg_keccak::k_state;
import pkg_keccak::N;

program prog_keccak #(
    parameter FILE_IN       = "test_vectors/keccak_in.txt",
    parameter FILE_OUT      = "output.txt",
    parameter CLOCK_CYCLE   = 1ns,
    parameter IDLE_CLOCKS   = 1)
    (
    output logic                Clock,
    output logic                Reset,
    output logic                Start,
    output logic    [N-1:0]     Din,
    output logic                Din_valid,
    output logic                Last_block,

    input                       Buffer_full,
    input                       Ready,
    input           [N-1:0]     Dout,
    input                       Dout_valid);

localparam CLOCK_WIDTH = CLOCK_CYCLE / 2;

// Items used for simulation
integer num_test, result;
integer file_in, file_out; // File pointers
string  line_in, line_out; // Lines

// Create a clock
initial begin
    Clock = 1'b0;
    forever #CLOCK_WIDTH Clock = ~Clock;
end

// Open the files
initial begin
    file_in = $fopen(FILE_IN, "r");
    file_out = $fopen(FILE_OUT, "w");
end

task do_reset;
    Reset       = '1;
    Din         = '0;
    Din_valid   = '0;
    Last_block  = '0;
    repeat (IDLE_CLOCKS) @(negedge Clock);
    Reset       = '0;
endtask

task finish_prog;
    $fclose(file_in);
    $fclose(file_out);
    $display("Simulation complete!");
    $finish;
endtask

// The main testing block
initial begin
    do_reset();

    // Read the first line which gives the number of tests
    result      = $fscanf(file_in, "%d\n", num_test);
    Start       = '1;
    Din_valid   = '0;
    repeat (IDLE_CLOCKS) @ (negedge Clock);

    // Read a line of input data
    result  = $fscanf(file_in, "%s\n", line_in);

    // Begin the main loop of code
    while(line_in != ".") begin

        Start               = '0;
        repeat (IDLE_CLOCKS) @ (negedge Clock);

        // Keep fetching input data until we get to a dash.
        while(line_in != "-") begin
            if(Buffer_full) begin
                Din_valid   = '0;
            end else begin
                Din_valid   = '1;
                result      = $sscanf(line_in, "%h", Din);
                result      = $fscanf(file_in, "%s\n", line_in);
            end
            repeat (IDLE_CLOCKS) @ (negedge Clock);
        end
        // All lines read in, start looking at the data
        // potentially coming out.

        // Ensure that data is not showing valid out here.
        Din_valid           = '0;

        // Wait until buffer isn't full. Then, wait
        // until ready comes back high waiting at least
        // a clock tick before beginning to check.
        while (Buffer_full)
            repeat (IDLE_CLOCKS) @ (posedge Clock);
        while (~Ready)
            repeat (IDLE_CLOCKS) @ (posedge Clock);

        // Pulse Last_block high for a single cycle.
        repeat (IDLE_CLOCKS) @ (negedge Clock);
        Last_block          = '1;
        repeat (1) @ (negedge Clock);
        Last_block          = '0;
        repeat (IDLE_CLOCKS) @ (negedge Clock);

        // Keep looping while output data is coming.
        while(Dout_valid) begin
            $sformat(line_out, "%h", Dout);
            $fwrite(file_out, "%s\n", line_out);
            repeat (IDLE_CLOCKS) @ (negedge Clock);
        end

        $fwrite(file_out,"-\n");
        Start               = '1;
        repeat (IDLE_CLOCKS) @ (negedge Clock);

        // Read a line of input data
        result  = $fscanf(file_in, "%s\n", line_in);
    end // end of while (line_in != ".")

    // Close the file handles and exit
    finish_prog();
end

endprogram
