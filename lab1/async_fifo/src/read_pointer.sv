module read_pointer #(
    parameter int WIDTH = 8
) (
    input  logic             rclk,
    input  logic             rst_n,
    input  logic             ren,
    input  logic [WIDTH-1:0] wptr_sync,
    output logic [WIDTH-1:0] raddr,
    output logic [WIDTH-1:0] rptr,
    output logic             empty,
    output logic             almost_empty
);

    // Internal signals
    logic [WIDTH-1:0] next_raddr;
    logic [WIDTH-1:0] next_rptr;
    logic             next_empty;
    logic             next_almost_empty;

    // Add the increment (0 or 1) to the current count
    assign next_raddr = raddr + {(WIDTH)'(0), (ren && !empty)};

    // Convert the next count into gray code
    assign next_rptr = next_raddr ^ (next_raddr >> 1);

    // Latch both the binary and gray counts
    always_ff @(posedge rclk or negedge rst_n) begin
        if (!rst_n) {raddr, rptr} <= 0;
        else        {raddr, rptr} <= {next_raddr, next_rptr};
    end

    // Compute the next empty flag
    assign next_empty = (next_rptr == wptr_sync);

    // Compute the next almost_empty flag
    assign next_almost_empty = 1'b0;

    // Latch the empty and almost_empty flags
    always_ff @(posedge rclk or negedge rst_n) begin
        if (!rst_n) {empty, almost_empty} <= 2'b11;
        else        {empty, almost_empty} <= {next_empty, next_almost_empty};
    end

endmodule
