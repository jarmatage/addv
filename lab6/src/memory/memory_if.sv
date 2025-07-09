interface memory_if (
    input logic clk,
    input logic resetn
    );

    logic [`AWIDTH-1:0]             addr;
    logic [`MASK_WIDTH*`DWIDTH-1:0] data;
    logic [`MASK_WIDTH-1:0]         en;

    modport TB_READ(
        input clk, resetn,
        output addr, en,
        input data
    );

    modport DUT_READ(
        input clk, resetn,
        input addr, en,
        output data
    );

    modport TB_WRITE(
        input clk, resetn,
        output addr, en, data
    );

    modport DUT_WRITE(
        input clk, resetn,
        input addr, en, data
    );
endinterface
