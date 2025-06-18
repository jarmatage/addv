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


task display_fp8(input logic [7:0] fp);
    real abs_fp;

    if (fp[7]) begin
        abs_fp = -fp8_to_real(fp);
        $write("-");
    end else begin
        abs_fp = fp8_to_real(fp);
        $write("+");
    end

    if (fp[6:0] == 7'b111_0000)
        $write("inf     ");
    else if (fp[6:4] == 3'b111)
        $write("nan     ");
    else if (fp[6:0] == 7'b000_0000)
        $write("0.000000");
    else
        $write("%f", abs_fp);
endtask
