//////////////////////////////////////////////////////////////////////
// ===================================================================
// This file has the following module implementations:
// 1. datapath
// 2. regfile
// 3. alu
// 4. adder
// 5. mux2
// 6. sl2
// 7. signext
// 8. flopr
// ===================================================================
//////////////////////////////////////////////////////////////////////
// Datapath module
//////////////////////////////////////////////////////////////////////
module datapath (
    input  logic        clk, reset,
    input  logic        memtoreg, pcsrc,
    input  logic        alusrc, regdst,
    input  logic        regwrite, jump,
    input  logic [2:0]  alucontrol,
    output logic        zero,
    output logic [31:0] pc,
    input  logic [31:0] instr,
    output logic [31:0] aluout, writedata,
    input  logic [31:0] readdata
);

    wire [4:0]  writereg;
    wire [31:0] pcnext, pcnextbr, pcplus4, pcbranch, pcjump;
    wire [31:0] signimm, signimmsh;
    wire [31:0] srca, srcb;
    wire [31:0] result;
    
    // next PC logic
    flopr #(32) pcreg(.clk(clk), .reset(reset), .d(pcnext), .q(pc));
    adder pcadd1 (.a(pc), .b(32'd4), .y(pcplus4));
    sl2 immsh(.a(signimm), .y(signimmsh));
    adder pcadd2(.a(pcplus4), .b(signimmsh), .y(pcbranch));
    mux2 #(32) pcbrmux(.d0(pcplus4), .d1(pcbranch), .s(pcsrc), .y(pcnextbr));
    assign pcjump = {pcplus4[31:28], instr[25:0], 2'b00};
    mux2 #(32) pcmux(.d0(pcnextbr), .d1(pcjump), .s(jump), .y(pcnext));

    // register file logic
    regfile rf(
        .clk(clk),
        .we3(regwrite),
        .ra1(instr[25:21]),
        .ra2(instr[20:16]),
        .wa3(writereg),
        .wd3(result),
        .rd1(srca),
        .rd2(writedata)
    );
    mux2 #(5) wrmux(.d0(instr[20:16]), .d1(instr[15:11]), .s(regdst), .y(writereg));
    mux2 #(32) resmux(.d0(aluout), .d1(readdata), .s(memtoreg), .y(result));
    signext se(.a(instr[15:0]), .y(signimm));
    
    // ALU logic
    mux2 #(32) srcbmux(.d0(writedata), .d1(signimm), .s(alusrc), .y(srcb));
    alu alu(.a(srca), .b(srcb), .control(alucontrol), .result(aluout), .zero(zero));
endmodule


//////////////////////////////////////////////////////////////////////
// Register File Module
//////////////////////////////////////////////////////////////////////
module regfile (
    input  logic clk,
    input  logic we3,
    input  logic [4:0] ra1, ra2, wa3,
    input  logic [31:0] wd3,
    output logic [31:0] rd1, rd2
);
    
    logic [31:0] rf[31:0];
    // three ported register file
    // read two ports combinationally
    // write third port on rising edge of clock
    // register 0 hardwired to 0
    always @ (posedge clk)
        if (we3) rf[wa3] <= wd3;

    assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
    assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
endmodule

//////////////////////////////////////////////////////////////////////
// ALU Module
////////////////////////////////////////////////////////////////////// 
module alu(
    input  logic [31:0] a,      // First operand
    input  logic [31:0] b,      // Second operand
    input  logic [2:0] control, // ALU control signal
    output logic [31:0] result, // ALU result
    output logic zero           // Zero flag
);

    // Define ALU operations based on control signal
    localparam [2:0] ALU_AND = 3'b000;
    localparam [2:0] ALU_OR  = 3'b001;
    localparam [2:0] ALU_ADD = 3'b010;
    localparam [2:0] ALU_SUB = 3'b110;
    localparam [2:0] ALU_SLT = 3'b111;
    
    // Calculate result based on control input
    always_comb begin
        case(control)
            ALU_AND: result = a & b;                     // AND
            ALU_OR:  result = a | b;                     // OR
            ALU_ADD: result = a + b;                     // ADD
            ALU_SUB: result = a - b;                     // SUB
            ALU_SLT: result = ($signed(a) < $signed(b)); // Set Less Than (signed)
            default: result = 32'bx;                     // Undefined operation
        endcase
    end
    
    // Set zero flag when result is 0
    assign zero = (result == 32'b0);
endmodule


//////////////////////////////////////////////////////////////////////
// Adder Module
//////////////////////////////////////////////////////////////////////
module adder (
    input  logic [31:0] a, b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule


//////////////////////////////////////////////////////////////////////
// 2-to-1 Multiplexer Module
//////////////////////////////////////////////////////////////////////
module mux2 #(parameter WIDTH = 8) (
    input  logic [WIDTH-1:0] d0, d1,
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
    // shift left by 2
    assign y = {a[29:0], 2'b00};
endmodule


//////////////////////////////////////////////////////////////////////
// Sign Extension Module
//////////////////////////////////////////////////////////////////////
module signext (
    input [15:0] a,
    output [31:0] y
);
    assign y = {{16{a[15]}}, a};
endmodule


//////////////////////////////////////////////////////////////////////
// Flop Register Module
//////////////////////////////////////////////////////////////////////
module flopr #(parameter WIDTH = 8) (
    input  logic             clk, reset,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
    always_ff @ (posedge clk, posedge reset) begin
        if (reset) q <= 0;
        else q <= d;
    end
endmodule
