// Muhammed Salman
//
// sobel_edge.v
//
// Sobel edge magnitude for an 8-bit greyscale 3x3 window.
//
//   Gx = (p13 + 2*p23 + p33) - (p11 + 2*p21 + p31)
//   Gy = (p31 + 2*p32 + p33) - (p11 + 2*p12 + p13)
//
// magnitude = |Gx| + |Gy|, saturated to 255. The |Gx| + |Gy| form is
// the common resource-light approximation of sqrt(Gx^2 + Gy^2); it
// overestimates diagonal edges by up to about 41 percent, which is
// acceptable for a thresholded edge flag but worth knowing when the
// magnitude itself is consumed.
//
// The result is registered; out_valid follows in_valid by one cycle.

module sobel_edge #(
    parameter DATA_WIDTH = 8
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

    localparam SUM_WIDTH = DATA_WIDTH + 3;  // max |Gx| = 4*255 = 1020

    wire signed [SUM_WIDTH-1:0] t13 = {3'b000, p13};
    wire signed [SUM_WIDTH-1:0] t23 = {3'b000, p23};
    wire signed [SUM_WIDTH-1:0] t33 = {3'b000, p33};
    wire signed [SUM_WIDTH-1:0] t11 = {3'b000, p11};
    wire signed [SUM_WIDTH-1:0] t21 = {3'b000, p21};
    wire signed [SUM_WIDTH-1:0] t31 = {3'b000, p31};
    wire signed [SUM_WIDTH-1:0] t12 = {3'b000, p12};
    wire signed [SUM_WIDTH-1:0] t32 = {3'b000, p32};

    wire signed [SUM_WIDTH-1:0] gx = (t13 + (t23 << 1) + t33)
                                   - (t11 + (t21 << 1) + t31);
    wire signed [SUM_WIDTH-1:0] gy = (t31 + (t32 << 1) + t33)
                                   - (t11 + (t12 << 1) + t13);

    wire [SUM_WIDTH-1:0] abs_gx = gx[SUM_WIDTH-1] ? -gx : gx;
    wire [SUM_WIDTH-1:0] abs_gy = gy[SUM_WIDTH-1] ? -gy : gy;
    wire [SUM_WIDTH:0]   mag    = {1'b0, abs_gx} + {1'b0, abs_gy};

    always @(posedge clk) begin
        if (in_valid) begin
            if (mag > {1'b0, {DATA_WIDTH{1'b1}}})
                pixel_out <= {DATA_WIDTH{1'b1}};
            else
                pixel_out <= mag[DATA_WIDTH-1:0];
            out_valid <= 1'b1;
        end else begin
            out_valid <= 1'b0;
        end
    end

endmodule
