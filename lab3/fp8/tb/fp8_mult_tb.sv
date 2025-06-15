function real fp8_to_real(input logic [7:0] fp);
    logic sign;
    logic [2:0] exp;
    logic [3:0] mant;
    int unbiased_exp;
    real r_mant;

    sign = fp[7];
    exp  = fp[6:4];
    mant = fp[3:0];

    if (exp == 0 && mant == 0) return 0.0;

    unbiased_exp = exp - 3;
    r_mant = 1.0 + mant / 16.0;
    return (sign ? -1.0 : 1.0) * r_mant * (2.0 ** unbiased_exp);
endfunction


module fp8_tb();
    // Set the timescale
    timeunit 1ns;
    timeprecision 100ps;

    // DUT signals
    logic [7:0] a, b, result;
    logic [4:0] flags;

    // Instantiate the DUT
    fp8_mult dut(.*);

    // Main test sequence
    initial begin
        `ifdef DUMP
            $display("Dumping to FSDB");
            $fsdbDumpvars();
        `endif
        reset_dut();
        a = 8'b0_100_0100;
        b = 8'b0_100_0000;
        print_vals();
        reset_dut();
        $finish;
    end

    // Reset the DUT
    task automatic reset_dut();
        a = '0;
        b = '0;
        #5;
    endtask

    // Print the current DUT signals 
    task automatic print_vals();
        $display("a = %b = %f", a, fp8_to_real(a));
        $display("b = %b = %f", b, fp8_to_real(b));
        $display("y = %b = %f", result, fp8_to_real(result));
        #5;
    endtask
endmodule
