typedef struct packed {
    logic       sign;
    logic [2:0] exp;
    logic [3:0] mant;
} fp8_value;

module fp8_mult (
    input  fp8_value a, b,
    output fp8_value result,
    output logic [4:0] flags
);

    // Internal signals
    logic sign;
    logic a_nan, a_inf, a_zero;
    logic b_nan, b_inf, b_zero;
    logic [9:0] prod_mant;
    logic [8:0] norm_mant;
    logic guard, round_bit, sticky, round_up, inexact;
    logic [4:0] rounded_mant;
    logic signed [4:0] exp_sum, norm_exp;
    logic overflow, underflow;
    logic y_nan, y_inf, y_zero;

    // Matching signs results in a positive value
    assign sign = a.sign ^ b.sign;

    // Check for input special values
    assign a_nan = (&a.exp) && (|a.mant);
    assign b_nan = (&b.exp) && (|b.mant);
    assign a_inf = (&a.exp) && (~|a.mant);
    assign b_inf = (&b.exp) && (~|b.mant);
    assign a_zero = (~|a.exp) && (~|a.mant);
    assign b_zero = (~|b.exp) && (~|b.mant);

    // Multiply the mantissas and then normalize
    assign prod_mant = {6'd1, a.mant} * {6'd1, b.mant};
    assign norm_mant = prod_mant[9] ? prod_mant[8:0] : {1'b0, prod_mant[7:0]};

    // Round the mantissa (round to nearest, ties to even)
    assign guard = norm_mant[4];
    assign round_bit = norm_mant[3];
    assign sticky = |norm_mant[2:0];
    assign round_up = guard && (round_bit || sticky || norm_mant[5]);
    assign inexact = guard || round_bit || sticky;
    assign rounded_mant = {1'b0, norm_mant[8:5]} + round_up;

    // Add the exponents and increment due to normalization or rounding
    assign exp_sum = {2'd0, a.exp} + {2'd0, b.exp} - 5'd3;
    assign norm_exp = exp_sum + prod_mant[9] + rounded_mant[4];

    // Check for overflow and underflow
    assign overflow = norm_exp > 6;
    assign underflow = norm_exp < 1 && norm_exp != 0;

    // Compute if the result is a special value
    assign y_nan = a_nan || b_nan || (a_inf && b_zero ) || (b_inf && a_zero);
    assign y_inf = a_inf || b_inf || overflow;
    assign y_zero = a_zero || b_zero || underflow;

    // Compute the final result
    always_comb begin
        priority case (1'b1)
            y_nan:   result = {sign, 3'd7, 4'hF};
            y_inf:   result = {sign, 3'd7, 4'h0};
            y_zero:  result = {sign, 3'd0, 4'h0};
            default: result = {sign, norm_exp[2:0], norm_mant[3:0]};
        endcase
    end

    // Compute flags (invalid op, div by zero, overflow, underflow, inexact)
    assign flags = {y_nan, 1'b0, overflow, underflow, inexact};

endmodule
