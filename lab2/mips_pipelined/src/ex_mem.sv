module ex_mem(
    input  logic        clk,
    input  logic        reset,
    // Control in
    input  logic        memtoreg_EX,
    input  logic        memwrite_EX,
    input  logic        regwrite_EX,
    input  logic        branch_EX,
    input  logic        zero_EX,
    // Data in
    input  logic [31:0] aluout_EX,
    input  logic [31:0] rt_data_EX,
    input  logic [31:0] pcbranch_EX,
    input  logic [4:0]  destReg_EX,
    // Control out
    output logic        memtoreg_MEM,
    output logic        memwrite_MEM,
    output logic        regwrite_MEM,
    output logic        branch_MEM,
    output logic        zero_MEM,
    // Data out
    output logic [31:0] aluout_MEM,
    output logic [31:0] rt_data_MEM,
    output logic [31:0] pcbranch_MEM,
    output logic [4:0]  destReg_MEM
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            memtoreg_MEM <= '0;
            memwrite_MEM <= '0;
            regwrite_MEM <= '0;
            branch_MEM   <= '0;
            zero_MEM     <= '0;
            aluout_MEM   <= '0;
            rt_data_MEM  <= '0;
            pcbranch_MEM <= '0;
            destReg_MEM  <= '0;
        end else begin
            memtoreg_MEM <= memtoreg_EX;
            memwrite_MEM <= memwrite_EX;
            regwrite_MEM <= regwrite_EX;
            branch_MEM   <= branch_EX;
            zero_MEM     <= zero_EX;
            aluout_MEM   <= aluout_EX;
            rt_data_MEM  <= rt_data_EX;
            pcbranch_MEM <= pcbranch_EX;
            destReg_MEM  <= destReg_EX;
        end
    end
endmodule
