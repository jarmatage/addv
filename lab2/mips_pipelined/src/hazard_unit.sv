module hazard_unit(
    output logic stall,

    // ID
    input logic jump_ID, branch_ID,
    input logic [4:0] rs_ID,
    input logic [4:0] rt_ID,

    // EX
    input logic branch_EX, memtoreg_EX, regwrite_EX,
    input logic [4:0] writereg_EX,

    // MEM
    input logic branch_MEM, memtoreg_MEM, regwrite_MEM,
    input logic [4:0] writereg_MEM,

    // WB
    input logic memtoreg_WB, regwrite_WB,
    input logic [4:0] writereg_WB
);

    logic match_EX, match_MEM, match_WB;
    assign match_EX  = (writereg_EX  != 5'd0) && (rs_ID == writereg_EX  || rt_ID == writereg_EX);
    assign match_MEM = (writereg_MEM != 5'd0) && (rs_ID == writereg_MEM || rt_ID == writereg_MEM);
    assign match_WB  = (writereg_WB  != 5'd0) && (rs_ID == writereg_WB  || rt_ID == writereg_WB);

    assign stall = (
        (memtoreg_EX  && match_EX)  ||
        (regwrite_EX  && match_EX)  ||
        (memtoreg_MEM && match_MEM) ||
        (regwrite_MEM && match_MEM) ||
        (memtoreg_WB  && match_WB)  ||
        (regwrite_WB  && match_WB)  ||
        jump_ID                     ||
        branch_ID                   ||
        branch_EX                   ||
        branch_MEM
    );
endmodule
