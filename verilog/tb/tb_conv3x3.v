// Muhammed Salman
//
// tb_conv3x3.v
//
// Self-checking integration testbench: window_3x3 feeding two conv3x3
// instances with different kernels over the same 8x4 frame.
//
//   conv_id:   identity kernel (K22=1, SHIFT=0) -> output = centre tap
//   conv_blur: all-ones kernel, SHIFT=4         -> floor(sum/16)
//
// Golden results are recomputed in the testbench from the frame with
// plain integer arithmetic.

`timescale 1ns/1ps

module tb_conv3x3;

    localparam WIDTH  = 8;
    localparam HEIGHT = 4;
    localparam NPIX   = WIDTH * HEIGHT;

    reg        clk = 1'b0;
    reg        rst_n = 1'b0;
    reg        pixel_valid = 1'b0;
    reg  [7:0] pixel_in = 8'd0;
    wire [7:0] p11, p12, p13, p21, p22, p23, p31, p32, p33;
    wire       window_valid;

    wire [7:0] id_out;
    wire       id_valid;
    wire [7:0] blur_out;
    wire       blur_valid;

    integer errors = 0;
    integer checks = 0;
    integer accepted = 0;
    integer k;
    integer k_win = -1;  // acceptance index of the window conv consumed
    integer sum;
    integer i;
    integer j;

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

    conv3x3 #(
        .K22 (1), .SHIFT (0)
    ) conv_id (
        .clk (clk), .in_valid (window_valid),
        .p11 (p11), .p12 (p12), .p13 (p13),
        .p21 (p21), .p22 (p22), .p23 (p23),
        .p31 (p31), .p32 (p32), .p33 (p33),
        .pixel_out (id_out), .out_valid (id_valid)
    );

    conv3x3 #(
        .K11 (1), .K12 (1), .K13 (1),
        .K21 (1), .K22 (1), .K23 (1),
        .K31 (1), .K32 (1), .K33 (1),
        .SHIFT (4)
    ) conv_blur (
        .clk (clk), .in_valid (window_valid),
        .p11 (p11), .p12 (p12), .p13 (p13),
        .p21 (p21), .p22 (p22), .p23 (p23),
        .p31 (p31), .p32 (p32), .p33 (p33),
        .pixel_out (blur_out), .out_valid (blur_valid)
    );

    always #5 clk = ~clk;

    // Track which window the conv stages consumed last cycle.
    always @(posedge clk) begin
        if (rst_n && window_valid)
            k_win <= accepted - 1;
    end

    always @(posedge clk) begin
        if (rst_n && pixel_valid)
            accepted <= accepted + 1;
    end

    // Check conv outputs one cycle after window_valid.
    always @(posedge clk) begin
        if (rst_n && id_valid) begin
            // Golden: identity returns the centre tap = frame[k-9].
            checks = checks + 1;
            if (id_out !== frame[k_win - WIDTH - 1]) begin
                errors = errors + 1;
                $display("FAIL id t=%0t got=%0d want=%0d",
                         $time, id_out, frame[k_win - WIDTH - 1]);
            end
            // Golden: blur returns floor(sum of the nine taps / 16).
            sum = 0;
            for (i = -1; i <= 1; i = i + 1)
                for (j = -1; j <= 1; j = j + 1)
                    sum = sum + frame[k_win - WIDTH - 1 + i*WIDTH + j];
            checks = checks + 1;
            if (blur_out !== (sum >> 4)) begin
                errors = errors + 1;
                $display("FAIL blur t=%0t got=%0d want=%0d",
                         $time, blur_out, sum >> 4);
            end
        end
    end

    initial begin
        for (k = 0; k < NPIX; k = k + 1)
            frame[k] = (k * 7 + 13) & 8'hff;   // non-trivial pattern

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

        if (checks != 12 * 2) begin
            errors = errors + 1;
            $display("FAIL: ran %0d conv checks, want %0d",
                     checks, 12 * 2);
        end
        if (errors == 0)
            $display("PASS tb_conv3x3: %0d checks", checks);
        else begin
            $display("FAIL tb_conv3x3: %0d errors", errors);
            $fatal(1);
        end
        $finish;
    end

endmodule
