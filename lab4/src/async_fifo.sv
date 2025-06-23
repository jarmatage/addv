module async_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
) (
    write_if write,     // Push interface
    read_if read,       // Pop interface
    input logic rst_n   // Global reset
);

    // Create memory block
    memory #(DATA_WIDTH, ADDR_WIDTH) mem1(
        .wclk(write.clk),
        .wen(write.en),
        .full(write.full),
        .waddr(write.addr[ADDR_WIDTH-1:0]),
        .raddr(read.addr[ADDR_WIDTH-1:0]),
        .wdata(write.data),
        .rdata(read.data)
    );

    // Compute the read pointer and empty status flags
    read_pointer #(ADDR_WIDTH+1) rptr_empty(
        .rclk(read.clk),
        .rst_n(rst_n),
        .ren(read.en),
        .wptr_sync(write.ptr_sync),
        .raddr(read.addr),
        .rptr(read.ptr),
        .empty(read.empty),
        .almost_empty(read.almost_empty)
    );

    // Compute the write pointer and full status flags
    write_pointer #(ADDR_WIDTH+1) wptr_full(
        .wclk(write.clk),
        .rst_n(rst_n),
        .wen(write.en),
        .rptr_sync(read.ptr_sync),
        .waddr(write.addr),
        .wptr(write.ptr),
        .full(write.full),
        .almost_full(write.almost_full)
    );

    // Synchronize the pointers with clock domain crossing
    synchronizer #(ADDR_WIDTH+1) rsync(
        .clk(write.clk),
        .rst_n(rst_n),
        .d(read.ptr),
        .q2(read.ptr_sync)
    );
    synchronizer #(ADDR_WIDTH+1) wsync(
        .clk(read.clk),
        .rst_n(rst_n),
        .d(write.ptr),
        .q2(write.ptr_sync)
    );

endmodule
