module fp8_mac (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [7:0] c,
    output logic [7:0] result,
    output logic [4:0] flags
);

    // Internal wires for the datapath
    logic [7:0] mul_result;
    logic [4:0] mul_flags;
    logic [4:0] add_flags;

    // Instantiate the FP8 Multiplier
    fp8_mul multiplier (
        .a(a),
        .b(b),
        .result(mul_result),
        .flags(mul_flags)
    );

    // Instantiate the FP8 Adder
    fp8_add adder (
        .a(mul_result),
        .b(c),
        .operation(1'b0), // Always addition
        .result(result),
        .flags(add_flags)
    );

    // Combine exception flags from both units
    assign flags = mul_flags | add_flags;

endmodule
