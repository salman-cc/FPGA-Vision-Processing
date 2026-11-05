// Muhammed Salman
//
// conv3x3.v
//
// Single-cycle 3x3 convolution for an 8-bit greyscale window.
//
// The nine unsigned taps and nine signed coefficients form one
// multiply-accumulate. The accumulated sum is arithmetic-shifted right
// by SHIFT bits and saturated into the unsigned 8-bit output range.
// The result is registered, so the module adds one clock of latency and
// out_valid follows in_valid by exactly one cycle.
//
// Choosing coefficients and SHIFT is a system decision: for example a
// 3x3 box blur uses all-ones coefficients with SHIFT 4 (divide by 16,
// slightly darker than the true mean), while an identity pass-through
// uses K22 = 1 with SHIFT 0.

module conv3x3 #(
    parameter DATA_WIDTH = 8,
    parameter signed [7:0] K11 = 0,
    parameter signed [7:0] K12 = 0,
    parameter signed [7:0] K13 = 0,
    parameter signed [7:0] K21 = 0,
    parameter signed [7:0] K22 = 1,
    parameter signed [7:0] K23 = 0,
    parameter signed [7:0] K31 = 0,
    parameter signed [7:0] K32 = 0,
    parameter signed [7:0] K33 = 0,
    parameter SHIFT = 0
) (
    input  wire                  clk,
    input  wire                  in_valid,
    input  wire [DATA_WIDTH-1:0] p11,
    input  wire [DATA_WIDTH-1:0] p12,
    input  wire [DATA_WIDTH-1:0] p13,
    input  wire [DATA_WIDTH-1:0] p21,
    input  wire [DATA_WIDTH-1:0] p22,
    input  wire [DATA_WIDTH-1:0] p23,
    input  wire [DATA_WIDTH-1:0] p31,
    input  wire [DATA_WIDTH-1:0] p32,
    input  wire [DATA_WIDTH-1:0] p33,
    output reg  [DATA_WIDTH-1:0] pixel_out,
    output reg                   out_valid
);

    // Taps are zero-extended to signed values before the MAC so the
    // pixel data stays unsigned while the coefficients stay signed.
    wire signed [DATA_WIDTH:0] s11 = {1'b0, p11};
    wire signed [DATA_WIDTH:0] s12 = {1'b0, p12};
    wire signed [DATA_WIDTH:0] s13 = {1'b0, p13};
    wire signed [DATA_WIDTH:0] s21 = {1'b0, p21};
    wire signed [DATA_WIDTH:0] s22 = {1'b0, p22};
    wire signed [DATA_WIDTH:0] s23 = {1'b0, p23};
    wire signed [DATA_WIDTH:0] s31 = {1'b0, p31};
    wire signed [DATA_WIDTH:0] s32 = {1'b0, p32};
    wire signed [DATA_WIDTH:0] s33 = {1'b0, p33};

    // 9 products of (8-bit coeff) x (9-bit unsigned tap) need at most
    // 9 + 8 + 4 = 21 signed bits; ACC_WIDTH keeps headroom.
    localparam ACC_WIDTH = DATA_WIDTH + 13;

    wire signed [ACC_WIDTH-1:0] acc =
          K11 * s11 + K12 * s12 + K13 * s13
        + K21 * s21 + K22 * s22 + K23 * s23
        + K31 * s31 + K32 * s32 + K33 * s33;

    wire signed [ACC_WIDTH-1:0] scaled = acc >>> SHIFT;

    always @(posedge clk) begin
        if (in_valid) begin
            if (scaled < 0)
                pixel_out <= {DATA_WIDTH{1'b0}};
            else if (scaled > {1'b0, {DATA_WIDTH{1'b1}}})
                pixel_out <= {DATA_WIDTH{1'b1}};
            else
                pixel_out <= scaled[DATA_WIDTH-1:0];
            out_valid <= 1'b1;
        end else begin
            out_valid <= 1'b0;
        end
    end

endmodule
