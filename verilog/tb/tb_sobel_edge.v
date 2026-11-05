// Muhammed Salman
//
// tb_sobel_edge.v
//
// Self-checking integration testbench: window_3x3 feeding sobel_edge
// over an 8x6 frame with a vertical step edge (columns 0-3 dark,
// columns 4-7 bright).
//
// Golden magnitudes are recomputed in the testbench from the frame
// with plain integer arithmetic: mag = |Gx| + |Gy| saturated at 255.
// Directed expectations: flat interiors give 0, the two centre columns
// straddling the step give the saturated maximum (768 -> 255).

`timescale 1ns/1ps

module tb_sobel_edge;

    localparam WIDTH  = 8;
    localparam HEIGHT = 6;
    localparam NPIX   = WIDTH * HEIGHT;

    reg        clk = 1'b0;
    reg        rst_n = 1'b0;
    reg        pixel_valid = 1'b0;
    reg  [7:0] pixel_in = 8'd0;
    wire [7:0] p11, p12, p13, p21, p22, p23, p31, p32, p33;
    wire       window_valid;

    wire [7:0] edge_out;
    wire       edge_valid;

    integer errors = 0;
    integer checks = 0;
    integer accepted = 0;
    integer k;
    integer k_win = -1;
    integer gx, gy, mag, c;

    reg [7:0] frame [0:NPIX-1];

    window_3x3 #(
        .DATA_WIDTH  (8),
        .LINE_LENGTH (WIDTH)
    ) dut_win (
        .clk          (clk),
        .rst_n        (rst_n),
        .pixel_valid  (pixel_valid),
        .pixel_in     (pixel_in),
        .p11 (p11), .p12 (p12), .p13 (p13),
        .p21 (p21), .p22 (p22), .p23 (p23),
        .p31 (p31), .p32 (p32), .p33 (p33),
        .window_valid (window_valid)
    );

    sobel_edge dut_sobel (
        .clk (clk), .in_valid (window_valid),
        .p11 (p11), .p12 (p12), .p13 (p13),
        .p21 (p21), .p22 (p22), .p23 (p23),
        .p31 (p31), .p32 (p32), .p33 (p33),
        .pixel_out (edge_out), .out_valid (edge_valid)
    );

    always #5 clk = ~clk;

    // Track which window the Sobel stage consumed last cycle.
    always @(posedge clk) begin
        if (rst_n && window_valid)
            k_win <= accepted - 1;
    end

    always @(posedge clk) begin
        if (rst_n && pixel_valid)
            accepted <= accepted + 1;
    end

    always @(posedge clk) begin
        if (rst_n && edge_valid) begin
            // Golden Sobel over the window ending at acceptance k_win.
            gx = (frame[k_win-16] + 2*frame[k_win-8] + frame[k_win])
               - (frame[k_win-18] + 2*frame[k_win-10] + frame[k_win-2]);
            gy = (frame[k_win-2] + 2*frame[k_win-1] + frame[k_win])
               - (frame[k_win-18] + 2*frame[k_win-17] + frame[k_win-16]);
            if (gx < 0) gx = -gx;
            if (gy < 0) gy = -gy;
            mag = gx + gy;
            if (mag > 255) mag = 255;

            checks = checks + 1;
            if (edge_out !== mag[7:0]) begin
                errors = errors + 1;
                $display("FAIL t=%0t got=%0d want=%0d",
                         $time, edge_out, mag);
            end

            // Directed check: only centre columns 3 and 4 see the step.
            c = (k_win % WIDTH) - 1;
            if ((c == 3 || c == 4) && mag != 255) begin
                errors = errors + 1;
                $display("FAIL directed: centre col %0d should saturate",
                         c);
            end
            if ((c == 1 || c == 2 || c == 5 || c == 6) && mag != 0) begin
                errors = errors + 1;
                $display("FAIL directed: centre col %0d should be flat",
                         c);
            end
        end
    end

    initial begin
        for (k = 0; k < NPIX; k = k + 1)
            frame[k] = ((k % WIDTH) < 4) ? 8'd32 : 8'd224;

        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        for (k = 0; k < NPIX; k = k + 1) begin
            @(negedge clk);
            pixel_valid = 1'b1;
            pixel_in    = frame[k];
        end
        @(negedge clk);
        pixel_valid = 1'b0;
        repeat (4) @(negedge clk);

        // 4 valid rows (2..5) x 6 valid centre columns = 24 windows.
        if (checks != 24) begin
            errors = errors + 1;
            $display("FAIL: ran %0d sobel checks, want 24", checks);
        end
        if (errors == 0)
            $display("PASS tb_sobel_edge: %0d checks", checks);
        else begin
            $display("FAIL tb_sobel_edge: %0d errors", errors);
            $fatal(1);
        end
        $finish;
    end

endmodule
