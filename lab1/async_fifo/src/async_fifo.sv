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

    // Internal signals for read/write pointers
    logic [ADDR_WIDTH:0] waddr;     // binary memory addresses
    logic [ADDR_WIDTH:0] raddr;
    logic [ADDR_WIDTH:0] wptr;      // gray pointers
    logic [ADDR_WIDTH:0] rptr;
    logic [ADDR_WIDTH:0] wptr_sync; // synchronized gray pointers
    logic [ADDR_WIDTH:0] rptr_sync;

    // Create memory block
    memory #(DATA_WIDTH, ADDR_WIDTH) mem1(
        .wclk(wclk),
        .wen(wen),
        .full(full),
        .waddr(waddr[ADDR_WIDTH-1:0]),
        .raddr(raddr[ADDR_WIDTH-1:0]),
        .wdata(wdata),
        .rdata(rdata)
    );

    // Compute the read pointer and empty status flags
    read_pointer #(ADDR_WIDTH+1) rptr_empty(
        .rclk(rclk),
        .rst_n(rst_n),
        .ren(ren),
        .wptr_sync(wptr_sync),
        .raddr(raddr),
        .rptr(rptr),
        .empty(empty),
        .almost_empty(almost_empty)
    );

    // Compute the write pointer and full status flags
    write_pointer #(ADDR_WIDTH+1) wptr_full(
        .wclk(wclk),
        .rst_n(rst_n),
        .wen(wen),
        .rptr_sync(rptr_sync),
        .waddr(waddr),
        .wptr(wptr),
        .full(full),
        .almost_full(almost_full)
    );

    // Synchronize the pointers with clock domain crossing
    synchronizer #(ADDR_WIDTH+1) rsync(
        .clk(wclk),
        .rst_n(rst_n),
        .d(rptr),
        .q2(rptr_sync)
    );
    synchronizer #(ADDR_WIDTH+1) wsync(
        .clk(rclk),
        .rst_n(rst_n),
        .d(wptr),
        .q2(wptr_sync)
    );

endmodule
