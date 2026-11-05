// Muhammed Salman
//
// tb_line_buffer.v
//
// Self-checking testbench for line_buffer.
//
// Drives 24 pixels with intermittent gaps (ce low) and checks that
// pixel_out always returns the pixel accepted exactly LINE_LENGTH
// accepted-pixels earlier.

`timescale 1ns/1ps

module tb_line_buffer;

    localparam LINE_LENGTH = 8;

    reg         clk = 1'b0;
    reg         ce = 1'b0;
    reg  [7:0]  pixel_in = 8'd0;
    wire [7:0]  pixel_out;

    integer errors = 0;
    integer checks = 0;
    integer accepted = 0;   // pixels accepted so far
    integer i;

    // Values already accepted, for golden comparison.
    reg [7:0] history [0:63];

    line_buffer #(
        .DATA_WIDTH  (8),
        .LINE_LENGTH (LINE_LENGTH)
    ) dut (
        .clk       (clk),
        .ce        (ce),
        .pixel_in  (pixel_in),
        .pixel_out (pixel_out)
    );

    always #5 clk = ~clk;

    task expect;
        input [7:0] want;
        begin
            checks = checks + 1;
            if (pixel_out !== want) begin
                errors = errors + 1;
                $display("FAIL t=%0t pixel_out=%0d want=%0d",
                         $time, pixel_out, want);
            end
        end
    endtask

    initial begin
        @(negedge clk);
        for (i = 0; i < 24; i = i + 1) begin
            // Insert a stall cycle after every third pixel.
            if ((i % 3) == 2) begin
                ce = 1'b0;
                @(negedge clk);
                // Output must hold the oldest pixel while stalled.
                if (accepted >= LINE_LENGTH)
                    expect(history[accepted - LINE_LENGTH]);
            end
            ce        = 1'b1;
            pixel_in  = 8'd100 + i[7:0];
            history[i] = 8'd100 + i[7:0];
            @(posedge clk);
            #1;
            ce = 1'b0;
            accepted = accepted + 1;
            if (accepted > LINE_LENGTH)
                expect(history[accepted - LINE_LENGTH]);
            @(negedge clk);
        end

        if (errors == 0)
            $display("PASS tb_line_buffer: %0d checks", checks);
        else begin
            $display("FAIL tb_line_buffer: %0d of %0d checks failed",
                     errors, checks);
            $fatal(1);
        end
        $finish;
    end

endmodule
