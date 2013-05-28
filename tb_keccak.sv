// ============================================================================
// Project:   Keccak Verilog Module
// Author:    Josh Moles
// Created:   27 May 2013
//
// Description:
//   Top-level module for the Keccak sponge function in Verilog.
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

parameter FILE_IN  = "test_vectors/keccak_in.txt";
parameter FILE_OUT = "output.txt";


module tb_keccak ();

localparam CLOCK_CYCLE = 1ms;
localparam CLOCK_WIDTH = CLOCK_CYCLE / 2;
localparam IDLE_CLOCKS = 2;

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

// Items used for simulation
integer counter, count_hash, num_test, result;
logic [63:0] temp;
integer file_in, file_out; // File pointers
string  line_in, line_out; // Lines
logic [8:0] char;

// Enum for state machine below
typedef enum integer { INIT, read_first_input, st0, st1, END_HASH1, END_HASH2, STOP} st_type;
st_type st;


keccak keccak_i(.*);

// Create a clock
initial begin
    Clock = 1'b0;
    forever #CLOCK_WIDTH Clock = ~Clock;
end

// Open the files and set up monitor
initial begin
    file_in = $fopen(FILE_IN, "r");
    file_out = $fopen(FILE_OUT, "w");
end

initial begin
    Reset = 1'b1;
    repeat (IDLE_CLOCKS) @(negedge Clock);
    Reset = 1'b0;
end

// State machine to do testing
always @ (posedge Clock or posedge Reset) begin
    if(Reset) begin
        st          <= INIT;
        counter     <= '0;
        Din         <= '0;
        Din_valid   <= '0;
        Last_block  <= '0;
        count_hash  <= '0;
    end else begin
        case(st)
            INIT:
                begin
                    result = $fscanf(file_in, "%d\n", num_test);
                    st          <= read_first_input;
                    Start       <= '1;
                    Din_valid   <= '0;
                end
            read_first_input:
                begin
                    Start       <= '0;

                    result = $fscanf(file_in, "%s\n", line_in);
                    if(line_in == ".") begin
                        $fclose(file_in);
                        $fclose(file_out);

                        $display("Simulation complete!");
                        st <= STOP;
                    end else begin
                        if(line_in == "-") begin
                            st <= END_HASH1;
                        end else begin
                            Din_valid   <= '1;
                            result = $sscanf(line_in, "%h", Din);
                            st          <= st0;
                            counter     <= '0;
                        end
                    end

                end
            st0:
                begin
                    if(counter < 16) begin
                        if(counter < 15) begin
                            result = $fscanf(file_in, "%h\n", Din);
                        end
                        counter         <= counter + 1;
                        st              <= st0;
                        Din_valid       <= '1;

                    end else begin
                        st              <= st1;
                        Din_valid       <= '0;
                    end

                end
            st1:
                begin
                    if(Buffer_full) begin
                        st              <= st1;
                    end else begin
                        st              <= read_first_input;
                    end
                end
            END_HASH1:
                begin
                    if(~Ready) begin
                        st              <= END_HASH1;
                    end else begin
                        Last_block      <= '1;
                        st              <= END_HASH2;
                        counter         <= '0;
                    end
                end
            END_HASH2:
                begin
                    Last_block          <= '0;
                    if(Dout_valid) begin
                        $sformat(line_out, "%h", Dout);
                        $fwrite(file_out, "%s\n", line_out);
                        if(counter < 3) begin
                            counter     <= counter + 1;
                        end else begin
                            st          <= read_first_input;
                            Start       <= '1;
                            $fwrite(file_out,"-\n");

                        end
                    end
                end
            STOP:
                begin
                    $finish;
                end
        endcase

    end // End if reset/else
end // End posedge Clock/Reset


endmodule