# Verilog vision pipeline examples

Small, original Verilog building blocks for streaming image processing,
matching the accelerator topics studied in this repository's seminar
report. Each module is synthesizable and verified by the self-checking
testbenches in [`tb/`](tb/).

## Modules

| Module | Function |
| ------ | -------- |
| [`line_buffer.v`](line_buffer.v) | One-scanline delay as a circular buffer (block-RAM friendly) |
| [`window_3x3.v`](window_3x3.v) | Rebuilds 3x3 pixel neighbourhoods from a raster stream using two line buffers |
| [`conv3x3.v`](conv3x3.v) | Single-cycle 3x3 convolution, signed coefficients, shift-and-saturate output |
| [`sobel_edge.v`](sobel_edge.v) | Sobel gradient magnitude (\|Gx\| + \|Gy\|, saturated) |

`window_3x3` suppresses windows that would need pixels outside the
frame, so a W-wide input line produces W-2 valid output windows starting
from the third input line. `conv3x3` and `sobel_edge` add one clock of
latency behind the window stage.

## Running the testbenches

Requires [Icarus Verilog](https://steveicarus.github.io/iverilog/)
(`iverilog`, `vvp`):

```sh
sh verilog/run_tests.sh
```

The script compiles every testbench in `tb/` and runs it; each
testbench checks the design against an independent golden model and
prints `PASS` or aborts with `FAIL`.

## Verification status

Simulated with Icarus Verilog 11.0 (`-g2005`) on 5 November 2026; all
four testbenches pass (line buffer, window extraction, convolution with
two kernels, Sobel on a synthetic step edge). These designs have **not**
been synthesized or run on FPGA hardware yet, so no timing or resource
numbers are claimed.
