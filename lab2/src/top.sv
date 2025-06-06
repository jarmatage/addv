////////////////////////////////////////////////////////////////////////////
// SystemVerilog conversion of top.v and submodules
////////////////////////////////////////////////////////////////////////////

// Top Module: connects processor, instruction memory, and data memory
module top (
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] writedata,
    output logic [31:0] dataadr,
    output logic        memwrite
);
    // Internal wires
    logic [31:0] pc;
    logic [31:0] instr;
    logic [31:0] readdata;

    // Instantiate single-cycle MIPS processor
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

    // Instantiate instruction memory
    imem u_imem (
        .a  (pc[7:2]),
        .rd (instr)
    );

    // Instantiate data memory
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
    // Control signals
    logic        memtoreg, branch, alusrc, regdst, regwrite, jump;
    logic [2:0]  alucontrol;
    logic        zero;
    logic        pcsrc;

    // Instantiate controller and datapath
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
// Data Memory Module
////////////////////////////////////////////////////////////////////////////
module dmem (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] a,
    input  logic [31:0] wd,
    output logic [31:0] rd
);
    // 64-word memory
    logic [31:0] RAM [0:63];

    // Read combinationally
    assign rd = RAM[a[31:2]];

    // Write on clock edge
    always_ff @(posedge clk) begin
        if (we)
            RAM[a[31:2]] <= wd;
    end
endmodule

////////////////////////////////////////////////////////////////////////////
// Instruction Memory Module
////////////////////////////////////////////////////////////////////////////
module imem (
    input  logic [5:0]  a,
    output logic [31:0] rd
);
    // 64-word memory
    logic [31:0] RAM [0:63];

    // Initialize from hex file
    initial begin
        $readmemh("memfile.dat", RAM);
    end

    // Read combinationally
    assign rd = RAM[a];
endmodule
