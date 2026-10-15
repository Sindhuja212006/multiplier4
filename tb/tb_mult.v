`timescale 1ns/1ps
// Exhaustive self-checking testbench for mult_array
module tb_mult;
    reg        clk   = 1'b0;
    reg        rst_n = 1'b0;
    reg  [3:0] a     = 4'd0;
    reg  [3:0] b     = 4'd0;
    wire [7:0] p;

    integer i, j;
    integer errors = 0;
    integer count  = 0;
    reg [7:0] expected;

    mult_array dut (.clk(clk), .rst_n(rst_n), .a(a), .b(b), .p(p));

    // 10 ns clock period
    always #5 clk = ~clk;

    initial begin
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);

        // Hold reset low for the first 2 clock cycles
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        // Apply all 256 combinations
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                a = i;                    // applied on a falling edge
                b = j;
                expected = i * j;         // '*' allowed in the testbench only
                @(posedge clk);           // edge 1: a, b captured into input registers
                @(posedge clk);           // edge 2: product captured into p
                @(negedge clk);           // sample half a cycle later (safe for gate-level sim)
                count = count + 1;
                if (p !== expected) begin
                    errors = errors + 1;
                    $display("MISMATCH at %0t ns: a=%0d b=%0d p=%0d expected=%0d",
                             $time, a, b, p, expected);
                end
            end
        end

        if (errors == 0)
            $display("PASS: %0d vectors checked, 0 errors", count);
        else
            $display("FAIL: %0d vectors checked, %0d errors", count, errors);
        $finish;
    end
endmodule
