`timescale 1ns/1ps

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

    // Almost empty threshold (-1 to get address size, -2 to divide by 4)
    localparam [WIDTH-1:0] THRESHOLD = WIDTH'(1 << (WIDTH - 3));

    // Internal signals
    logic [WIDTH-1:0] next_raddr;
    logic [WIDTH-1:0] next_rptr;
    logic             next_empty;
    logic             next_almost_empty;
    logic [WIDTH-1:0] waddr_sync;
    logic [WIDTH-1:0] diff;

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

    // Gray to binary
    function automatic logic [WIDTH-1:0] gray2bin(input logic [WIDTH-1:0] gray);
        logic [WIDTH-1:0] bin;
        bin[WIDTH-1] = gray[WIDTH-1];
        for (int i = WIDTH-2; i >= 0; i--)
            bin[i] = bin[i+1] ^ gray[i];
        return bin;
    endfunction

    // Compute the next almost_empty flag
    assign waddr_sync = gray2bin(wptr_sync);
    assign diff = waddr_sync - next_raddr;
    assign next_almost_empty = diff <= THRESHOLD;

    // Latch the empty and almost_empty flags
    always_ff @(posedge rclk or negedge rst_n) begin
        if (!rst_n) {empty, almost_empty} <= 2'b11;
        else        {empty, almost_empty} <= {next_empty, next_almost_empty};
    end

endmodule
