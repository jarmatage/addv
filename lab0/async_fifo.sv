module async_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 8
) (
    // Push interface
    input  logic                  write_clk,
    input  logic                  write_en,
    input  logic [DATA_WIDTH-1:0] write_data,
    output logic                  full,
    output logic                  almost_full,

    // Pop interface
    input  logic                  read_clk,
    input  logic                  read_en,
    output logic [DATA_WIDTH-1:0] read_data,
    output logic                  empty,
    output logic                  almost_empty,

    // Global reset
    input  logic                  rst_n
);

    // Internal signals
    logic [ADDR_WIDTH:0] read_ptr;        // binary pointers
    logic [ADDR_WIDTH:0] write_ptr;
    logic [ADDR_WIDTH:0] read_ptr_gray;   // gray pointers
    logic [ADDR_WIDTH:0] write_ptr_gray;
    logic [ADDR_WIDTH:0] read_addr;       // synchronized gray pointers
    logic [ADDR_WIDTH:0] write_addr;

    // Use counters for the binary pointers
    counter #(ADDR_WIDTH+1) read_count(
        .clk(read_clk),
        .rst_n,
        .incr(read_en),
        .count(read_ptr)
    );
    counter #(ADDR_WIDTH+1) write_count(
        .clk(write_clk),
        .rst_n,
        .incr(write_en),
        .count(write_ptr)
    );

    // Convert the binary pointers into gray code
    assign read_ptr_gray  = read_ptr  ^ (read_ptr >> 1);
    assign write_ptr_gray = write_ptr ^ (write_ptr >> 1);

    // Synchronize the gray pointers with clock domain crossing
    synchronizer #(ADDR_WIDTH+1) read_sync(
        .clk(write_clk),
        .async_data(read_ptr_gray),
        .sync_data(read_addr)
    );
    synchronizer #(ADDR_WIDTH+1) write_sync(
        .clk(read_clk),
        .async_data(write_ptr_gray),
        .sync_data(write_addr)
    );

    // Create memory block
    memory #(DATA_WIDTH, ADDR_WIDTH) m1(
        .write_clk,
        .write_en,
        .write_addr(write_addr[ADDR_WIDTH-1:0]),
        .read_addr(read_addr[ADDR_WIDTH-1:0]),
        .write_data,
        .read_data
    );

    // Compute the empty/full status flags
    assign full = (write_ptr_gray[ADDR_WIDTH] != read_addr[ADDR_WIDTH]) && (write_ptr_gray[ADDR_WIDTH-1:0] == read_addr[ADDR_WIDTH-1:0]);
    assign empty = (read_ptr_gray == write_addr);
    
    // TODO: compute the almost empty/full status flags
    assign almost_full = 1'b0;
    assign almost_empty = 1'b0;

endmodule
