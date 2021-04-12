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

package pkg_keccak;


    parameter int NUM_PLANE             = 5;
    parameter int NUM_SHEET             = 5;
    parameter int unsigned N            = 64;
    parameter int unsigned IN_BUF_SIZE  = 64;
    parameter int unsigned OUT_BUF_SIZE = 64;


    typedef logic   [N-1:0]             k_lane;
    typedef k_lane  [NUM_SHEET-1:0]     k_plane;
    typedef k_plane [NUM_PLANE-1:0]     k_state;


    function int ABS (int numberIn);
        ABS = (numberIn < 0) ? -numberIn : numberIn;
    endfunction


endpackage
