module ex_mem(
    input  logic        clk,
    input  logic        reset,
    // Control in
    input  logic        memtoreg_EX,
    input  logic        memwrite_EX,
    input  logic        regwrite_EX,
    // Data in
    input  logic [31:0] aluout_EX,
    input  logic [31:0] writedata_EX,
    input  logic [4:0]  writereg_EX,
    // Control out
    output logic        memtoreg_MEM,
    output logic        memwrite_MEM,
    output logic        regwrite_MEM,
    // Data out
    output logic [31:0] aluout_MEM,
    output logic [31:0] writedata_MEM,
    output logic [4:0]  writereg_MEM
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            memtoreg_MEM  <= '0;
            memwrite_MEM  <= '0;
            regwrite_MEM  <= '0;
            aluout_MEM    <= '0;
            writedata_MEM <= '0;
            writereg_MEM  <= '0;
        end else begin
            memtoreg_MEM  <= memtoreg_EX;
            memwrite_MEM  <= memwrite_EX;
            regwrite_MEM  <= regwrite_EX;
            aluout_MEM    <= aluout_EX;
            writedata_MEM <= writedata_EX;
            writereg_MEM  <= writereg_EX;
        end
    end
endmodule
