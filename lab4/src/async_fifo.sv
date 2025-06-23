module async_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
) (
    write_if.DUT write, // Push interface
    read_if.DUT  read,  // Pop interface
    input logic rst_n   // Global reset
);

    // Internal signals for read/write pointers
    logic [ADDR_WIDTH:0] waddr;     // binary memory addresses
    logic [ADDR_WIDTH:0] raddr;
    logic [ADDR_WIDTH:0] wptr;      // gray pointers
    logic [ADDR_WIDTH:0] rptr;
    logic [ADDR_WIDTH:0] wptr_sync; // synchronized gray pointers
    logic [ADDR_WIDTH:0] rptr_sync;

    // Create memory block
    memory #(DATA_WIDTH, ADDR_WIDTH) mem1(
        .wclk(write.clk),
        .wen(write.en),
        .full(write.full),
        .waddr(waddr[ADDR_WIDTH-1:0]),
        .raddr(raddr[ADDR_WIDTH-1:0]),
        .wdata(write.data),
        .rdata(read.data)
    );

    // Compute the read pointer and empty status flags
    read_pointer #(ADDR_WIDTH+1) rptr_empty(
        .rclk(read.clk),
        .rst_n(rst_n),
        .ren(read.en),
        .wptr_sync(wptr_sync),
        .raddr(raddr),
        .rptr(rptr),
        .empty(read.empty),
        .almost_empty(read.almost_empty)
    );

    // Compute the write pointer and full status flags
    write_pointer #(ADDR_WIDTH+1) wptr_full(
        .wclk(write.clk),
        .rst_n(rst_n),
        .wen(write.en),
        .rptr_sync(rptr_sync),
        .waddr(waddr),
        .wptr(wptr),
        .full(write.full),
        .almost_full(write.almost_full)
    );

    // Synchronize the pointers with clock domain crossing
    synchronizer #(ADDR_WIDTH+1) rsync(
        .clk(write.clk),
        .rst_n(rst_n),
        .d(rptr),
        .q2(rptr_sync)
    );
    synchronizer #(ADDR_WIDTH+1) wsync(
        .clk(read.clk),
        .rst_n(rst_n),
        .d(wptr),
        .q2(wptr_sync)
    );

endmodule
