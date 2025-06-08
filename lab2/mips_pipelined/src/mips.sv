module mips (
    input  logic        clk, reset,
    output logic [31:0] pc,
    input  logic [31:0] instr,
    output logic        memwrite,
    output logic [31:0] aluout, writedata,
    input  logic [31:0] readdata
);

    wire memtoreg, branch, alusrc, regdst, regwrite, jump, pcsrc, zero;
    wire [2:0] alucontrol;

    controller c(
        .op(instr[31:26]),
        .funct(instr[5:0]),
        .zero,
        .memtoreg,
        .memwrite,
        .pcsrc,
        .alusrc,
        .regdst,
        .regwrite,
        .jump,
        .alucontrol
    );

    datapath dp(
        .clk,
        .reset,
        .memtoreg,
        .pcsrc,
        .alusrc,
        .regdst, 
        .regwrite,
        .jump,
        .alucontrol,
        .zero,
        .pc,
        .instr,
        .aluout,
        .writedata,
        .readdata
    );
endmodule
