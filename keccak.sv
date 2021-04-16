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
import pkg_keccak::IN_BUF_SIZE;

module keccak (
    input logic                   clk,
    input logic                   reset,
    input logic [IN_BUF_SIZE-1:0] din,
    input logic                   din_valid,
    input logic                   last_block,

    output logic                    buffer_full,
    output logic                    ready,
    output logic [255:0]            dout_all,
    output logic [31:0]             dout_blk_0,
    output logic [31:0]             dout_blk_1,
    output logic [31:0]             dout_blk_2,
    output logic [31:0]             dout_blk_3,
    output logic [31:0]             dout_blk_4,
    output logic [31:0]             dout_blk_5,
    output logic [31:0]             dout_blk_6,
    output logic [31:0]             dout_blk_7,
    output logic                    dout_valid,
    output logic                    intermediate_dout_valid
);

    logic [1023:0] din_unbuffered;
    logic buffer_in_output_valid;
    logic internal_intermediate_dout_valid;
    logic last_block_reg_q;
    logic last_block_buf_output;
    logic [255:0] dout_unbuffered;
    logic unbuffered_dout_valid;


    assign intermediate_dout_valid = internal_intermediate_dout_valid;

    assign dout_valid = last_block_reg_q && internal_intermediate_dout_valid;
    assign dout_all = dout_unbuffered;
    assign dout_blk_0 = dout_unbuffered[31:0];
    assign dout_blk_1 = dout_unbuffered[63:32];
    assign dout_blk_2 = dout_unbuffered[95:64];
    assign dout_blk_3 = dout_unbuffered[127:96];
    assign dout_blk_4 = dout_unbuffered[159:128];
    assign dout_blk_5 = dout_unbuffered[191:160];
    assign dout_blk_6 = dout_unbuffered[223:192];
    assign dout_blk_7 = dout_unbuffered[255:224];

    EnResetReg #(.nbits(1)) last_block_reg (
                                            .clk(clk),
                                            .reset(reset),
                                            .en(last_block_buf_output),
                                            .d(1'b1),
                                            .q(last_block_reg_q)
    );

    keccak_buffer_in in_buf(
                            .clk(clk),
                            .reset(reset),
                            .buffer_input(din),
                            .input_valid(din_valid),
                            .output_ready(ready),
                            .last_block_input(last_block),
                            .buffer_full(buffer_full),
                            .last_block_output(last_block_buf_output),
                            .buffer_output(din_unbuffered),
                            .buffer_output_valid(buffer_in_output_valid)
    );

    keccak_unbuffered keccak_unbuf (
                                   .clk(clk),
                                   .reset(reset),
                                   .din(din_unbuffered),
                                   .din_valid(buffer_in_output_valid),
                                   .ready(ready),
                                   .dout(dout_unbuffered),
                                   .dout_valid(internal_intermediate_dout_valid)
    );

endmodule
