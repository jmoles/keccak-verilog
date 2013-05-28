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

module keccak_round_constant_gen(
        input   [4:0]          round_number,
        output  logic [63:0]  round_constant_signal_out);

    always_comb
    begin
        case(round_number)
            5'b00000 : round_constant_signal_out = 64'h0000_0000_0000_0001;
            5'b00001 : round_constant_signal_out = 64'h0000_0000_0000_8082;
            5'b00010 : round_constant_signal_out = 64'h8000_0000_0000_808A;
            5'b00011 : round_constant_signal_out = 64'h8000_0000_8000_8000;
            5'b00100 : round_constant_signal_out = 64'h0000_0000_0000_808B;
            5'b00101 : round_constant_signal_out = 64'h0000_0000_8000_0001;
            5'b00110 : round_constant_signal_out = 64'h8000_0000_8000_8081;
            5'b00111 : round_constant_signal_out = 64'h8000_0000_0000_8009;
            5'b01000 : round_constant_signal_out = 64'h0000_0000_0000_008A;
            5'b01001 : round_constant_signal_out = 64'h0000_0000_0000_0088;
            5'b01010 : round_constant_signal_out = 64'h0000_0000_8000_8009;
            5'b01011 : round_constant_signal_out = 64'h0000_0000_8000_000A;
            5'b01100 : round_constant_signal_out = 64'h0000_0000_8000_808B;
            5'b01101 : round_constant_signal_out = 64'h8000_0000_0000_008B;
            5'b01110 : round_constant_signal_out = 64'h8000_0000_0000_8089;
            5'b01111 : round_constant_signal_out = 64'h8000_0000_0000_8003;
            5'b10000 : round_constant_signal_out = 64'h8000_0000_0000_8002;
            5'b10001 : round_constant_signal_out = 64'h8000_0000_0000_0080;
            5'b10010 : round_constant_signal_out = 64'h0000_0000_0000_800A;
            5'b10011 : round_constant_signal_out = 64'h8000_0000_8000_000A;
            5'b10100 : round_constant_signal_out = 64'h8000_0000_8000_8081;
            5'b10101 : round_constant_signal_out = 64'h8000_0000_0000_8080;
            5'b10110 : round_constant_signal_out = 64'h0000_0000_8000_0001;
            5'b10111 : round_constant_signal_out = 64'h8000_0000_8000_8008;
            default : round_constant_signal_out = '0;

        endcase
    end







endmodule