# VHDL vision pipeline examples

The same streaming vision building blocks as in
[`../verilog/`](../verilog/), written in VHDL-2008. Each module is
synthesizable and verified by the self-checking testbenches in
[`tb/`](tb/).

## Modules

| Module | Function |
| ------ | -------- |
| [`line_buffer.vhd`](line_buffer.vhd) | One-scanline delay as a circular buffer (block-RAM friendly) |
| [`window_3x3.vhd`](window_3x3.vhd) | Rebuilds 3x3 pixel neighbourhoods from a raster stream using two line buffers |
| [`conv3x3.vhd`](conv3x3.vhd) | Single-cycle 3x3 convolution, signed coefficients, shift-and-saturate output |
| [`sobel_edge.vhd`](sobel_edge.vhd) | Sobel gradient magnitude (\|Gx\| + \|Gy\|, saturated) |

`window_3x3` suppresses windows that would need pixels outside the
frame, so a W-wide input line produces W-2 valid output windows starting
from the third input line. `conv3x3` and `sobel_edge` add one clock of
latency behind the window stage.

## Running the testbenches

Requires [GHDL](https://ghdl.github.io/ghdl/):

```sh
sh vhdl/run_tests.sh
```

The script analyses, elaborates and runs every testbench in `tb/` with
VHDL-2008; each testbench checks the design against an independent
golden model and prints `PASS` or aborts with `FAIL`.

## Verification status

Simulated with GHDL 1.0.0 (mcode backend, `--std=08`) on 5 November
2026; all four testbenches pass (line buffer, window extraction,
convolution with two kernels, Sobel on a synthetic step edge). These
designs have **not** been synthesized or run on FPGA hardware yet, so no
timing or resource numbers are claimed.
