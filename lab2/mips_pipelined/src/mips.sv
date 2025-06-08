module mips (
    input  logic        clk, reset,
    output logic [31:0] pc,
    input  logic [31:0] instr,
    output logic        memwrite,
    output logic [31:0] aluout, writedata,
    input  logic [31:0] readdata
);

    wire memtoreg, branch, alusrc, regdst, regwrite, jump, memwrite_ID;
    wire [2:0] alucontrol;

    controller c(
        .op(instr[31:26]),
        .funct(instr[5:0]),
        .branch,
        .memtoreg,
        .memwrite(memwrite_ID),
        .alusrc,
        .regdst,
        .regwrite,
        .jump,
        .alucontrol
    );

    datapath dp(
        .clk,
        .reset,
        .memtoreg_ID(memtoreg),
        .memwrite_ID(memwrite_ID),
        .alusrc_ID(alusrc),
        .regdst_ID(regdst), 
        .regwrite_ID(regwrite),
        .jump_ID(jump),
        .branch_ID(branch),
        .alucontrol_ID(alucontrol),
        .pc_IF(pc),
        .instr_IF(instr),
        .aluout_MEM(aluout),
        .writedata_MEM(writedata),
        .readdata_MEM(readdata),
        .memwrite_MEM(memwrite)
    );
endmodule
