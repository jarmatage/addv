////////////////////////////////////////////////////////////////////////////
// ========================================================================
// This file has the following module implementations:
// 1. top
// 2. mips
// 3. dmem
// 4. imem
// =========================================================================
////////////////////////////////////////////////////////////////////////////
// Top Module 
//  - This module connects the MIPS processor to instruction and data memory
////////////////////////////////////////////////////////////////////////////
module top (
    input clk, reset,
    output [31:0] writedata, dataadr,
    output memwrite
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


//////////////////////////////////////////////////////////////////////
// Single-cycle MIPS Processor Module
//////////////////////////////////////////////////////////////////////
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


//////////////////////////////////////////////////////////////////////
// Data Memory Module
//////////////////////////////////////////////////////////////////////
module dmem (
    input  logic        clk, we,
    input  logic [31:0] a, wd,
    output logic [31:0] rd
);
    logic [31:0] RAM[63:0];

    assign rd = RAM[a[31:2]]; // word aligned
    
    always_ff @ (posedge clk)
        if (we)
            RAM[a[31:2]] <= wd;
endmodule


//////////////////////////////////////////////////////////////////////
// Instruction Memory Module
// - Note that it uses $readmemh to load imem from memfile.dat
// - This has a capacity of 64 words, If the memfile.dat has fewer than 64 words,
//   you will get a warning that some addresses are not initialized or the file has not enough words
//   you can ignre this warning
//////////////////////////////////////////////////////////////////////
module imem (
    input  logic [5:0] a,
    output logic [31:0] rd
);
    logic [31:0] RAM[63:0];
    
    initial $readmemh("../memfile.dat",RAM);
    assign rd = RAM[a]; // word aligned
endmodule
