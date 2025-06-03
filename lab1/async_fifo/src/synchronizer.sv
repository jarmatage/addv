`timescale 1ns/1ps

module synchronizer #(
    parameter int WIDTH = 8
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q2
);

    logic [WIDTH-1:0] q1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) {q2, q1} <= 0;
        else        {q2, q1} <= {q1, d};
    end

endmodule
