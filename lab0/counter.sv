module counter #(
    parameter int WIDTH = 8
) (
    input  logic             clk,
    input  logic             rst_n, // synchronous reset
    input  logic             incr,
    output logic [WIDTH-1:0] count
);

    always_ff @(posedge clk) begin
        if (!rst_n)
            count <= 0;
        else if (incr)
            count <= count + 1;
    end

endmodule
