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
        $error("[%0t] ERROR: en '%b' is high while resetn is low", $time, en);

    property invalid_addr;
        @(posedge clk)
        en |-> (addr <= 3);
    endproperty

    assert property (invalid_addr) else
        $error("[%0t] ERROR: addr '%0h' is invalid", $time, addr);

endinterface
