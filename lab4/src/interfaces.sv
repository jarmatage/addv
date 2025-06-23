interface read_if #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
) (
    input logic clk
);

    logic                  en;
    logic [DATA_WIDTH-1:0] data;
    logic                  empty;
    logic                  almost_empty;

    modport TB (
        input clk, data, empty, almost_empty,
        output en
    );

    modport DUT (
        input clk, en,
        output data, empty, almost_empty
    );

    // Internal signals for pointers
    logic [ADDR_WIDTH:0] addr, ptr, ptr_sync;

endinterface

interface write_if #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
) (
    input logic clk
);

    logic                  en;
    logic [DATA_WIDTH-1:0] data;
    logic                  full;
    logic                  almost_full;

    modport TB (
        input clk, full, almost_full,
        output en, data
    );

    modport DUT (
        input clk, en, data,
        output full, almost_full
    );

    // Internal signals for pointers
    logic [ADDR_WIDTH:0] addr, ptr, ptr_sync;

endinterface
