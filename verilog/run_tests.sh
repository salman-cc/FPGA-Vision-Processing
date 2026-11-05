#!/bin/sh
# Muhammed Salman
#
# run_tests.sh - compile and run every Verilog testbench with
# Icarus Verilog. Exits non-zero on the first failing testbench.
#
# Usage: sh verilog/run_tests.sh   (from the repository root)

set -e

cd "$(dirname "$0")"

for tb in tb/tb_line_buffer.v tb/tb_window_3x3.v tb/tb_conv3x3.v tb/tb_sobel_edge.v
do
    name=$(basename "$tb" .v)
    echo "== $name"
    iverilog -g2005 -o "/tmp/$name.vvp" \
        line_buffer.v window_3x3.v conv3x3.v sobel_edge.v "$tb"
    vvp "/tmp/$name.vvp"
done

echo "All Verilog testbenches passed."
