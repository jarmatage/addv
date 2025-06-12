module fp8 (
    input  logic clk, reset,
    input  logic [7:0] a, b,
    output logic [7:0] result,
    input  logic [1:0] op,
    output logic [4:0] flags
);

    assign result = '0;
    assign flags  = '0;

endmodule
