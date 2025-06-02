module async_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 8
) (
    // Push interface
    input  logic                  wclk,
    input  logic                  wen,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic                  full,
    output logic                  almost_full,

    // Pop interface
    input  logic                  rclk,
    input  logic                  ren,
    output logic [DATA_WIDTH-1:0] rdata,
    output logic                  empty,
    output logic                  almost_empty,

    // Global reset
    input  logic                  rst_n
);

    // Internal signals for status flags
    logic next_full;
    logic next_empty;
    logic next_almost_full;
    logic next_almost_empty;

    // Internal signals for read/write pointers
    logic [ADDR_WIDTH:0] waddr;     // binary memory addresses
    logic [ADDR_WIDTH:0] raddr;
    logic [ADDR_WIDTH:0] next_wptr; // next gray pointers
    logic [ADDR_WIDTH:0] next_rptr; 
    logic [ADDR_WIDTH:0] wptr;      // gray pointers
    logic [ADDR_WIDTH:0] rptr;       
    logic [ADDR_WIDTH:0] wptr_sync; // synchronized gray pointers
    logic [ADDR_WIDTH:0] rptr_sync;

    // Use counters for the binary pointers
    gray_counter #(ADDR_WIDTH+1) wcount(
        .clk(wclk),
        .rst_n(rst_n),
        .incr(wen && !full),
        .count(waddr),
        .next_count_gray(next_wptr),
        .count_gray(wptr)
    );
    gray_counter #(ADDR_WIDTH+1) rcount(
        .clk(rclk),
        .rst_n(rst_n),
        .incr(ren && !empty),
        .count(raddr),
        .next_count_gray(next_rptr),
        .count_gray(rptr)
    );

    // Synchronize the pointers with clock domain crossing
    synchronizer #(ADDR_WIDTH+1) wsync(
        .clk(rclk),
        .rst_n(rst_n),
        .async_data(wptr),
        .sync_data(wptr_sync)
    );
    synchronizer #(ADDR_WIDTH+1) rsync(
        .clk(wclk),
        .rst_n(rst_n),
        .async_data(rptr),
        .sync_data(rptr_sync)
    );

    // Create memory block
    memory #(DATA_WIDTH, ADDR_WIDTH) mem1(
        .wclk(wclk),
        .wen(wen && !full),
        .waddr(waddr[ADDR_WIDTH-1:0]),
        .raddr(raddr[ADDR_WIDTH-1:0]),
        .wdata(wdata),
        .rdata(rdata)
    );

    // Compute empty
    assign next_empty = (next_rptr == wptr_sync);

    always_ff @(posedge rclk) begin
        if (!rst_n) empty <= 1'b1;
        else        empty <= next_empty;
    end

    // Compute full
    assign next_full = (
        next_wptr == {~rptr_sync[ADDR_WIDTH:ADDR_WIDTH-1], rptr_sync[ADDR_WIDTH-2:0]}
    );

    always_ff @(posedge rclk) begin
        if (!rst_n) full <= 1'b0;
        else        full <= next_full;
    end

    // Compute almost empty
    assign next_almost_empty = 1'b0;

    always_ff @(posedge rclk) begin
        if (!rst_n) almost_empty <= 1'b1;
        else        almost_empty <= next_almost_empty;
    end

    // Compute almost full
    assign next_almost_full = 1'b0;

    always_ff @(posedge rclk) begin
        if (!rst_n) almost_full <= 1'b0;
        else        almost_full <= next_almost_full;
    end

endmodule
