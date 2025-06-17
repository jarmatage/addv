module fp8_mac (
    input  logic clk,
    input  logic reset,
    input  fp8_value a, b,
    output fp8_value out,
    output logic [4:0] flags
);

    logic [7:0] a_flop, b_flop, mult, next_mult, next_out;
    logic [4:0] mul_flags, add_flags;

    // Instantiate the FP8 Multiplier
    fp8_mult multiplier (
        .a(a_flop),
        .b(b_flop),
        .result(next_mult),
        .flags(mul_flags)
    );

    // Instantiate the FP8 Adder
    fp8_addsub adder (
        .a(mult),
        .b(out),
        .operation(1'b0), // Always addition
        .result(next_out),
        .flags(add_flags)
    );

    // Latch inputs and outputs
    always_ff @(posedge clk) begin
        if (reset) begin
            a_flop <= '0;
            b_flop <= '0;
            mult   <= '0;
            out    <= '0;
        end else begin
            a_flop <= a;
            b_flop <= b;
            mult   <= next_mult; 
            out    <= next_out; 
        end
    end

    // Combine exception flags from both units
    assign flags = mul_flags | add_flags;

endmodule
