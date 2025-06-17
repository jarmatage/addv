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

        operation = 1'b0;
        a = 8'b0_100_0100;
        b = 8'b0_100_0000;
        print_vals();

        operation = 1'b0;
        a = 8'b0_000_0001;
        b = 8'b0_101_0111;
        print_vals();

        operation = 1'b0;
        a = 8'b0_100_0100;
        b = 8'b0_101_0111;
        print_vals();

        operation = 1'b0;
        a = 8'b0_111_0100;
        b = 8'b0_001_1111;
        print_vals();

        operation = 1'b0;
        a = 8'b0_101_0110;
        b = 8'b1_111_1111;
        print_vals();

        operation = 1'b0;
        a = 8'b0_111_0000;
        b = 8'b1_111_0000;
        print_vals();

        operation = 1'b0;
        a = 8'b0_100_0100;
        b = 8'b1_111_0000;
        print_vals();

        operation = 1'b1;
        a = 8'b1_111_0000;
        b = 8'b1_111_0000;
        print_vals();

        operation = 1'b1;
        a = 8'b0_111_0000;
        b = 8'b0_111_0000;
        print_vals();

        operation = 1'b1;
        a = 8'b0_111_0000;
        b = 8'b1_111_0000;
        print_vals();

        operation = 1'b1;
        a = 8'b0_101_0000;
        b = 8'b0_011_0110;
        print_vals();

        operation = 1'b1;
        a = 8'b0_010_0001;
        b = 8'b0_010_0010;
        print_vals();      

        operation = 1'b1;
        a = 8'b0_010_0001;
        b = 8'b1_010_0110;
        print_vals();     

        reset_dut();
        $display("\nAll done!");
        $finish;
    end

    // Reset the DUT
    task automatic reset_dut();
        a = '0;
        b = '0;
        operation = 1'b0;
        #5;
    endtask

    // Print the current DUT values
    task automatic print_vals();
        #1;
        if (operation)
            $display("\nSubtraction:");
        else
            $display("\nAddition:");

        $write("a = %b = ", a);
        display_fp8(a);
        $write("\nb = %b = ", b);
        display_fp8(b);
        $write("\ny = %b = ", result);
        display_fp8(result);
        $display(" (flags = %b)", flags);
        #4;
    endtask
endmodule
