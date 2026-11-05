# Examples

Hands-on code that complements the seminar's literature study.

## HDL building blocks

The [`verilog/`](../verilog/) and [`vhdl/`](../vhdl/) directories hold
small, simulation-verified streaming-vision modules: a scanline delay
buffer, a 3x3 window extractor, a configurable 3x3 convolution and a
Sobel edge magnitude stage.

These are the same primitives the studied accelerators are built from:
Li et al.'s kernel-partition design streams feature-map windows through
convolution engines, and edge-gradient stages like Sobel are the classic
pre-CNN front end for vision pipelines. Writing them at register
transfer level makes the seminar's dataflow discussion concrete: line
buffers are exactly the on-chip memory organisation that avoids repeated
off-chip reads, and the multiply-accumulate plus shift-and-saturate
stage is one quantised kernel evaluation.

Each HDL directory has its own README with module tables, run
instructions and an honest verification statement (simulation only, no
hardware claims yet).
