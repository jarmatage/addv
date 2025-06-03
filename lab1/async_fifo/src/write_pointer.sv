`timescale 1ns/1ps

module write_pointer #(
    parameter int WIDTH = 8
) (
    input  logic             wclk,
    input  logic             rst_n,
    input  logic             wen,
    input  logic [WIDTH-1:0] rptr_sync,
    output logic [WIDTH-1:0] waddr,
    output logic [WIDTH-1:0] wptr,
    output logic             full,
    output logic             almost_full
);

    // Almost full threshold (-1 to get address size, -2 to divide by 4)
    localparam [WIDTH-1:0] THRESHOLD = WIDTH'(1 << (WIDTH - 3));

    // Internal signals
    logic [WIDTH-1:0] next_waddr;
    logic [WIDTH-1:0] next_wptr;
    logic             next_full;
    logic             next_almost_full;
    logic [WIDTH-1:0] raddr_sync;

    // Add the increment (0 or 1) to the current count
    assign next_waddr = waddr + {(WIDTH)'(0), (wen && !full)};

    // Convert the next count into gray code
    assign next_wptr = next_waddr ^ (next_waddr >> 1);

    // Latch both the binary and gray counts
    always_ff @(posedge wclk or negedge rst_n) begin
        if (!rst_n) {waddr, wptr} <= 0;
        else        {waddr, wptr} <= {next_waddr, next_wptr};
    end

    // Compute the next empty flag
    assign next_full = (next_wptr == {~rptr_sync[WIDTH-1:WIDTH-2], rptr_sync[WIDTH-3:0]});

    // Gray to binary
    function automatic logic [WIDTH-1:0] gray2bin(input logic [WIDTH-1:0] gray);
        logic [WIDTH-1:0] bin;
        bin[WIDTH-1] = gray[WIDTH-1];
        for (int i = WIDTH-2; i >= 0; i--)
            bin[i] = bin[i+1] ^ gray[i];
        return bin;
    endfunction

    // Compute the next almost_empty flag
    assign raddr_sync = gray2bin(rptr_sync);
    assign next_almost_full = (
        (next_waddr + THRESHOLD) >= raddr_sync &&
        next_waddr[WIDTH-1] != raddr_sync[WIDTH-1]
    );

    // Latch the empty and almost_empty flags
    always_ff @(posedge wclk or negedge rst_n) begin
        if (!rst_n) {full, almost_full} <= 2'b00;
        else        {full, almost_full} <= {next_full, next_almost_full};
    end

endmodule
