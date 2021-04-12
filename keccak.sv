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
import pkg_keccak::OUT_BUF_SIZE;

module keccak (
    input                      Clock,
    input                      Reset,
    input                      Start,
    input   [IN_BUF_SIZE-1:0]  Din,
    input                      Din_valid,
    input                      Last_block,

    output                     Buffer_full,
    output                     Ready,
    output  [OUT_BUF_SIZE-1:0] Dout,
    output                     Dout_valid);


k_state         reg_data, Round_in, Round_out;
logic [255:0]   reg_data_vector;
logic [4:0]     counter_nr_rounds;
logic           din_buffer_full;
logic [N-1:0]   Round_constant_signal;
logic [1023:0]  din_buffer_out;
logic           permutation_computed;

genvar x,i,col,row;

keccak_round keccak_round_i(
    .Round_in,
    .Round_constant_signal,
    .Round_out);

keccak_round_constants_gen keccak_round_constants_gen_i(
    .round_number(counter_nr_rounds),
    .round_constant_signal_out(Round_constant_signal));

keccak_buffer keccak_buffer_i(
    .Clock(Clock),
    .Reset(Reset),
    .Din_buffer_in(Din),
    .Din_buffer_in_valid(Din_valid),
    .Last_block(Last_block),
    .Dout_buffer_in(reg_data_vector),
    .Ready(permutation_computed),

    .Din_buffer_full(din_buffer_full),
    .Din_buffer_out(din_buffer_out),
    .Dout_buffer_out(Dout),
    .Dout_buffer_out_valid(Dout_valid));

assign Ready       = permutation_computed;
assign Buffer_full = din_buffer_full;

generate
    for(x = 0; x <= 3; x++)
        for(i = 0; i <= 63; i++)
            assign reg_data_vector[64*x+i] = reg_data[0][x][i];
endgenerate

always_ff @ (posedge Clock or posedge Reset) begin
    if(Reset) begin
        reg_data                            <= '0;
        counter_nr_rounds                   <= '0;
        permutation_computed                <= '1;
    end else begin
        if(Start) begin
            reg_data                        <= '0;
            counter_nr_rounds               <= '0;
            permutation_computed            <= '1;
        end else begin
            if(din_buffer_full && permutation_computed) begin
                counter_nr_rounds           <= 1;
                permutation_computed        <= '0;
                reg_data                    <= Round_out;
            end else begin
                if(counter_nr_rounds < 24 && ~permutation_computed) begin
                    counter_nr_rounds       <= counter_nr_rounds + 1;
                    reg_data                <= Round_out;
                end // End if counter_nr_rounds < 24 & ~permutation_computed

                if(counter_nr_rounds == 23) begin
                    permutation_computed    <= '1;
                    counter_nr_rounds       <= '0;
                end // End if counter_nr_rounds == 23
            end // End if Din_buffer_full && permutation_computer / else
        end // End if Start / else
    end // End if Reset/else
end // End always_ff @ possedge Clock

// Input Mapping

// Capacity Part
generate
    for (col = 1; col <= 4; col++)
        for(i = 0; i<= 63; i++)
            assign Round_in[3][col][i] = reg_data[3][col][i];
endgenerate

generate
    for(col = 0; col <= 4; col++)
        for(i = 0; i <= 63; i++)
            assign Round_in[4][col][i] = reg_data[4][col][i];
endgenerate


// Rate Part
generate
    for(row = 0; row <= 2; row++)
        for(col = 0; col <= 4; col++)
            for(i = 0; i <= 63; i++)
                assign Round_in[row][col][i] = reg_data[row][col][i] ^ (din_buffer_out[(row*64*5) + (col*64) + i] & (din_buffer_full & permutation_computed));
endgenerate

generate
    for(i = 0; i<= 63; i++)
        assign Round_in[3][0][i] = reg_data[3][0][i] ^ (din_buffer_out[(3*64*5)+(0*64)+i] & (din_buffer_full & permutation_computed));
endgenerate

// Trace support for verilator.
initial begin
    if ($test$plusargs("trace") != 0) begin
        $display("[%0t] Tracing to logs/vlt_dump.vcd...\n", $time);
        $dumpfile("logs/vlt_dump.vcd");
        $dumpvars();
    end
    $display("[%0t] Model running...", $time);
end

endmodule
