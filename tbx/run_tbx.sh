#!/bin/bash

mkdir -p runDir
cd runDir

tbxlib work
tbxmap work work

cat > tbx.config << "EOF" 
rtlc -partition_module_xrtl tbx_keccak
rtlc -debug
velsyn -D1S -num_boards 1
EOF

veanalyze -work work -f ../tbx_vfiles.f

tbxcomp -top tbx_keccak -cfiles ../tbx_keccak.cpp

tbxrun

mv output_tbx.txt ../
cd ../