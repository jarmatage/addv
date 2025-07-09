interface ram_read_if (
    input logic clk,
    input logic resetn
    );

    logic [`AWIDTH-1:0]             addr;
    logic [`MASK_WIDTH*`DWIDTH-1:0] data;
    logic [`MASK_WIDTH-1:0]         en;

    modport TB(
        input clk, resetn,
        output addr, en,
        input data
    );

    modport DUT(
        input clk, resetn,
        input addr, en,
        output data
    );
endinterface


interface ram_write_if (
    input logic clk,
    input logic resetn
    );

    logic [`AWIDTH-1:0]             addr;
    logic [`MASK_WIDTH*`DWIDTH-1:0] data;
    logic [`MASK_WIDTH-1:0]         en;

    modport TB(
        input clk, resetn,
        output addr, en, data
    );

    modport DUT(
        input clk, resetn,
        input addr, en, data
    );
endinterface
