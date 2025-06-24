interface read_if #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
) (
    input logic clk,
    input logic rst_n
);

    logic                  en;
    logic [DATA_WIDTH-1:0] data;
    logic                  empty;
    logic                  almost_empty;

    modport TB (
        input clk, rst_n, data, empty, almost_empty,
        output en
    );

    modport DUT (
        input clk, rst_n, en,
        output data, empty, almost_empty
    );

    // Internal signals for pointers
    logic [ADDR_WIDTH:0] addr, ptr, ptr_sync;

    // Assert that write pointer does not change when FIFO is full
    property no_read_when_empty;
        @(posedge clk) disable iff (!rst_n)
        empty |=> (ptr == $past(ptr));
    endproperty

    assert property (no_read_when_empty) else
        $error("[%0t] ERROR: read pointer changed while FIFO is empty", $time);

endinterface

interface write_if #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
) (
    input logic clk,
    input logic rst_n
);

    logic                  en;
    logic [DATA_WIDTH-1:0] data;
    logic                  full;
    logic                  almost_full;

    modport TB (
        input clk, rst_n, full, almost_full,
        output en, data
    );

    modport DUT (
        input clk, rst_n, en, data,
        output full, almost_full
    );

    // Internal signals for pointers
    logic [ADDR_WIDTH:0] addr, ptr, ptr_sync;

    // Assert that read pointer does not change when FIFO is empty
    property no_write_when_full;
        @(posedge clk) disable iff (!rst_n)
        full |=> (ptr == $past(ptr));
    endproperty

    assert property (no_write_when_full) else
        $error("[%0t] ERROR: write pointer changed while FIFO is full", $time);

endinterface
