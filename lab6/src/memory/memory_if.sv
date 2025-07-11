interface memory_if (
    input logic clk,
    input logic resetn
    );

    logic [`AWIDTH-1:0]             addr;
    logic [`MASK_WIDTH*`DWIDTH-1:0] data;
    logic en;

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

    // Assertions
    property no_en_when_reset;
        @(posedge clk)
        !resetn |-> !en;
    endproperty

    assert property (no_en_when_reset) else
        $error("[%0t] ERROR: en is high while resetn is low", $time);

    property invalid_addr;
        @(posedge clk)
        (addr === 'x) || (addr < 3) || (addr == 10'h3FF);
    endproperty

    assert property (invalid_addr) else
        $error("[%0t] ERROR: addr is invalid (either unknown or less than 3)", $time);

endinterface
