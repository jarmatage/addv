//////////////////////////////////////////////////////////////////////
// ===================================================================
// This file has the following module implementations:
// 1. controller
// 2. maindec
// 3. aludec
// ===================================================================
//////////////////////////////////////////////////////////////////////
// Controller module
//////////////////////////////////////////////////////////////////////
module controller (
    input  logic [5:0] op, funct,
    input  logic       zero,
    output logic       memtoreg, memwrite,
    output logic       pcsrc, alusrc,
    output logic       regdst, regwrite,
    output logic       jump,
    output logic [2:0] alucontrol
);
    wire [1:0] aluop;
    wire branch;
    
    maindec md(
        .op,
        .memtoreg,
        .memwrite,
        .branch,
        .alusrc,
        .regdst,
        .regwrite,
        .jump,
        .aluop
    );
    aludec ad(
        .funct,
        .aluop,
        .alucontrol
    );
    
    assign pcsrc = branch & zero;
endmodule


//////////////////////////////////////////////////////////////////////
// Main Decoder module
//////////////////////////////////////////////////////////////////////
module maindec(
    input  logic [5:0] op,
    output logic       memtoreg, memwrite,
    output logic       branch, alusrc,
    output logic       regdst, regwrite,
    output logic       jump,
    output logic [1:0] aluop
);

    logic [8:0] controls;
    
    assign {regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump, aluop} = controls;

    always_comb begin
        case(op)
            6'b000000: controls = 9'b110000010; //Rtyp
            6'b100011: controls = 9'b101001000; //LW
            6'b101011: controls = 9'b001010000; //SW
            6'b000100: controls = 9'b000100001; //BEQ
            6'b001000: controls = 9'b101000000; //ADDI
            6'b000010: controls = 9'b000000100; //J
            default:   controls = 9'bxxxxxxxxx; //???
        endcase
    end
endmodule


//////////////////////////////////////////////////////////////////////
// ALU Decoder module
//////////////////////////////////////////////////////////////////////
module aludec (
    input  logic [5:0] funct,
    input  logic [1:0] aluop,
    output logic [2:0] alucontrol
);

    logic [2:0] rtype;

    always_comb begin
        case(funct) 
            6'b100000: rtype = 3'b010; // ADD
            6'b011001: rtype = 3'b101; // MULADD
            6'b100010: rtype = 3'b110; // SUB
            6'b100100: rtype = 3'b000; // AND
            6'b100101: rtype = 3'b001; // OR
            6'b101010: rtype = 3'b111; // SLT
            default:   rtype = 3'bxxx; // ???
        endcase
    end

    always_comb begin
        case (aluop)
            2'b00:   alucontrol = 3'b010; // add
            2'b01:   alucontrol = 3'b110; // sub
            default: alucontrol = rtype;  // RTYPE
        endcase
    end
endmodule
