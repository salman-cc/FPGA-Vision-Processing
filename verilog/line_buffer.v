// Muhammed Salman
//
// line_buffer.v
//
// One-scanline delay for a streaming video pipeline.
//
// Pixels enter through pixel_in while ce is high and leave through
// pixel_out exactly LINE_LENGTH accepted pixels later. The buffer is a
// circular memory so it maps onto a block RAM on most FPGAs.
//
// The module has no frame knowledge of its own; window_3x3 uses two of
// these plus tap registers to rebuild a 3x3 neighbourhood.

module line_buffer #(
    parameter DATA_WIDTH  = 8,
    parameter LINE_LENGTH = 640
) (
    input  wire                  clk,
    input  wire                  ce,
    input  wire [DATA_WIDTH-1:0] pixel_in,
    output wire [DATA_WIDTH-1:0] pixel_out
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

    localparam ADDR_WIDTH = (LINE_LENGTH > 1) ? clog2(LINE_LENGTH) : 1;

    reg [DATA_WIDTH-1:0] mem [0:LINE_LENGTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr = {ADDR_WIDTH{1'b0}};

    // The location about to be overwritten still holds the oldest pixel,
    // so the combinational read returns the pixel written LINE_LENGTH
    // accepted pixels ago.
    assign pixel_out = mem[wr_ptr];

    always @(posedge clk) begin
        if (ce) begin
            mem[wr_ptr] <= pixel_in;
            if (wr_ptr == LINE_LENGTH - 1)
                wr_ptr <= {ADDR_WIDTH{1'b0}};
            else
                wr_ptr <= wr_ptr + 1'b1;
        end
    end

endmodule
