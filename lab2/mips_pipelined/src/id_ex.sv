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
    input  logic [31:0] pc4_ID,
    input  logic [31:0] rs_data_ID,
    input  logic [31:0] rt_data_ID,
    input  logic [31:0] signext_ID,
    input  logic [4:0]  rs_ID,
    input  logic [4:0]  rt_ID,
    input  logic [4:0]  rd_ID,
    // Control out
    output logic        memtoreg_EX,
    output logic        memwrite_EX,
    output logic        alusrc_EX,
    output logic        regdst_EX,
    output logic        regwrite_EX,
    output logic        branch_EX,
    output logic [2:0]  alucontrol_EX,
    // Data out
    output logic [31:0] pc4_EX,
    output logic [31:0] rs_data_EX,
    output logic [31:0] rt_data_EX,
    output logic [31:0] signext_EX,
    output logic [4:0]  rs_EX,
    output logic [4:0]  rt_EX,
    output logic [4:0]  rd_EX
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset || stall) begin
            memtoreg_EX   <= '0;
            memwrite_EX   <= '0;
            alusrc_EX     <= '0;
            regdst_EX     <= '0;
            regwrite_EX   <= '0;
            branch_EX     <= '0;
            alucontrol_EX <= '0;
            pc4_EX        <= '0;
            rs_data_EX    <= '0;
            rt_data_EX    <= '0;
            signext_EX    <= '0;
            rs_EX         <= '0;
            rt_EX         <= '0;
            rd_EX         <= '0;
        end else begin
            memtoreg_EX   <= memtoreg_ID;
            memwrite_EX   <= memwrite_ID;
            alusrc_EX     <= alusrc_ID;
            regdst_EX     <= regdst_ID;
            regwrite_EX   <= regwrite_ID;
            branch_EX     <= branch_ID;
            alucontrol_EX <= alucontrol_ID;
            pc4_EX        <= pc4_ID;
            rs_data_EX    <= rs_data_ID;
            rt_data_EX    <= rt_data_ID;
            signext_EX    <= signext_ID;
            rs_EX         <= rs_ID;
            rt_EX         <= rt_ID;
            rd_EX         <= rd_ID;
        end
    end
endmodule
