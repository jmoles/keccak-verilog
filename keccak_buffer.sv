// ============================================================================
// Project:   Keccak Verilog Module
// Author:    Josh Moles
// Created:   27 May 2013
//
// Description:
//
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
import pkg_keccak::OUT_BUF_SIZE;
parameter int unsigned IN_BUF_WORD_SIZE  = (1024/IN_BUF_SIZE)-1;
parameter int unsigned IN_BUF_DATA = 1023-(IN_BUF_SIZE-1);
parameter int unsigned COUNT_OUT_WORD_SIZE = 256/OUT_BUF_SIZE;



module keccak_buffer(
    input                         Clock,
    input                         Reset,
    input   [IN_BUF_SIZE-1:0]     Din_buffer_in,
    input                         Din_buffer_in_valid,
    input                         Last_block,
    input   [255:0]               Dout_buffer_in,
    input                         Ready,

    output                        Din_buffer_full,
    output  [1023:0]              Din_buffer_out,
    output  [OUT_BUF_SIZE-1:0]    Dout_buffer_out,
    output  logic                 Dout_buffer_out_valid);


    logic               mode;               // 0 = Input mode, 1 = Output Mode
    logic               buffer_full;

    logic   [31:0]       count_in_words;
    logic   [1023:0]    buffer_data;

    logic   [31:0]       count_out_words;    // Range of this value is 0 - 4


    assign  Din_buffer_out                      = buffer_data;
    assign  Dout_buffer_out                     = buffer_data[OUT_BUF_SIZE-1:0];
    assign  Din_buffer_full                     = buffer_full;

    always_ff @(posedge Clock or posedge Reset)
    begin
        if(Reset) begin
            buffer_data                         <= '0;
            count_in_words                      <= '0;
            count_out_words                     <= 0;
            buffer_full                         <= '0;
            mode                                <= '0;
            Dout_buffer_out_valid               <= '0;
        end else begin

            if(Last_block && Ready) begin
                mode                            <= '1;
            end

            if(~mode)
            begin
                if(buffer_full && Ready) begin
                    buffer_full                 <= '0;
                    count_in_words              <= '0;
                end else begin
                    if(Din_buffer_in_valid & ~buffer_full) begin

                        // Shift buffer for the data
                        buffer_data             <= (buffer_data >> IN_BUF_SIZE);

                        // TODO: Delete this old for loop after checking above in sim.
                        // for (int i = 0; i < 15; ++i) begin
                        //     buffer_data[63+(i*64) : 0+(i*64)] <= buffer_data[127+(i*64) : 64+(i*64)];
                        // end

                        // Insert a new input
                        buffer_data[1023:IN_BUF_DATA]   <= Din_buffer_in;

                        if(count_in_words == IN_BUF_WORD_SIZE) begin
                            // Buffer rull and ready for being absorbed by the permutation
                            buffer_full         <= '1;
                            count_in_words      <= '0;
                        end else begin
                            count_in_words      <= count_in_words + 1;
                        end // End if count_in_words == 15
                    end // End Din_buffer_in_valid & ~buffer_full
                end // End if buffer_full & Ready

            end else begin
                // Output mode

                if(count_out_words == 0) begin
                    buffer_data[255:0]          <= Dout_buffer_in;
                    count_out_words             <= count_out_words + 1;
                    Dout_buffer_out_valid       <= '1;
                end else begin
                    if(count_out_words < COUNT_OUT_WORD_SIZE) begin
                        count_out_words         <= count_out_words + 1;
                        Dout_buffer_out_valid   <= '1;

                        buffer_data             <= (buffer_data >> OUT_BUF_SIZE);

                        // TODO: Delete this old for loop after checking above in sim.
                        // for (int j = 0; j < 2; ++j) begin
                        //     buffer_data[63+(j*64) : 0+(j*64)] <= buffer_data[127+(j*64) : 64+(j*64)];
                        // end

                    end else begin
                        Dout_buffer_out_valid   <= '0;
                        count_out_words         <= '0;
                        mode                    <= '0;
                    end // End count_out_words < 4
                end // End count_out_words == 0
            end // End if ~mode
        end // End if Reset
    end // End always_ff







endmodule
