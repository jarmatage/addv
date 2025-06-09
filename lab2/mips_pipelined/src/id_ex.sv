module id_ex(
    input  logic        clk,
    input  logic        reset,
    input  logic        stall,
    // Control in
    input  logic        memtoreg_ID,
    input  logic        memwrite_ID,
    input  logic        alusrc_ID,
    input  logic        regdst_ID,
    input  logic        regwrite_ID,
    input  logic        branch_ID,
    input  logic [2:0]  alucontrol_ID,
    // Data in
    input  logic [31:0] pcplus4_ID,
    input  logic [31:0] srca_ID,
    input  logic [31:0] writedata_ID,
    input  logic [31:0] signimm_ID,
    input  logic [31:0] instr_ID,
    // Control out
    output logic        memtoreg_EX,
    output logic        memwrite_EX,
    output logic        alusrc_EX,
    output logic        regdst_EX,
    output logic        regwrite_EX,
    output logic        branch_EX,
    output logic [2:0]  alucontrol_EX,
    // Data out
    output logic [31:0] pcplus4_EX,
    output logic [31:0] srca_EX,
    output logic [31:0] writedata_EX,
    output logic [31:0] signimm_EX,
    output logic [31:0] instr_EX
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            branch_EX <= 1'b0;
        else
            branch_EX <= branch_ID;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset || stall) begin
            memtoreg_EX   <= '0;
            memwrite_EX   <= '0;
            alusrc_EX     <= '0;
            regdst_EX     <= '0;
            regwrite_EX   <= '0;
            alucontrol_EX <= '0;
            pcplus4_EX    <= '0;
            srca_EX       <= '0;
            writedata_EX  <= '0;
            signimm_EX    <= '0;
            instr_EX      <= '0;
        end else begin
            memtoreg_EX   <= memtoreg_ID;
            memwrite_EX   <= memwrite_ID;
            alusrc_EX     <= alusrc_ID;
            regdst_EX     <= regdst_ID;
            regwrite_EX   <= regwrite_ID;
            alucontrol_EX <= alucontrol_ID;
            pcplus4_EX    <= pcplus4_ID;
            srca_EX       <= srca_ID;
            writedata_EX  <= writedata_ID;
            signimm_EX    <= signimm_ID;
            instr_EX      <= instr_ID;
        end
    end
endmodule
