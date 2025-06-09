module datapath(
    input logic clk, reset,

    // Control signals
    output logic [31:0] instr_ID,
    input  logic        memtoreg_ID,
    input  logic        memwrite_ID,
    input  logic        alusrc_ID,
    input  logic        regdst_ID,
    input  logic        regwrite_ID,
    input  logic        jump_ID,
    input  logic        branch_ID,
    input  logic [2:0]  alucontrol_ID,

    // Instruction memory interface
    output logic [31:0] pc_IF,
    input  logic [31:0] instr_IF,

    // Data memory interface
    output logic [31:0] aluout_MEM, writedata_MEM,
    input  logic [31:0] readdata_MEM,
    output logic        memwrite_MEM
);

    // Internal signals
    logic [31:0] pcnext_IF;
    wire [31:0] pcplus4_IF;
    wire [31:0] pcplus4_ID, signimm_ID, srca_ID, writedata_ID;
    wire memtoreg_EX, memwrite_EX, alusrc_EX, regdst_EX, regwrite_EX, branch_EX;
    wire [2:0] alucontrol_EX;
    wire [31:0] pcplus4_EX, srca_EX, writedata_EX, signimm_EX, instr_EX;
    wire [31:0] srcb_EX, aluout_EX, signimmsh_EX, pcbranch_EX;
    wire [4:0] writereg_EX;
    wire zero_EX;
    wire memtoreg_MEM, regwrite_MEM, branch_MEM, zero_MEM, pcsrc_MEM;
    wire [31:0] pcbranch_MEM;
    wire [4:0] writereg_MEM;
    wire branch_WB, memtoreg_WB, regwrite_WB;
    wire [31:0] aluout_WB, readdata_WB;
    wire [4:0] writereg_WB;
    wire [31:0] result_WB;
    wire stall_IF, stall_ID, stall_EX;
    logic [31:0] pcnextbr, pcjump;

    // IF
    mux2 #(32) pcbrmux(
        .d0(pcplus4_IF),
        .d1(pcbranch_MEM),
        .s(pcsrc_MEM),
        .y(pcnextbr)
    );
    assign pcjump = {pcplus4_IF[31:28], instr_ID[25:0], 2'b00};
    mux2 #(32) pcmux(
        .d0(pcnextbr),
        .d1(pcjump),
        .s(jump_ID),
        .y(pcnext_IF)
    );
    flopr #(32) pcreg(
        .clk(clk),
        .reset(reset),
        .en(!stall_IF),
        .d(pcnext_IF),
        .q(pc_IF)
    );
    adder pcadd1(.a(pc_IF), .b(32'd4), .y(pcplus4_IF));

    // IF/ID
    if_id if_id(
        .clk,
        .reset,
        .stall(stall_ID),
        .pcplus4_IF,
        .instr_IF,
        .pcplus4_ID,
        .instr_ID
    );

    // ID
    regfile rf(
        .clk(clk),
        .we3(regwrite_WB),
        .ra1(instr_ID[25:21]),
        .ra2(instr_ID[20:16]),
        .wa3(writereg_WB),
        .wd3(result_WB),
        .rd1(srca_ID),
        .rd2(writedata_ID)
    );
    signext se(.a(instr_ID[15:0]), .y(signimm_ID));

    // ID/EX
    id_ex id_ex(
        .clk,
        .reset,
        .stall(stall_EX),
        .memtoreg_ID,
        .memwrite_ID,
        .alusrc_ID,
        .regdst_ID,
        .regwrite_ID,
        .branch_ID,
        .alucontrol_ID,
        .pcplus4_ID,
        .srca_ID,
        .writedata_ID,
        .signimm_ID,
        .instr_ID,
        .memtoreg_EX,
        .memwrite_EX,
        .alusrc_EX,
        .regdst_EX,
        .regwrite_EX,
        .branch_EX,
        .alucontrol_EX,
        .pcplus4_EX,
        .srca_EX,
        .writedata_EX,
        .signimm_EX,
        .instr_EX
    );

    // EX
    mux2 #(32) srcbmux(
        .d0(writedata_EX),
        .d1(signimm_EX),
        .s(alusrc_EX),
        .y(srcb_EX)
    );
    alu alu(
        .a(srca_EX),
        .b(srcb_EX),
        .control(alucontrol_EX),
        .result(aluout_EX),
        .zero(zero_EX)
    );
    mux2 #(5) wrmux(
        .d0(instr_EX[20:16]),
        .d1(instr_EX[15:11]),
        .s(regdst_EX),
        .y(writereg_EX)
    );
    sl2 immsh(.a(signimm_EX), .y(signimmsh_EX));
    adder pcadd2(.a(pcplus4_EX), .b(signimmsh_EX), .y(pcbranch_EX));
    
    // EX/MEM
    ex_mem ex_mem(
        .clk,
        .reset,
        .memtoreg_EX,
        .memwrite_EX,
        .regwrite_EX,
        .branch_EX,
        .zero_EX,
        .aluout_EX,
        .writedata_EX,
        .pcbranch_EX,
        .writereg_EX,
        .memtoreg_MEM,
        .memwrite_MEM,
        .regwrite_MEM,
        .branch_MEM,
        .zero_MEM,
        .aluout_MEM,
        .writedata_MEM,
        .pcbranch_MEM,
        .writereg_MEM
    );

    // MEM
    assign pcsrc_MEM = branch_MEM && zero_MEM;

    // MEM/WB
    mem_wb mem_wb(
        .clk,
        .reset,
        .branch_MEM,
        .memtoreg_MEM,
        .regwrite_MEM,
        .aluout_MEM,
        .readdata_MEM,
        .writereg_MEM,
        .branch_WB,
        .memtoreg_WB,
        .regwrite_WB,
        .aluout_WB,
        .readdata_WB,
        .writereg_WB
    );

    // WB
    mux2 #(32) resmux(
        .d0(aluout_WB),
        .d1(readdata_WB),
        .s(memtoreg_WB),
        .y(result_WB)
    );

    // Hazard detection
    hazard_unit hazard_unit(
        .stall_IF,
        .stall_ID,
        .stall_EX,
        .jump_ID,
        .branch_ID,
        .rs_ID(instr_ID[25:21]),
        .rt_ID(instr_ID[20:16]),
        .branch_EX,
        .memtoreg_EX, 
        .regwrite_EX,
        .writereg_EX,
        .branch_MEM,
        .memtoreg_MEM,
        .regwrite_MEM,
        .writereg_MEM,
        .branch_WB,
        .memtoreg_WB,
        .regwrite_WB,
        .writereg_WB
    );
endmodule
