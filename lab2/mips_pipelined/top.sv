module top (
    input  logic        clk, reset,
    output logic [31:0] writedata,
    output logic [31:0] dataadr,
    output logic        memwrite
);
    wire [31:0] pc, instr, readdata;

    // instantiate processor and memories
    mips mips (
        .clk,
        .reset,
        .pc,
        .instr,
        .memwrite,
        .aluout(dataadr),
        .writedata,
        .readdata
    );
    imem imem (
        .a(pc[7:2]),
        .rd(instr)
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
    input  logic [5:0]  a,
    output logic [31:0] rd
);
    logic [31:0] RAM[63:0];
    initial $readmemh("../memfile.dat", RAM);
    assign rd = RAM[a];
endmodule
