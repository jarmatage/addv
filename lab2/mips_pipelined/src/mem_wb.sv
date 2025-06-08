module mem_wb(
    input  logic        clk,
    input  logic        reset,
    // Control in
    input  logic        memtoreg_MEM,
    input  logic        regwrite_MEM,
    // Data in
    input  logic [31:0] aluout_MEM,
    input  logic [31:0] readdata_MEM,
    input  logic [4:0]  destReg_MEM,
    // outputs
    output logic        memtoreg_WB,
    output logic        regwrite_WB,
    output logic [31:0] aluout_WB,
    output logic [31:0] readdata_WB,
    output logic [4:0]  destReg_WB
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            memtoreg_WB <= '0;
            regwrite_WB <= '0;
            aluout_WB   <= '0;
            readdata_WB <= '0;
            destReg_WB  <= '0;
        end else begin
            memtoreg_WB <= memtoreg_MEM;
            regwrite_WB <= regwrite_MEM;
            aluout_WB   <= aluout_MEM;
            readdata_WB <= readdata_MEM;
            destReg_WB  <= destReg_MEM;
        end
    end
endmodule
