//////////////////////////////////////////////////////////////////////
// SystemVerilog conversion of datapath.v and submodules
//////////////////////////////////////////////////////////////////////

module datapath (
    input  logic        clk,
    input  logic        reset,
    input  logic        memtoreg,
    input  logic        pcsrc,
    input  logic        alusrc,
    input  logic        regdst,
    input  logic        regwrite,
    input  logic        jump,
    input  logic [2:0]  alucontrol,
    output logic        zero,
    output logic [31:0] pc,
    input  logic [31:0] instr,
    output logic [31:0] aluout,
    output logic [31:0] writedata,
    input  logic [31:0] readdata
);

    // Internal signals
    logic [4:0]  writereg;
    logic [31:0] pcnext, pcnextbr, pcplus4, pcbranch;
    logic [31:0] signimm, signimmsh;
    logic [31:0] srca, srcb;
    logic [31:0] result;

    // Next PC logic
    flopr #(.WIDTH(32)) pcreg (
        .clk   (clk),
        .reset (reset),
        .d     (pcnext),
        .q     (pc)
    );

    adder pcadd1 (
        .a (pc),
        .b (32'd4),
        .y (pcplus4)
    );

    sl2 immsh (
        .a (signimm),
        .y (signimmsh)
    );

    adder pcadd2 (
        .a (pcplus4),
        .b (signimmsh),
        .y (pcbranch)
    );

    mux2 #(.WIDTH(32)) pcbrmux (
        .d0 (pcplus4),
        .d1 (pcbranch),
        .s  (pcsrc),
        .y  (pcnextbr)
    );

    mux2 #(.WIDTH(32)) pcmux (
        .d0 (pcnextbr),
        .d1 ({pcplus4[31:28], instr[25:0], 2'b00}),
        .s  (jump),
        .y  (pcnext)
    );

    // Register file logic
    regfile rf (
        .clk  (clk),
        .we3  (regwrite),
        .ra1  (instr[25:21]),
        .ra2  (instr[20:16]),
        .wa3  (writereg),
        .wd3  (result),
        .rd1  (srca),
        .rd2  (writedata)
    );

    mux2 #(.WIDTH(5)) wrmux (
        .d0 (instr[20:16]),
        .d1 (instr[15:11]),
        .s  (regdst),
        .y  (writereg)
    );

    mux2 #(.WIDTH(32)) resmux (
        .d0 (aluout),
        .d1 (readdata),
        .s  (memtoreg),
        .y  (result)
    );

    signext se (
        .a (instr[15:0]),
        .y (signimm)
    );

    // ALU logic
    mux2 #(.WIDTH(32)) srcbmux (
        .d0 (writedata),
        .d1 (signimm),
        .s  (alusrc),
        .y  (srcb)
    );

    alu myalu (
        .a         (srca),
        .b         (srcb),
        .control   (alucontrol),
        .result    (aluout),
        .zero      (zero)
    );

endmodule

//////////////////////////////////////////////////////////////////////
// Register File Module
//////////////////////////////////////////////////////////////////////
module regfile (
    input  logic        clk,
    input  logic        we3,
    input  logic [4:0]  ra1,
    input  logic [4:0]  ra2,
    input  logic [4:0]  wa3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1,
    output logic [31:0] rd2
);
    logic [31:0] rf_mem [31:0];

    always_ff @(posedge clk) begin
        if (we3) rf_mem[wa3] <= wd3;
    end

    assign rd1 = (ra1 != 0) ? rf_mem[ra1] : 0;
    assign rd2 = (ra2 != 0) ? rf_mem[ra2] : 0;
endmodule

//////////////////////////////////////////////////////////////////////
// ALU Module
//////////////////////////////////////////////////////////////////////
module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  control,
    output logic [31:0] result,
    output logic        zero
);
    localparam logic [2:0] ALU_AND = 3'b000,
                          ALU_OR  = 3'b001,
                          ALU_ADD = 3'b010,
                          ALU_SUB = 3'b110,
                          ALU_SLT = 3'b111;

    always_comb begin
        unique case (control)
            ALU_AND: result = a & b;
            ALU_OR:  result = a | b;
            ALU_ADD: result = a + b;
            ALU_SUB: result = a - b;
            ALU_SLT: result = ($signed(a) < $signed(b));
            default: result = 'x;
        endcase
    end

    assign zero = (result == 0);
endmodule

//////////////////////////////////////////////////////////////////////
// Adder Module
//////////////////////////////////////////////////////////////////////
module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule

//////////////////////////////////////////////////////////////////////
// 2-to-1 Multiplexer Module
//////////////////////////////////////////////////////////////////////
module mux2 #(parameter int WIDTH = 8) (
    input  logic [WIDTH-1:0] d0,
    input  logic [WIDTH-1:0] d1,
    input  logic             s,
    output logic [WIDTH-1:0] y
);
    assign y = s ? d1 : d0;
endmodule

//////////////////////////////////////////////////////////////////////
// Shift Left by 2 Module
//////////////////////////////////////////////////////////////////////
module sl2 (
    input  logic [31:0] a,
    output logic [31:0] y
);
    assign y = {a[29:0], 2'b00};
endmodule

//////////////////////////////////////////////////////////////////////
// Sign Extension Module
//////////////////////////////////////////////////////////////////////
module signext (
    input  logic [15:0] a,
    output logic [31:0] y
);
    assign y = {{16{a[15]}}, a};
endmodule

//////////////////////////////////////////////////////////////////////
// Flop Register Module
//////////////////////////////////////////////////////////////////////
module flopr #(parameter int WIDTH = 8)(
    input  logic             clk,
    input  logic             reset,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) q <= '0;
        else       q <= d;
    end
endmodule
