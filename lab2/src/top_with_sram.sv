////////////////////////////////////////////////////////////////////////////
// top_with_sram.sv - SystemVerilog conversion of top_with_sram.v
////////////////////////////////////////////////////////////////////////////

// Top Module connecting processor to SRAM-based memories
module top (
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] writedata,
    output logic [31:0] dataadr,
    output logic        memwrite
);
    // Internal signals
    logic [31:0] pc;
    logic [31:0] instr;
    logic [31:0] readdata;

    // Instantiate processor
    mips u_mips (
        .clk       (clk),
        .reset     (reset),
        .pc        (pc),
        .instr     (instr),
        .memwrite  (memwrite),
        .aluout    (dataadr),
        .writedata (writedata),
        .readdata  (readdata)
    );

    // Instruction memory (SRAM)
    imem u_imem (
        .a  (pc[7:2]),
        .rd (instr)
    );

    // Data memory (SRAM)
    dmem u_dmem (
        .clk   (clk),
        .we    (memwrite),
        .a     (dataadr),
        .wd    (writedata),
        .rd    (readdata)
    );
endmodule

////////////////////////////////////////////////////////////////////////////
// Single-cycle MIPS Processor Module
////////////////////////////////////////////////////////////////////////////
module mips (
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] pc,
    input  logic [31:0] instr,
    output logic        memwrite,
    output logic [31:0] aluout,
    output logic [31:0] writedata,
    input  logic [31:0] readdata
);
    // Control & datapath signals
    logic        memtoreg, branch, alusrc, regdst, regwrite, jump;
    logic [2:0]  alucontrol;
    logic        zero, pcsrc;

    controller u_ctrl (
        .op        (instr[31:26]),
        .funct     (instr[5:0]),
        .zero      (zero),
        .memtoreg  (memtoreg),
        .memwrite  (memwrite),
        .pcsrc     (pcsrc),
        .alusrc    (alusrc),
        .regdst    (regdst),
        .regwrite  (regwrite),
        .jump      (jump),
        .alucontrol(alucontrol)
    );

    datapath u_dp (
        .clk       (clk),
        .reset     (reset),
        .memtoreg  (memtoreg),
        .pcsrc     (pcsrc),
        .alusrc    (alusrc),
        .regdst    (regdst),
        .regwrite  (regwrite),
        .jump      (jump),
        .alucontrol(alucontrol),
        .zero      (zero),
        .pc        (pc),
        .instr     (instr),
        .aluout    (aluout),
        .writedata (writedata),
        .readdata  (readdata)
    );
endmodule

////////////////////////////////////////////////////////////////////////////
// Data Memory Module - uses OpenRAM SRAM_32x64_1rw
////////////////////////////////////////////////////////////////////////////
module dmem (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] a,
    input  logic [31:0] wd,
    output logic [31:0] rd
);
    // OpenRAM signals
    logic        csb0;
    logic        web0;
    logic [5:0]  addr0;
    logic [31:0] din0;
    logic [31:0] dout0;

    assign csb0  = 1'b0;
    assign web0  = ~we;
    assign addr0 = a[7:2];
    assign din0  = wd;
    assign rd    = dout0;

    SRAM_32x64_1rw u_sram (
        .clk0  (clk),
        .csb0  (csb0),
        .web0  (web0),
        .addr0 (addr0),
        .din0  (din0),
        .dout0 (dout0)
    );
endmodule

////////////////////////////////////////////////////////////////////////////
// Instruction Memory Module - uses OpenRAM SRAM_32x64_1rw
////////////////////////////////////////////////////////////////////////////
module imem (
    input  logic [5:0]  a,
    output logic [31:0] rd
);
    // OpenRAM signals
    logic        clk0;
    logic        csb0;
    logic        web0;
    logic [5:0]  addr0;
    logic [31:0] din0;
    logic [31:0] dout0;

    assign clk0  = 1'b0;
    assign csb0  = 1'b0;
    assign web0  = 1'b1;
    assign addr0 = a;
    assign din0  = 32'b0;
    assign rd    = dout0;

    SRAM_32x64_1rw u_sram (
        .clk0  (clk0),
        .csb0  (csb0),
        .web0  (web0),
        .addr0 (addr0),
        .din0  (din0),
        .dout0 (dout0)
    );
endmodule
