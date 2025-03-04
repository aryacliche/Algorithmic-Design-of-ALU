#!/bin/bash

# This script will compile and produce the wave for each of the individual questions.
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 <folder> [<wave_file_name>]"
    exit 1
fi

folder=$1
wave_file_name=${2:-wave}

if [ "$folder" == "q1" ]; then
    rm *.cf
    ghdl -a --std=08 q1/datapath_8bit.vhdl
    ghdl -a --std=08 q1/multiplier.vhdl
    ghdl -a --std=08 q1/testbench.vhdl
    ghdl -e --std=08 multiplier
    ghdl -e --std=08 testbench
    ghdl -r --std=08 testbench --stop-time=500us --wave=$"wave_file_name".ghw

elif [ "$folder" == "q2" ]; then
    echo "Not implemented yet"
    exit 1
fi