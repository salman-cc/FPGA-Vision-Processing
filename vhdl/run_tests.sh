#!/bin/sh
# Muhammed Salman
#
# run_tests.sh - analyse, elaborate and run every VHDL testbench with
# GHDL (VHDL-2008). Exits non-zero on the first failing testbench.
#
# Usage: sh vhdl/run_tests.sh   (from the repository root)

set -e

cd "$(dirname "$0")"

BUILD=/tmp/fpga_vision_ghdl
rm -rf "$BUILD"
mkdir -p "$BUILD"

GHDLA="ghdl -a --std=08 --workdir=$BUILD"
GDLE="ghdl -e --std=08 --workdir=$BUILD"
GDLR="ghdl -r --std=08 --workdir=$BUILD"

$GHDLA line_buffer.vhd window_3x3.vhd conv3x3.vhd sobel_edge.vhd

for tb in tb_line_buffer tb_window_3x3 tb_conv3x3 tb_sobel_edge
do
    echo "== $tb"
    $GHDLA "tb/$tb.vhd"
    $GDLE "$tb"
    $GDLR "$tb"
done

echo "All VHDL testbenches passed."
