module gray_counter #(
    parameter int WIDTH = 8
) (
    input  logic             clk,
    input  logic             rst_n, // synchronous reset
    input  logic             incr,
    output logic [WIDTH-1:0] count,
    output logic [WIDTH-1:0] next_count_gray, // expose next gray count for status flags
    output logic [WIDTH-1:0] count_gray
);

    logic [WIDTH-1:0] next_count;

    // Add the increment (0 or 1) to the current count
    assign next_count = count + {(WIDTH-1)'(0), incr};

    // Convert the next count into gray code
    assign next_count_gray = next_count ^ (next_count >> 1);

    // Latch both the binary and gray counts
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            count <= WIDTH'(0);
            count_gray <= WIDTH'(0);
        end else begin
            count <= next_count;
            count_gray <= next_count_gray;
        end
    end

endmodule
