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

    // Some constants
    const int IDLE_CLOCKS = 1;

    // Other variables
    int num_test, result;

    // Create our input/output files
    const std::string FILENAME_IN = "test_vectors/keccak_in.txt";
    const char * FILE_OUT = "logs/output.txt";
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

    // Construct the Verilated model
    const std::unique_ptr<Vkeccak> top{new Vkeccak};

    // Set Vtop's input signals
    top->Clock = 0b0;
    top->Reset = 0b1;
    top->Start = 0b0;
    top->Din = 0x00000000000000000;
    top->Din_valid = 0b0;
    top->Last_block = 0b0;

    // Do reset and other prep before the main loop.
    while(main_time < 30 && !Verilated::gotFinish()) {
        top->Reset = 0b1;
        top->Start = 0b0;
        top->Din = 0x00000000000000000;
        top->Din_valid = 0b0;
        top->Last_block = 0b0;

        // Toggle the clock and increment the time.
        top->Clock = !top->Clock;
        main_time++;

        printf("RESET: Time: %d Reset: %d\n", main_time, top->Reset);
    }

    // Read the number of tests and start.
    top->Reset = 0;
    top->Start = 1;
    data_in >> line_in;
    num_test = std::stoi(line_in);

    // Toggle the clock and increment the time.
    top->Clock = !top->Clock;
    main_time++;
    top->Clock = !top->Clock;
    main_time++;

    // Read the first line of input data and hop into the loop.
    data_in >> line_in;

    // Main loop - simulate until $finish
    while (!Verilated::gotFinish()) {

        printf("READIN: Time: %d Num_tests: %d line_in: 0x%s\n", main_time, num_test, line_in);

        top->Clock = !top->Clock;
        main_time++;
        top->Clock = !top->Clock;
        main_time++;

        while(line_in[0] != '-') {

            if (!top->Clock) {
                if(top->Buffer_full) {
                    top->Din_valid = 0;
                } else {
                    uint64_t line_in_uint64;
                    line_in_uint64 = std::strtoull(line_in, NULL, 16);

                    sscanf(line_in, "%llX", &line_in_uint64);
                    data_in >> line_in;

                    top->Din = line_in_uint64;
                    top->Din_valid = 1;

                    printf("READIN2: Time: %d Buffer_full: %d line_in: %s Din: 0x%.16X\n", main_time, top->Buffer_full, line_in, top->Din);
                }
            }

            top->Clock = !top->Clock;
            main_time++;
            if(main_time > 100) return 0;
        }

        // If here, all lines read. Start looking at the potential
        // data coming on output.

        // Ensure that we are not putting more data in.
        top->Din_valid = 0;

        // Wait until buffer isn't full. Then, wait
        // until ready comes back high waiting at least
        // a clock tick before beginning to check.
        do {
            top->Clock = !top->Clock;
            main_time++;
            printf("BUFF_WAIT: Time: %d Buffer Full: %x\n", main_time, top->Buffer_full);
        } while(top->Buffer_full);

        do {
            top->Clock = !top->Clock;
            main_time++;
            printf("WAIT_READY: Time: %d Ready: %d\n", main_time, top->Ready);
            if (main_time > 300) return 1;
        } while(!top->Ready);

        // Pulse Last_block high for a single cycle.
        std::cout << "PULSE_LAST_BLOCK Time: " << main_time << std::endl;
        top->Clock = !top->Clock;
        main_time++;
        if(top->Clock) {
            top->Clock = !top->Clock;
            main_time++;
        }

        top->Last_block          = 1;
        std::cout << "LAST_BLOCK_HIGH Time: " << main_time << std::endl;
        top->Clock = !top->Clock;
        main_time++;
        top->Clock = !top->Clock;
        main_time++;

        top->Last_block          = 0;
        std::cout << "LAST_BLOCK_LOW Time: " << main_time << std::endl;
        top->Clock = !top->Clock;
        main_time++;
        top->Clock = !top->Clock;
        main_time++;

        // Keep looping while output data is coming.
        while(top->Dout_valid) {
            if(!top->Clock) {
                fprintf(file_out, "%llX\n", top->Dout);
                printf("DOut: Time: %d Dout_Valid: %X Dout: %llX\n", main_time, top->Dout_valid, top->Dout);
            }
            main_time++;
            top->Clock = !top->Clock;
            if(main_time > 300) return 0;
        }

        fprintf(file_out, "-\n");
        top->Start = 1;

        main_time++;
        top->Clock = !top->Clock;
        main_time++;
        top->Clock = !top->Clock;
        while(top->Clock) {
            main_time++;
            top->Clock = !top->Clock;
        }

        // Evaluate model
        // (If you have multiple models being simulated in the same
        // timestep then instead of eval(), call eval_step() on each, then
        // eval_end_step() on each. See the manual.)
        top->eval();

        // Read a line of input data.
        file_in >> line_in;
        if(line_in[0] == '.') {
            break;
        }
    }

    // Close file pointer
    fclose(file_out);

    // Final model cleanup
    top->final();

    // Coverage analysis (calling write only after the test is known to pass)
#if VM_COVERAGE
    Verilated::mkdir("logs");
    VerilatedCov::write("logs/coverage.dat");
#endif

    // Return good completion status
    // Don't use exit() or destructor won't get called
    return 0;
}
