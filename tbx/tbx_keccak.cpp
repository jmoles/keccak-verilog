// ============================================================================
// Project:   Keccak Verilog Module
// Author:    Josh Moles
// Created:   3 June 2013
//
// Description:
//      DPI-C functions for use in Veloce TBX environment.
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
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <iomanip>

#include "tbxbindings.h"
#include "svdpi.h"

static const char * 	inFileName 			= "../../test_vectors/keccak_in.txt";
static const char * 	outFileName 		= "output_tbx.txt";
static const char * 	debugLogFileName 	= "output_TEST_tbx.txt";

static int numTests 						= 0;
static bool period 							= false;
static bool dash 							= false;
static bool initDone						= false;
static bool DEBUG							= true;

static std::string      	line;
static std::ifstream    	inFile;
static std::ofstream    	outFile;
static std::ofstream		debugLogFile;

// Function to read in a line and see if it is a dash, period, or
// actually data. If dash, means that this is end of data hunk.
// A period indicates the end of file. Otherwise, the line is
// intrepreted as a number.
int ReadLine()
{
	// Temporary string used for comparing input from stream.
	std::string tempStr;

	// Fetch a line, put in an input string stream, and then
	// put it in the temporary string.
	std::getline(inFile, line);
	std::istringstream iss(line);
	iss >> tempStr;

	if(tempStr == "-") 
	{
		dash 	= true;
		period 	= false;

		if(DEBUG)
			debugLogFile << "Saw a dash!" << std::endl;
	} 
	else if (tempStr == ".") 
	{
		dash 	= false;
		period 	= true;

		if(DEBUG)
			debugLogFile << "Saw a period!" << std::endl;
	} 
	else
	{
		// It is a number
		dash 	= false;
		period 	= false;
	}

	return 0;


}

// Opens up the files and reads in the number of tests
int PrepareFiles()
{
	if(!initDone)
	{
		// Open up all of the I/O files.
		inFile.open(inFileName);
		outFile.open(outFileName);
		if(DEBUG)
			debugLogFile.open(debugLogFileName);

		// Read the number of tests from inFile.
		std::getline(inFile, line);
		std::istringstream iss(line);
		iss >> numTests;

		initDone = true;
		
	}

	return 0;

}

// Returns the number of tests as read from input file.
int GetNumTestsFromSoftware(svBitVecVal* num_test)
{
	*num_test = numTests;
	return 0;
}

// Returns true if a dash (end of hunk) was just seen.
int SeeDash(svBit* see_dash)
{
	*see_dash = dash;
	return 0;
}

// Returns true if a period (end of file) was just seen.
int SeePeriod(svBit* see_period)
{
	*see_period = period;
	return 0;
}

// Returns the line of data converted to long long int.
// TODO: Check if this description is accurate.
int GetDataFromSoftare(svBitVecVal* dataInHigh, svBitVecVal* dataInLow)
{
	std::stringstream ss1, ss2;
	std::string ts1, ts2;

	ts1 = line.substr(0,8);
	ss1 << std::setw(8) << std::hex << std::setfill('0') << ts1;
	ss1 >> *dataInHigh;

	ts2 = line.substr(8,8);
	ss2 << std::setw(8) << std::hex << std::setfill('0') << ts2;
	ss2 >> *dataInLow;

	if(DEBUG) 
	{	
		debugLogFile << "Reading in data!" << std::endl;
		debugLogFile << std::setw(8) << std::hex << std::setfill('0')  << *dataInHigh;
		debugLogFile << std::setw(8) << std::hex << std::setfill('0')  << *dataInLow;
		debugLogFile << std::endl;
	}

	return 0;
}

// Receives data from the test bench and prints it to output file.
int SendDataToSoftware(const svBitVecVal* dataOutHigh, const svBitVecVal* dataOutLow)
{
	unsigned int highData = *dataOutHigh;
	unsigned int lowData = *dataOutLow;

	outFile << std::setw(8) << std::hex << std::setfill('0')  << highData;
	outFile << std::setw(8) << std::hex << std::setfill('0')  << lowData;
	outFile << std::endl;

	// Reset the fill character to a space (the default).
	std::setfill(' ');

	if (DEBUG) 
	{
		debugLogFile << "Raw output [63:32]: " << highData << std::endl;
		debugLogFile << "Raw output [31:0 ]: " << lowData << std::endl;
	}

	return 0;
}

// Message from testbench to indicate end of data hunk and put - in file.
int DoneWithSend()
{
	outFile << "-" << std::endl;
	return 0;
}

// Called when simulation is complete and just cleans up stuff on this side.
int SimulationComplete()
{
	inFile.close();
	outFile.close();
	if (DEBUG)
		debugLogFile.close();
	return 0;
}