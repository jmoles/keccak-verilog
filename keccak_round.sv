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

import pkg_keccak::k_plane;
import pkg_keccak::k_state;
import pkg_keccak::N;
import pkg_keccak::ABS;

module keccak_round (
    input   k_state         Round_in,
    input   [N-1:0]         Round_constant_signal,
    output  k_state         Round_out);


k_state theta_in, theta_out, pi_in, pi_out, rho_in, rho_out,
        chi_in, chi_out, iota_in, iota_out;

k_plane sum_sheet;

// Connections

// Order is theata, pi, rho, chi, iota
assign  theta_in    = Round_in;
assign  pi_in       = rho_out;
assign  rho_in      = theta_out;
assign  chi_in      = pi_out;
assign  iota_in     = chi_out;
assign  Round_out   = iota_out;

genvar y,x,i;


// Chi
generate
    for(y = 0; y <= 4; y++)
        for(x = 0; x <= 2; x++)
            for(i = 0; i <= N-1; i++)
                assign chi_out[y][x][i] = chi_in[y][x][i] ^ ( ~(chi_in[y][x+1][i]) & chi_in[y][x+2][i]);
endgenerate

generate
    for(y = 0; y <= 4; y++)
        for(i = 0; i <= N-1; i++)
            assign chi_out[y][3][i] = chi_in[y][3][i] ^ ( ~(chi_in[y][4][i]) & chi_in[y][0][i]);
endgenerate

generate
    for(y = 0; y <= 4; y++)
        for(i = 0; i <= N-1; i++)
            assign chi_out[y][4][i] = chi_in[y][4][i] ^ ( ~(chi_in[y][0][i]) & chi_in[y][1][i]);
endgenerate

// Theta

//compute the sum of the columns
generate
    for(x = 0; x <= 4; x++)
        for(i = 0; i <= N-1; i++)
            assign sum_sheet[x][i] = theta_in[0][x][i] ^ theta_in[1][x][i] ^ theta_in[2][x][i] ^ theta_in[3][x][i] ^ theta_in[4][x][i];
endgenerate

generate
    for(y = 0; y <= 4; y++)
        for(x = 1; x <= 3; x++) begin

            assign theta_out[y][x][0] = theta_in[y][x][0] ^ sum_sheet[x-1][0] ^ sum_sheet[x+1][N-1];

            for(i = 1; i <= N-1; i++)
                assign theta_out[y][x][i] = theta_in[y][x][i] ^ sum_sheet[x-1][i] ^ sum_sheet[x+1][i-1];
        end
endgenerate

generate
    for(y = 0; y <= 4; y++) begin
        assign theta_out[y][0][0] = theta_in[y][0][0] ^ sum_sheet[4][0] ^ sum_sheet[1][N-1];

        for(i = 1; i <= N-1; i++)
            assign theta_out[y][0][i] = theta_in[y][0][i] ^ sum_sheet[4][i] ^ sum_sheet[1][i-1];
    end
endgenerate

generate
    for(y = 0; y <= 4; y++) begin
        assign theta_out[y][4][0] = theta_in[y][4][0] ^ sum_sheet[3][0] ^ sum_sheet[0][N-1];

        for(i = 1; i <= N-1; i++)
            assign theta_out[y][4][i] = theta_in[y][4][i] ^ sum_sheet[3][i] ^ sum_sheet[0][i-1];
    end
endgenerate

// Pi
generate
    for(y = 0; y <= 4; y++)
        for(x = 0; x <= 4; x++)
            for(i = 0; i <= N-1; i++)
                assign pi_out[(2*x+3*y) % 5][0*x+1*y][i] = pi_in[y][x][i];
endgenerate

// Rho
always_comb begin
    for(int ri = 0; ri < N; ri++) begin
        rho_out[0][0][ri] = rho_in[0][0][ri];
        rho_out[0][1][ri] = rho_in[0][1][ABS((ri-1)  % N)];
        rho_out[0][2][ri] = rho_in[0][2][ABS((ri-62) % N)];
        rho_out[0][3][ri] = rho_in[0][3][ABS((ri-28) % N)];
        rho_out[0][4][ri] = rho_in[0][4][ABS((ri-27) % N)];

        rho_out[1][0][ri] = rho_in[1][0][ABS((ri-36) % N)];
        rho_out[1][1][ri] = rho_in[1][1][ABS((ri-44) % N)];
        rho_out[1][2][ri] = rho_in[1][2][ABS((ri-6)  % N)];
        rho_out[1][3][ri] = rho_in[1][3][ABS((ri-55) % N)];
        rho_out[1][4][ri] = rho_in[1][4][ABS((ri-20) % N)];

        rho_out[2][0][ri] = rho_in[2][0][ABS((ri-3)  % N)];
        rho_out[2][1][ri] = rho_in[2][1][ABS((ri-10) % N)];
        rho_out[2][2][ri] = rho_in[2][2][ABS((ri-43) % N)];
        rho_out[2][3][ri] = rho_in[2][3][ABS((ri-25) % N)];
        rho_out[2][4][ri] = rho_in[2][4][ABS((ri-39) % N)];

        rho_out[3][0][ri] = rho_in[3][0][ABS((ri-41) % N)];
        rho_out[3][1][ri] = rho_in[3][1][ABS((ri-45) % N)];
        rho_out[3][2][ri] = rho_in[3][2][ABS((ri-15) % N)];
        rho_out[3][3][ri] = rho_in[3][3][ABS((ri-21) % N)];
        rho_out[3][4][ri] = rho_in[3][4][ABS((ri-8)  % N)];

        rho_out[4][0][ri] = rho_in[4][0][ABS((ri-18) % N)];
        rho_out[4][1][ri] = rho_in[4][1][ABS((ri-2)  % N)];
        rho_out[4][2][ri] = rho_in[4][2][ABS((ri-61) % N)];
        rho_out[4][3][ri] = rho_in[4][3][ABS((ri-56) % N)];
        rho_out[4][4][ri] = rho_in[4][4][ABS((ri-14) % N)];
    end
end

// Iota
generate
    for(y = 1; y <= 4; y++)
        for(x = 0; x <= 4; x++)
            for(i = 0; i <= N-1; i++)
                assign iota_out[y][x][i] = iota_in[y][x][i];
endgenerate

generate
    for(x = 1; x <= 4; x++)
        for(i = 0; i <= N-1; i++)
            assign iota_out[0][x][i] = iota_in[0][x][i];
endgenerate

generate
    for(i = 0; i <= N-1; i++)
        assign iota_out[0][0][i] = iota_in[0][0][i] ^ Round_constant_signal[i];
endgenerate


endmodule