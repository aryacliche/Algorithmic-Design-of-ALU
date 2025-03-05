#!/bin/bash

folder_name=$1
time_in_us=${2:-500}

cd $folder_name
ghdl -a --std=08 *.vhdl
ghdl -e --std=08 testbench
ghdl -r --std=08 testbench --stop-time=${time_in_us}us --wave=wave.ghw
gtkwave wave.ghw
