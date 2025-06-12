module fp8_tb();
    // Set the timescale
    timeunit 1ns;
    timeprecision 100ps;

    // DUT signals
    logic clk, reset;
    logic [7:0] a, b, result;
    logic [1:0] op;
    logic [4:0] flags;

    // Instantiate the DUT
    fp8 dut(.*);

    // Clock generation
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Main test sequence
    initial begin
        `ifdef DUMP
            $display("Dumping to FSDB");
            $fsdbDumpvars();
        `endif
        reset_dut();
        reset_dut();
        $finish;
    end

    // Reset the DUT
    task automatic reset_dut();
        reset = 1'b1;
        a = '0;
        b = '0;
        op = '0;
        #10;
        reset = 1'b0;
        #10;
    endtask
endmodule
