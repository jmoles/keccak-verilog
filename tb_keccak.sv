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
// to use, copy, modify merge, publish, distribute, sublicense, and/or sell
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
logic                      clk;
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
            .clk(clk),
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

string FILE_IN, FILE_OUT;
initial begin
	$value$plusargs("FILE_IN=%s",FILE_IN);
	$value$plusargs("FILE_OUT=%s",FILE_OUT);
end

parameter IDLE_CLOCKS   = 1;
parameter CLOCK_CYCLE   = 1ns;
localparam CLOCK_WIDTH = CLOCK_CYCLE / 2;

// Items used for simulation
integer num_test, result;
integer file_in, file_out; // File pointers
string  line_in, line_out; // Lines

// Create a clk
initial begin
    clk = 1'b1;
    forever #CLOCK_WIDTH clk = ~clk;
end

// Open the files
initial begin
    file_in = $fopen(FILE_IN, "r");
    file_out = $fopen(FILE_OUT, "w");
end


task finish_prog;
    $fclose(file_in);
    $fclose(file_out);
    $display("Simulation complete!");
    $finish;
endtask

// The main testing block
initial begin
    reset       = '1;
    din_valid   = '0;
    repeat (IDLE_CLOCKS) @(negedge clk);
    reset         = '0;
    last_block    = '0;


    // Read the first line which gives the number of tests
    result      = $fscanf(file_in, "%d\n", num_test);
    din_valid   = '0;
    repeat (IDLE_CLOCKS) @ (negedge clk);

    // Read a line of input data
    result  = $fscanf(file_in, "%s\n", line_in);

    // Begin the main loop of code
    while(line_in != ".") begin

        repeat (IDLE_CLOCKS) @ (negedge clk);

        // Keep fetching input data until we get to a dash.
        while(line_in != "-") begin
            if(buffer_full) begin
                din_valid   = '0;
            end else begin
                din_valid   = '1;
                result      = $sscanf(line_in, "%h", din);
                result      = $fscanf(file_in, "%s\n", line_in);
                if (line_in == "-") begin
                    last_block         = '1;
                end
            end
            repeat (IDLE_CLOCKS) @ (negedge clk);
            if (line_in == "-") begin
                last_block         = '0;
            end

        end
        // All lines read in, start looking at the data
        // potentially coming out.

        // Ensure that data is not showing valid out here.
        din_valid           = '0;

        // Wait until buffer isn't full. Then, wait
        // until ready comes back high waiting at least
        // a clk tick before beginning to check.
        while (buffer_full)
            repeat (IDLE_CLOCKS) @ (posedge clk);
        while (~ready)
            repeat (IDLE_CLOCKS) @ (posedge clk);
        while (~dout_valid)
            repeat (IDLE_CLOCKS) @ (posedge clk);

        $sformat(line_out, "%h%h", dout_blk_1, dout_blk_0);
        $fwrite(file_out, "%s\n", line_out);
        $sformat(line_out, "%h%h", dout_blk_3, dout_blk_2);
        $fwrite(file_out, "%s\n", line_out);
        $sformat(line_out, "%h%h", dout_blk_5, dout_blk_4);
        $fwrite(file_out, "%s\n", line_out);
        $sformat(line_out, "%h%h", dout_blk_7, dout_blk_6);
        $fwrite(file_out, "%s\n", line_out);
        $fwrite(file_out,"-\n");

        // Pulse Last_block high for a single cycle.
        repeat (IDLE_CLOCKS) @ (negedge clk);
        reset         = '1;
        repeat (1) @ (negedge clk);
        reset          = '0;
        repeat (IDLE_CLOCKS) @ (negedge clk);
        // Read a line of input data
        result  = $fscanf(file_in, "%s\n", line_in);
    end // end of while (line_in != ".")
    
        //Testing a stall in din to make sure it works:
	repeat (IDLE_CLOCKS) @ (negedge clk);
	din_valid = 1;
	din = 32'h84BE2329;
	repeat (IDLE_CLOCKS) @ (negedge clk);
	din = 32'hAED66CE1;
	repeat (IDLE_CLOCKS) @ (negedge clk);
	din = 32'hF1499052;
	repeat (IDLE_CLOCKS) @ (negedge clk);
	din = 32'h00000010;	
        repeat (IDLE_CLOCKS) @ (negedge clk);
        din_valid = 0;
	din = 32'hFFFFFFFF;
        repeat (40) @ (negedge clk);
        din_valid = 1;
	din = 32'h00000000;
	repeat (26) @ (negedge clk);
	din = 32'h00000000;
	repeat (IDLE_CLOCKS) @ (negedge clk);
	din_valid = 0;
	din = 32'hFFFFFFFF;
	repeat (40) @ (negedge clk);
	din_valid = 1;
	din = 32'h80000000;
        last_block = 1;
	repeat (IDLE_CLOCKS) @ (negedge clk);
	last_block = 0;
	din_valid = 0;


        // Wait until buffer isn't full. Then, wait
        // until ready comes back high waiting at least
        // a clk tick before beginning to check.
        while (buffer_full)
            repeat (IDLE_CLOCKS) @ (posedge clk);
        while (~ready)
            repeat (IDLE_CLOCKS) @ (posedge clk);
        while (~dout_valid)
            repeat (IDLE_CLOCKS) @ (posedge clk);

        $sformat(line_out, "%h%h", dout_blk_1, dout_blk_0);
        $fwrite(file_out, "%s\n", line_out);
        $sformat(line_out, "%h%h", dout_blk_3, dout_blk_2);
        $fwrite(file_out, "%s\n", line_out);
        $sformat(line_out, "%h%h", dout_blk_5, dout_blk_4);
        $fwrite(file_out, "%s\n", line_out);
        $sformat(line_out, "%h%h", dout_blk_7, dout_blk_6);
        $fwrite(file_out, "%s\n", line_out);
        $fwrite(file_out,"-\n");

        // Pulse Last_block high for a single cycle.
        repeat (IDLE_CLOCKS) @ (negedge clk);
        reset         = '1;
        repeat (1) @ (negedge clk);
        reset          = '0;
        repeat (IDLE_CLOCKS) @ (negedge clk);

        //Testing a stall in din to make sure it works:
	repeat (IDLE_CLOCKS) @ (negedge clk);
	din_valid = 1;
	din = 32'h84BE2329;
	repeat (IDLE_CLOCKS) @ (negedge clk);
	din = 32'hAED66CE1;
	repeat (IDLE_CLOCKS) @ (negedge clk);
	din = 32'hF1499052;
	repeat (IDLE_CLOCKS) @ (negedge clk);
	din = 32'h00000010;	
        last_block = 1;
	repeat (IDLE_CLOCKS) @ (negedge clk);
	last_block = 0;
	din_valid = 0;


        // Wait until buffer isn't full. Then, wait
        // until ready comes back high waiting at least
        // a clk tick before beginning to check.
        while (buffer_full)
            repeat (IDLE_CLOCKS) @ (posedge clk);
        while (~ready)
            repeat (IDLE_CLOCKS) @ (posedge clk);
        while (~dout_valid)
            repeat (IDLE_CLOCKS) @ (posedge clk);

        $sformat(line_out, "%h%h", dout_blk_1, dout_blk_0);
        $fwrite(file_out, "%s\n", line_out);
        $sformat(line_out, "%h%h", dout_blk_3, dout_blk_2);
        $fwrite(file_out, "%s\n", line_out);
        $sformat(line_out, "%h%h", dout_blk_5, dout_blk_4);
        $fwrite(file_out, "%s\n", line_out);
        $sformat(line_out, "%h%h", dout_blk_7, dout_blk_6);
        $fwrite(file_out, "%s\n", line_out);
        $fwrite(file_out,"-\n");





    // Close the file handles and exit
    finish_prog();
end

endmodule
