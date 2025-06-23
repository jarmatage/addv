interface read_if #(
    parameter DATA_WIDTH = 8
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

endinterface

interface write_if #(
    parameter DATA_WIDTH = 8
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

endinterface
