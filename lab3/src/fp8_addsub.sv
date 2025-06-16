typedef struct packed {
    logic       sign;
    logic [2:0] exp;
    logic [3:0] mant;
} fp8_value;

module fp8_addsub (
    input  logic operation, // 1 = subtraction
    input  fp8_value a, b,
    output fp8_value result,
    output logic [4:0] flags
);

    // Internal signals
    logic eff_sign;
    logic a_nan, a_inf, a_zero;
    logic b_nan, b_inf, b_zero;
    logic y_nan, y_inf;
    logic [2:0] exp_diff;
    logic signed [3:0] norm_exp;
    logic [9:0] ma_aligned, mb_aligned;
    logic [10:0] sum_mant;
    logic sign;
    logic guard, round_bit, sticky, round_up, inexact;
    logic [4:0] rounded_mant;
    logic overflow, underflow;

    // Check for input special values
    assign a_nan = (&a.exp) && (|a.mant);
    assign b_nan = (&b.exp) && (|b.mant);
    assign a_inf = (&a.exp) && (~|a.mant);
    assign b_inf = (&b.exp) && (~|b.mant);
    assign a_zero = (~|a.exp) && (~|a.mant);
    assign b_zero = (~|b.exp) && (~|b.mant);

    // Compute the effective sign of b
    assign eff_sign = operation ^ b.sign;

    // Compute the rounding signals
    assign guard = sum_mant[4];
    assign round_bit = sum_mant[3];
    assign sticky = |sum_mant[2:0];
    assign round_up = guard && (round_bit || sticky || sum_mant[5]);
    assign inexact = guard || round_bit || sticky;
    assign rounded_mant = {1'b0, sum_mant[8:5]} + round_up;

    // Check for overflow and underflow
    assign overflow = norm_exp > 6;
    assign underflow = norm_exp < 0;

    // Compute if the result is a special value
    assign y_nan = a_nan || b_nan || (a_inf && b_inf && (a.sign ^ eff_sign));
    assign y_inf = a_inf || b_inf || overflow;
    assign y_zero = (sum_mant == '0) || underflow;

    // Main logic block
    always_comb begin
        // Align the mantissas
        if (a.exp > b.exp) begin
            exp_diff = a.exp - b.exp;
            norm_exp = {1'b0, a.exp};
            ma_aligned = {1'b1, a.mant, 5'b0};
            mb_aligned = {1'b1, b.mant, 5'b0} >> exp_diff;
        end else begin
            exp_diff = b.exp - a.exp;
            norm_exp = {1'b0, b.exp};
            mb_aligned = {{1'b1, b.mant}, 5'b0};
            ma_aligned = {{1'b1, a.mant}, 5'b0} >> exp_diff;
        end

        // Addition/Subtraction
        if (a.sign == eff_sign) begin
            sum_mant = ma_aligned + mb_aligned;
            sign = a.sign;
        end else if (ma_aligned >= mb_aligned) begin
            sum_mant = ma_aligned - mb_aligned;
            sign = a.sign;
        end else begin
            sum_mant = mb_aligned - ma_aligned;
            sign = eff_sign;
        end

        // Normalization
        if (sum_mant[10]) begin
            norm_exp = norm_exp + 1;
            sum_mant = sum_mant >> 1;
        end else begin
            while (sum_mant[9] == 0 && sum_mant != 0) begin
                sum_mant = sum_mant << 1;
                norm_exp = norm_exp - 1;
            end
        end

        // Rounding (round to nearest, ties to even)
        norm_exp = norm_exp + rounded_mant[4];
    end

    // Compute the final result
    always_comb begin
        priority case (1'b1)
            y_nan:   result = {1'b0, 3'd7, 4'hF};
            y_inf:   result = {a.sign, 3'd7, 4'h0};
            y_zero:  result = {sign, 3'd0, 4'h0};
            b_zero:  result = a;
            a_zero:  result = {eff_sign, b.exp, b.mant};
            default: result = {sign, norm_exp[2:0], rounded_mant[3:0]};
        endcase
    end

    // Compute flags (invalid op, div by zero, overflow, underflow, inexact)
    assign flags = {y_nan, 1'b0, overflow, underflow, inexact};

endmodule
