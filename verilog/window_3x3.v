// Muhammed Salman
//
// window_3x3.v
//
// Turns a raster-scanned pixel stream into 3x3 pixel neighbourhoods.
//
// Two line buffers delay the stream by one and two scanlines. Three
// tap registers per row then expose the 3x3 window ending at the
// current pixel. Pixel ordering is raster scan with a constant line
// length of LINE_LENGTH pixels and no blanking.
//
// Tap naming: pRC, row 1 is the oldest (two lines back), column 3 is
// the newest pixel in each row. p22 is the window centre.
//
// window_valid pulses high for one clock when the taps hold a complete
// window whose centre is a real pixel. Windows that would need pixels
// from outside the frame (first two lines, first two columns) are
// suppressed, so downstream logic sees a (LINE_LENGTH-2) wide output
// per line starting from the third input line.

module window_3x3 #(
    parameter DATA_WIDTH  = 8,
    parameter LINE_LENGTH = 640
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  pixel_valid,
    input  wire [DATA_WIDTH-1:0] pixel_in,
    output reg  [DATA_WIDTH-1:0] p11,
    output reg  [DATA_WIDTH-1:0] p12,
    output reg  [DATA_WIDTH-1:0] p13,
    output reg  [DATA_WIDTH-1:0] p21,
    output reg  [DATA_WIDTH-1:0] p22,
    output reg  [DATA_WIDTH-1:0] p23,
    output reg  [DATA_WIDTH-1:0] p31,
    output reg  [DATA_WIDTH-1:0] p32,
    output reg  [DATA_WIDTH-1:0] p33,
    output reg                   window_valid
);

    wire [DATA_WIDTH-1:0] line1_out;  // stream delayed by one line
    wire [DATA_WIDTH-1:0] line2_out;  // stream delayed by two lines

    line_buffer #(
        .DATA_WIDTH  (DATA_WIDTH),
        .LINE_LENGTH (LINE_LENGTH)
    ) lb1 (
        .clk       (clk),
        .ce        (pixel_valid),
        .pixel_in  (pixel_in),
        .pixel_out (line1_out)
    );

    line_buffer #(
        .DATA_WIDTH  (DATA_WIDTH),
        .LINE_LENGTH (LINE_LENGTH)
    ) lb2 (
        .clk       (clk),
        .ce        (pixel_valid),
        .pixel_in  (line1_out),
        .pixel_out (line2_out)
    );

    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    localparam COL_WIDTH = (LINE_LENGTH > 1) ? clog2(LINE_LENGTH) : 1;

    reg [COL_WIDTH-1:0] col = {COL_WIDTH{1'b0}};
    reg [31:0]          row = 32'd0;

    always @(posedge clk) begin
        if (!rst_n) begin
            col          <= {COL_WIDTH{1'b0}};
            row          <= 32'd0;
            p11 <= {DATA_WIDTH{1'b0}}; p12 <= {DATA_WIDTH{1'b0}};
            p13 <= {DATA_WIDTH{1'b0}};
            p21 <= {DATA_WIDTH{1'b0}}; p22 <= {DATA_WIDTH{1'b0}};
            p23 <= {DATA_WIDTH{1'b0}};
            p31 <= {DATA_WIDTH{1'b0}}; p32 <= {DATA_WIDTH{1'b0}};
            p33 <= {DATA_WIDTH{1'b0}};
            window_valid <= 1'b0;
        end else if (pixel_valid) begin
            p11 <= p12;       p12 <= p13;       p13 <= line2_out;
            p21 <= p22;       p22 <= p23;       p23 <= line1_out;
            p31 <= p32;       p32 <= p33;       p33 <= pixel_in;
            // A full window exists once at least two earlier pixels on
            // this line and two earlier lines have been accepted.
            window_valid <= (col >= 2) && (row >= 2);
            if (col == LINE_LENGTH - 1) begin
                col <= {COL_WIDTH{1'b0}};
                row <= row + 1'b1;
            end else begin
                col <= col + 1'b1;
            end
        end else begin
            window_valid <= 1'b0;
        end
    end

endmodule
