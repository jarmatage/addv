interface imem_if (
    input logic clk,
    input logic reset
);

    logic [31:0] pc, instr;

    modport TB (
        input clk, reset, pc, instr
    );

    modport DUT (
        input clk, reset,
        output pc, instr
    );

endinterface
