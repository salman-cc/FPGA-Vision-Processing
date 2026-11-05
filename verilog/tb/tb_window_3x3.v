// Muhammed Salman
//
// tb_window_3x3.v
//
// Self-checking testbench for window_3x3.
//
// Streams an 8x4 frame whose pixel values equal their linear index
// plus one. For every asserted window_valid the nine taps are compared
// against the golden frame positions: acceptance k must produce the
// window ending at k, i.e. taps k-18 .. k (top-left to bottom-right).

`timescale 1ns/1ps

module tb_window_3x3;

    localparam WIDTH  = 8;
    localparam HEIGHT = 4;
    localparam NPIX   = WIDTH * HEIGHT;

    reg        clk = 1'b0;
    reg        rst_n = 1'b0;
    reg        pixel_valid = 1'b0;
    reg  [7:0] pixel_in = 8'd0;
    wire [7:0] p11, p12, p13, p21, p22, p23, p31, p32, p33;
    wire       window_valid;

    integer errors = 0;
    integer checks = 0;
    integer accepted = 0;
    integer k;
    integer kw;

    window_3x3 #(
        .DATA_WIDTH  (8),
        .LINE_LENGTH (WIDTH)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .pixel_valid  (pixel_valid),
        .pixel_in     (pixel_in),
        .p11 (p11), .p12 (p12), .p13 (p13),
        .p21 (p21), .p22 (p22), .p23 (p23),
        .p31 (p31), .p32 (p32), .p33 (p33),
        .window_valid (window_valid)
    );

    always #5 clk = ~clk;

    task check_tap;
        input [7:0] got;
        input integer idx;   // frame index the tap should hold
        begin
            checks = checks + 1;
            if (got !== (idx + 1)) begin
                errors = errors + 1;
                $display("FAIL t=%0t tap got=%0d want=%0d",
                         $time, got, idx + 1);
            end
        end
    endtask

    // Checker: window_valid and the taps visible before this edge belong
    // to acceptance (accepted-1).
    always @(posedge clk) begin
        if (rst_n && window_valid) begin
            kw = accepted - 1;
            check_tap(p11, kw - 2*WIDTH - 2);
            check_tap(p12, kw - 2*WIDTH - 1);
            check_tap(p13, kw - 2*WIDTH);
            check_tap(p21, kw - WIDTH - 2);
            check_tap(p22, kw - WIDTH - 1);
            check_tap(p23, kw - WIDTH);
            check_tap(p31, kw - 2);
            check_tap(p32, kw - 1);
            check_tap(p33, kw);
        end
    end

    always @(posedge clk) begin
        if (rst_n && pixel_valid)
            accepted <= accepted + 1;
    end

    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        for (k = 0; k < NPIX; k = k + 1) begin
            @(negedge clk);
            pixel_valid = 1'b1;
            pixel_in    = k[7:0] + 8'd1;
        end
        @(negedge clk);
        pixel_valid = 1'b0;
        repeat (4) @(negedge clk);

        // 12 windows are expected: rows 2..3, columns 2..7 of the
        // acceptance grid.
        if (checks != 12 * 9) begin
            errors = errors + 1;
            $display("FAIL: ran %0d tap checks, want %0d",
                     checks, 12 * 9);
        end
        if (errors == 0)
            $display("PASS tb_window_3x3: %0d checks", checks);
        else begin
            $display("FAIL tb_window_3x3: %0d errors", errors);
            $fatal(1);
        end
        $finish;
    end

endmodule
