module fp8_tb();
    // Set the timescale
    timeunit 1ns;
    timeprecision 100ps;

    // DUT signals
    logic [7:0] a, b, result;
    logic operation;
    logic [4:0] flags;

    // Instantiate the DUT
    fp8_addsub dut(.*);

    // Main test sequence
    initial begin
        `ifdef DUMP
            $display("Dumping to FSDB");
            $fsdbDumpvars();
        `endif
        reset_dut();

        a = 8'b0_100_0100;
        b = 8'b0_100_0000;
        print_mac_vals();

        a = 8'b0_000_0001;
        b = 8'b0_101_0111;
        print_mac_vals();

        a = 8'b0_100_0100;
        b = 8'b0_101_0111;
        print_mac_vals();

        reset_dut();
        $finish;
    end

    // Reset the DUT
    task automatic reset_dut();
        a = '0;
        b = '0;
        operation = 1'b0;
        #5;
    endtask
endmodule
