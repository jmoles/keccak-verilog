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
parameter int unsigned IN_BUF_OUTPUT = 1024;
parameter int unsigned IN_BUF_DATA = (IN_BUF_OUTPUT-1)-(IN_BUF_SIZE-1);


module keccak_buffer_in(
    input logic                        clk,
    input logic                        reset,
    input logic  [IN_BUF_SIZE-1:0]     buffer_input,
    input logic                        input_valid,
    input logic                        output_ready,
    input logic                        last_block_input,

    output logic                       buffer_full,
    output logic                       last_block_output,
    output logic [IN_BUF_OUTPUT-1:0]   buffer_output,
    output logic                       buffer_output_valid
    );

    logic buffer_0_full;    
    logic buffer_0_input_valid;
    logic buffer_0_last_block_valid;
    logic buffer_0_output_ready;
    logic buffer_0_filling_last_block; 
    logic [IN_BUF_SIZE-1:0]  buffer_0_input;
    logic [IN_BUF_OUTPUT-1:0] buffer_0_output;

    logic buffer_1_full;
    logic buffer_1_input_valid;
    logic buffer_1_last_block_valid;
    logic buffer_1_output_ready;
    logic buffer_1_filling_last_block;
    logic [IN_BUF_SIZE-1:0]  buffer_1_input;
    logic [IN_BUF_OUTPUT-1:0] buffer_1_output;

    logic buffer_output_select;
    logic last_block_reg_q;

    assign buffer_full = buffer_0_full && buffer_1_full;
    assign buffer_0_input = buffer_input;
    assign buffer_1_input = buffer_input;

    assign last_block_output = last_block_reg_q && ~buffer_0_full && ~buffer_1_full && ~input_valid && ~buffer_0_filling_last_block && ~buffer_1_filling_last_block;

    EnResetReg #(.nbits(1)) last_block_reg (
                                            .clk(clk),
                                            .reset(reset),
                                            .en(last_block_input),
                                            .d(1'b1),
                                            .q(last_block_reg_q)

    );

    shift_register #(
                     .INPUT_BUFFER_SIZE(IN_BUF_SIZE), 
                     .OUTPUT_BUFFER_SIZE(IN_BUF_OUTPUT)
                    ) buffer_0 (
                              .clk(clk),
                              .reset(reset),
                              .buffer_input(buffer_0_input),          //input
                              .input_valid(buffer_0_input_valid),     //input
                              .output_ready(buffer_0_output_ready),   //input
                              .last_block(buffer_0_last_block_valid), //input
			      .filling_last_block(buffer_0_filling_last_block),
                              .buffer_full(buffer_0_full),            //output
                              .buffer_output(buffer_0_output)         //output
    );

    shift_register  #(
                      .INPUT_BUFFER_SIZE(IN_BUF_SIZE), 
                      .OUTPUT_BUFFER_SIZE(IN_BUF_OUTPUT)
                     ) buffer_1 (
                              .clk(clk),
                              .reset(reset),
                              .buffer_input(buffer_1_input),          //input
                              .input_valid(buffer_1_input_valid),     //input
                              .output_ready(buffer_1_output_ready),   //input
                              .last_block(buffer_1_last_block_valid), //input
			      .filling_last_block(buffer_1_filling_last_block),
                              .buffer_full(buffer_1_full),            //output
                              .buffer_output(buffer_1_output)         //output
    );


    enum {
	FILL_BUF_0,
	FILL_BUF_1,
	DO_NOT_FILL	
    } input_state, next_input_state;

    enum {
	OUTPUT_BUF_0,
	OUTPUT_BUF_1	
    } output_state, next_output_state;
   
    // Reset logic
    always_ff @ (posedge clk, posedge reset) begin
        if(reset) begin
            input_state  <= FILL_BUF_0;
            output_state <= OUTPUT_BUF_0;
        end else begin
            input_state <= next_input_state;
            output_state <= next_output_state;
        end
    end

    // Cycle Input Logic
    always_comb begin
        next_input_state = input_state;
        next_output_state = output_state;
        case (input_state)
            FILL_BUF_0: begin
                if (buffer_0_full && ~buffer_full && ~last_block_reg_q && ~last_block_input) begin
                    next_input_state = FILL_BUF_1;
                end
		else if (buffer_0_full && (last_block_reg_q || last_block_input)) begin
                    next_input_state = DO_NOT_FILL;
		end
            end
            FILL_BUF_1: begin
                if (buffer_1_full && ~buffer_full && ~last_block_reg_q && ~last_block_input) begin
                    next_input_state = FILL_BUF_0;
                end
		else if (buffer_1_full && (last_block_reg_q || last_block_input)) begin
                    next_input_state = DO_NOT_FILL;
		end
            end
            default:
                next_input_state = input_state;
        endcase


        case (output_state)
            OUTPUT_BUF_0: begin
                if (buffer_0_full && output_ready) begin
                    next_output_state = OUTPUT_BUF_1;
                end
            end
            OUTPUT_BUF_1: begin
                if (buffer_1_full && output_ready) begin
                    next_output_state = OUTPUT_BUF_0;
                end
            end
            default:
                next_output_state = output_state;
        endcase
    end

    logic fsm_0_input_valid;
    logic fsm_1_input_valid;

    assign buffer_0_input_valid = input_valid && fsm_0_input_valid;
    assign buffer_1_input_valid = input_valid && fsm_1_input_valid;

    assign buffer_0_last_block_valid = last_block_reg_q && fsm_0_input_valid;
    assign buffer_1_last_block_valid = last_block_reg_q && fsm_1_input_valid;

    always_comb begin
        fsm_0_input_valid = 0;
        fsm_1_input_valid = 0;

        case (input_state)
            FILL_BUF_0: begin
                fsm_0_input_valid = 1;
                if (buffer_0_full && ~buffer_full && ~last_block_reg_q) begin
                    fsm_1_input_valid = 1;
                end
            end
            FILL_BUF_1: begin
                fsm_1_input_valid = 1;
                if (buffer_1_full && ~buffer_full && ~last_block_reg_q) begin
                    fsm_0_input_valid = 1;
                end
            end
            DO_NOT_FILL: begin
               fsm_0_input_valid = 0;
               fsm_1_input_valid = 0;
            end
       endcase
    end    

    logic fsm_output_0;
    logic fsm_output_1;

    assign buffer_0_output_ready = output_ready && fsm_output_0;
    assign buffer_1_output_ready = output_ready && fsm_output_1;

    always_comb begin
       fsm_output_0 = 0;
       fsm_output_1 = 0;
       case (output_state)
            OUTPUT_BUF_0: begin
                fsm_output_0 = 1;
                fsm_output_1 = 0;
            end
            OUTPUT_BUF_1: begin
                fsm_output_0 = 0;
                fsm_output_1 = 1;
            end
       endcase
    end

   always_comb begin
       if (fsm_output_0) begin
           buffer_output       = buffer_0_output;
           buffer_output_valid = buffer_0_full;
       end else if (fsm_output_1) begin
           buffer_output       = buffer_1_output;
           buffer_output_valid = buffer_1_full;
       end

    end

endmodule


