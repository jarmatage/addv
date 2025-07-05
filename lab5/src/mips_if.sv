interface imem_if (
    input logic clk,
    input logic reset
);

    logic [31:0] pc, instr;
    logic [31:0] dataadr, writedata;
    logic memwrite;

    modport TB (
        input clk, reset, pc, instr, dataadr, writedata, memwrite
    );

    modport DUT (
        input clk, reset,
        output pc, instr, dataadr, writedata, memwrite
    );

endinterface
