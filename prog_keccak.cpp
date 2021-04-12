// ============================================================================
// Project:   Keccak Verilog Module
// Author:    Josh Moles
// Created:   4 April 2021
//
// Description:
//   Program to aid in testing the code designed for running in Verilator.
//
// This is based off examples from https://github.com/verilator/verilator/.
//
// The MIT License (MIT)
//
// Copyright (c) 2021 Josh Moles
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

#include <iostream>
#include <fstream>
#include <memory>
#include <sstream>

// Include common routines
#include <verilated.h>

// Include model header, generated from Verilating "Vtb_keccak.sv"
#include "Vkeccak.h"

// Constants
const std::string FILENAME_IN = "test_vectors/keccak_in.txt";
const char * FILE_OUT = "logs/output.txt";
const int MAX_RUNTIME = 3000000;
const bool DEBUG = false;

// Current simulation time (64-bit unsigned)
vluint64_t main_time = 0;
// Called by $time in Verilog
double sc_time_stamp() {
    return main_time;  // Note does conversion to real, to match SystemC
}

int main(int argc, char** argv, char** env) {
    // Prevent unused variable warnings
    if (false && argc && argv && env) {}

    // Create logs/ directory in case we have traces to put under it
    Verilated::mkdir("logs");

    // Other variables
    int num_test, result;

    // Create our input/output files
    char line_in[16];
    std::string data_file_in, line_out;
    std::FILE * file_out;
    file_out = fopen(FILE_OUT, "w");

    // Read input file in
    std::ifstream file_in (FILENAME_IN, std::ifstream::in);
    std::stringstream data_in;
    data_in << file_in.rdbuf();
    file_in.close();

    // Set debug level, 0 is off, 9 is highest presently used
    // May be overridden by commandArgs argument parsing
    Verilated::debug(0);

    // Randomization reset policy
    // May be overridden by commandArgs argument parsing
    Verilated::randReset(2);

    // Verilator must compute traced signals
    Verilated::traceEverOn(true);

    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    // This needs to be called before you create any model
    Verilated::commandArgs(argc, argv);

    // Make directory for logs.
    Verilated::mkdir("logs");

    // Construct the Verilated model
    const std::unique_ptr<Vkeccak> top{new Vkeccak};

    // Set initial values on Vkeccak's input signals
    top->Clock = false;
    top->Reset = true;
    top->Start = false;
    top->Din = 0;
    top->Din_valid = false;
    top->Last_block = false;

    enum States {
        RESET,
        NUM_TEST,
        DATA_IN,
        DATA_DONE,
        LAST_BLOCK_LOW,
        DATA_OUT,
        DONE
    };

    // Variables used for control flow
    States curr_state = RESET;  // State machine state
    int reset_count = 0;         // Number of times the reset loop as ran.
    const int RESET_MAX = 30;   // Number of clock cycles to perform reset.
    int numTests = 0;           // Number of tests read in from file.
    int dout_count = 0;         // Number of times dout has passed valid data.

    // The main loop
    while (!Verilated::gotFinish()) {
        // Increment time and clock
        top->Clock = !top->Clock;
        main_time++;

        if(!top->Clock) {

            if(main_time > MAX_RUNTIME) {
                curr_state = DONE;
            }

            switch(curr_state) {
                case RESET:
                    // In reset
                    top->Reset = true;
                    top->Start = false;
                    top->Din = 0x00000000000000000;
                    top->Din_valid = false;
                    top->Last_block = false;

                    if(DEBUG) printf("RESET: Time: %d Reset: %d reset_count: %d\n", main_time, top->Reset, reset_count);

                    reset_count++;
                    if(reset_count >= RESET_MAX) {
                        curr_state = NUM_TEST;
                    }
                    break;
                case NUM_TEST:
                    // Next phase after reset. End reset
                    top->Reset = false;
                    top->Start = true;

                    // Need to read the first line of the file in and get the number of tests.
                    data_in >> line_in;
                    num_test = std::stoi(line_in);

                    if(DEBUG) printf("NUM_TEST: Time: %d #Tests: %d\n", main_time, num_test);
                    curr_state = DATA_IN;
                    break;
                case DATA_IN:
                    top->Start = false;

                    if(top->Buffer_full) {
                        break;
                    }

                    data_in >> line_in;

                    if(line_in[0] == '-') {
                        curr_state = DATA_DONE;
                        top->Din_valid = false;
                        break;
                    } else if (line_in[0] == '.') {
                        curr_state = DONE;
                        top->Din_valid = false;
                        break;
                    }

                    QData line_in_int64;
                    sscanf(line_in, "%llx", &line_in_int64);

                    top->Din = line_in_int64;
                    top->Din_valid = true;

                    if(DEBUG) printf("DATA_IN: Time: %d Buffer_full: %d Din: 0x%.16llX\n", main_time, top->Buffer_full, top->Din);

                    break;

                case DATA_DONE:
                    top->Din_valid = false;

                    if(DEBUG) printf("DATA_DONE: Time: %d Buffer_full: %d Ready: %d Last_Block: %d\n", main_time, top->Buffer_full, top->Ready, top->Last_block);

                    if (top->Buffer_full) break;
                    if (!top->Ready) break;

                    top->Last_block = true;
                    curr_state = DATA_OUT;
                    if(DEBUG) printf("DATA_DONE: Time: %d Buffer_full: %d Ready: %d Last_Block: %d\n", main_time, top->Buffer_full, top->Ready, top->Last_block);

                    break;

                case DATA_OUT:
                    top->Last_block = false;
                    if(top->Dout_valid) {
                        fprintf(file_out, "%.16llX\n", top->Dout);
                        dout_count++;
                    } else if (dout_count > 3) {
                        fprintf(file_out, "-\n");
                        dout_count = 0;
                        top->Start = true;
                        curr_state = DATA_IN;
                    }
                    if(DEBUG) printf("DATA_OUT: Time: %d Dout_Valid: %X Start: %d Dout: %llX\n", main_time, top->Dout_valid, top->Start, top->Dout);
                    break;

                case DONE:
                    // We are done. Wrap up things and quit.
                    top->eval();

                    // Close file pointer
                    fclose(file_out);

                    // Final model cleanup
                    top->final();

                        // Coverage analysis (calling write only after the test is known to pass)
                    #if VM_COVERAGE
                        printf("Writing coverage analysis.");
                        Verilated::mkdir("logs");
                        VerilatedCov::write("logs/coverage.dat");
                    #endif

                    // Return good completion status
                    // Don't use exit() or destructor won't get called
                    return 0;

                    break;

                default:
                    curr_state = RESET;
                    break;

            }
        } // end if !top->Clock()

        // Evaluate model
        // (If you have multiple models being simulated in the same
        // timestep then instead of eval(), call eval_step() on each, then
        // eval_end_step() on each. See the manual.)
        top->eval();

    } // end while !gotFinished()
} // end main
