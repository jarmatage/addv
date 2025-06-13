typedef struct packed {
    logic sign;
    logic [2:0] exp;
    logic [3:0] mant;
} fp8_value;

module fp8_adder (
    input  fp8_value a,
    input  fp8_value b,
    output fp8_value result
);

    // Internal signals
    logic [4:0] mant_a, mant_b;
    logic [4:0] aligned_a, aligned_b;
    logic [2:0] exp_diff, common_exp;
    logic [4:0] norm_mant;
    logic [5:0] mant_sum;
    logic [2:0] norm_shift;

    // Add implicit 1 to mantissa if exponent is non-zero
    assign mant_a = {(a.exp != '0), a.mant};
    assign mant_b = {(b.exp != '0), b.mant};

    always_comb begin
        // Align exponents
        if (a.exp > b.exp) begin
            exp_diff   = a.exp - b.exp;
            aligned_a  = mant_a;
            aligned_b  = mant_b >> exp_diff;
            common_exp = a.exp;
        end else begin
            exp_diff   = b.exp - a.exp;
            aligned_a  = mant_a >> exp_diff;
            aligned_b  = mant_b;
            common_exp = b.exp;
        end

        // Add or subtract mantissas
        if (a.sign == b.sign) begin
            mant_sum    = aligned_a + aligned_b;
            result.sign = a.sign;
        end else if (aligned_a >= aligned_b) begin
            mant_sum    = aligned_a - aligned_b;
            result.sign = a.sign;
        end else begin
            mant_sum    = aligned_b - aligned_a;
            result.sign = b.sign;
        end

        // Normalize
        if (mant_sum[5]) begin
            norm_mant = mant_sum[5:1];  // shift right 1
            result.exp  = common_exp + 1;
        end else begin
            // Find leading 1 to normalize left
            norm_shift = mant_sum[4] ? 0 :
                mant_sum[3] ? 1 :
                mant_sum[2] ? 2 :
                mant_sum[1] ? 3 : 4;

            norm_mant = mant_sum << norm_shift;
            result.exp = common_exp > norm_shift ? common_exp - norm_shift : '0;
        end
        result.mant = norm_mant[3:0];

        // Handle underflow/overflow
        if (result.exp == '0 || mant_sum == '0) begin
            result.sign = 1'b0;
            result.exp  = 3'd0;
            result.mant = 4'd0;
        end
    end

endmodule
