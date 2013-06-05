// ============================================================================
// Project:   Keccak Verilog Module
// Author:    Josh Moles
// Created:   3 June 2013
//
// Description:
//      Testbench for use in a Veloce TBX enviornment.
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
`timescale 1ns/1ps
import pkg_keccak::N;

module tbx_keccak();

// Main connections to design
logic               Clock;
logic               Reset;
logic               Start;
logic  [N-1:0]      Din;
logic               Din_valid;
logic               Last_block;

wire                Buffer_full;
wire                Ready;
wire   [N-1:0]      Dout;
wire                Dout_valid;

// Signals for TBX Mode
logic               see_dash;
logic               see_period;

// Import the DPI C functions
import "DPI-C" task PrepareFiles();
import "DPI-C" task ReadLine();
import "DPI-C" task GetNumTestsFromSoftware(output bit [31:0] num_test);
import "DPI-C" task SeeDash(output bit see_dash);
import "DPI-C" task SeePeriod(output bit see_period);
import "DPI-C" task GetDataFromSoftare(output bit [31:0] dataInHigh, output bit [31:0] dataInLow);
import "DPI-C" task SendDataToSoftware(input bit [31:0] dataOutHigh, input bit [31:0] dataOutLow);
import "DPI-C" task DoneWithSend();
import "DPI-C" task SimulationComplete();

// Items used for simulation
integer counter, count_hash, num_test, result;

// Enum for state machine below
typedef enum integer { INIT, read_first_input, st0, st1, END_HASH1, END_HASH2, STOP} st_type;
st_type st;

keccak keccak_i(.*);

// Create a clock
// tbx clkgen
initial begin
    Clock = 1'b0;
    #5;
    forever begin
        Clock = 1'b1;
        #10;
        Clock = 1'b0;
        #10;
    end
end

// tbx clkgen
initial begin
    Reset = 1'b0;
    #1;
    Reset = 1'b1;
    #100;
    Reset = 1'b0;
end

// State machine to do testing
always @ (posedge Clock) begin
    if(Reset) begin
        PrepareFiles();
        st          <= INIT;
        counter     <= '0;
        Din_valid   <= '0;
        Last_block  <= '0;
        count_hash  <= '0;
    end else begin
        count_hash  <= '0;
        case(st)
            INIT:
                begin
                    GetNumTestsFromSoftware(num_test);
                    st          <= read_first_input;
                    Start       <= '1;
                    Din_valid   <= '0;
                end
            read_first_input:
                begin
                    Start       <= '0;

                    ReadLine();
                    SeePeriod(see_period);
                    SeeDash(see_dash);
                    if(see_period) begin
                        st <= STOP;
                    end else begin
                        if(see_dash) begin
                            st <= END_HASH1;
                        end else begin
                            Din_valid   <= '1;
                            GetDataFromSoftare(Din[63:32], Din[31:0]);
                            st          <= st0;
                            counter     <= '0;
                        end
                    end

                end
            st0:
                begin
                    if(counter < 16) begin
                        if(counter < 15) begin
                            ReadLine();
                            GetDataFromSoftare(Din[63:32], Din[31:0]);
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
                        SendDataToSoftware(Dout[63:32], Dout[31:0]);
                        if(counter < 3) begin
                            counter     <= counter + 1;
                        end else begin
                            st          <= read_first_input;
                            Start       <= '1;
                            DoneWithSend();

                        end
                    end
                end
            STOP:
                begin
                    SimulationComplete();
                    $finish;
                end
        endcase

    end // End if reset/else
end // End posedge Clock/Reset




endmodule