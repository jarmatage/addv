module mem_wb(
    input  logic        clk,
    input  logic        reset,
    // Control in
    input  logic        branch_MEM,
    input  logic        memtoreg_MEM,
    input  logic        regwrite_MEM,
    // Data in
    input  logic [31:0] aluout_MEM,
    input  logic [31:0] readdata_MEM,
    input  logic [4:0]  writereg_MEM,
    // outputs
    output logic        branch_WB,
    output logic        memtoreg_WB,
    output logic        regwrite_WB,
    output logic [31:0] aluout_WB,
    output logic [31:0] readdata_WB,
    output logic [4:0]  writereg_WB
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            branch_WB   <= '0;
            memtoreg_WB <= '0;
            regwrite_WB <= '0;
            aluout_WB   <= '0;
            readdata_WB <= '0;
            writereg_WB <= '0;
        end else begin
            branch_WB   <= branch_MEM;
            memtoreg_WB <= memtoreg_MEM;
            regwrite_WB <= regwrite_MEM;
            aluout_WB   <= aluout_MEM;
            readdata_WB <= readdata_MEM;
            writereg_WB <= writereg_MEM;
        end
    end
endmodule
