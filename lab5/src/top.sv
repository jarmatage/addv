module top (
    mips_if my_mips_if
);
    wire [31:0] readdata;

    // instantiate processor and memories
    mips mips (
        .clk(my_mips_if.clk),
        .reset(my_mips_if.reset),
        .pc(my_mips_if.pc),
        .instr(my_mips_if.instr),
        .memwrite(my_mips_if.memwrite),
        .aluout(my_mips_if.aluout),
        .writedata(my_mips_if.writedata),
        .readdata(readdata)
    );
    imem imem (
        .a(my_mips_if.pc[9:2]),
        .rd(my_mips_if.instr)
    );
    dmem dmem (
        .clk(my_mips_if.clk),
        .we(my_mips_if.memwrite),
        .a(my_mips_if.dataadr),
        .wd(my_mips_if.writedata),
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
