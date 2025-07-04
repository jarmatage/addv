module top (
    imem_if my_imem_if,
    input  logic        clk, reset,
    output logic [31:0] writedata,
    output logic [31:0] dataadr,
    output logic        memwrite
);
    wire [31:0] readdata;

    // instantiate processor and memories
    mips mips (
        .clk,
        .reset,
        .pc(my_imem_if.pc),
        .instr(my_imem_if.instr),
        .memwrite,
        .aluout(dataadr),
        .writedata,
        .readdata
    );
    imem imem (
        .a(my_imem_if.pc[9:2]),
        .rd(my_imem_if.instr)
    );
    dmem dmem (
        .clk, 
        .we(memwrite),
        .a(dataadr),
        .wd(writedata),
        .rd(readdata)
    );
endmodule


module dmem(
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] a,
    input  logic [31:0] wd,
    output logic [31:0] rd
);
    logic [31:0] RAM[63:0];
    assign rd = RAM[a[31:2]];
    always_ff @(posedge clk)
        if (we) RAM[a[31:2]] <= wd;
endmodule


module imem(
    input  logic [7:0]  a,
    output logic [31:0] rd
);
    logic [31:0] RAM[255:0];
    assign rd = RAM[a];
endmodule
