`timescale 1ns / 1ps

module sync_fifo #(
	parameter int DATA_WIDTH = 8,
	parameter int ADDR_WIDTH = 3
) (
    input  logic                  clk,
    input  logic                  reset_n,   
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);

    localparam int DEPTH = (1 << ADDR_WIDTH);

    //Memory array
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Binary pointers
    logic [ADDR_WIDTH:0] wr_ptr_bin, rd_ptr_bin;
    
    // Slice the binary pointers
    logic [ADDR_WIDTH-1:0] wr_addr, rd_addr;
    assign wr_addr = wr_ptr_bin[ADDR_WIDTH-1:0];
    assign rd_addr = rd_ptr_bin[ADDR_WIDTH-1:0];

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            wr_ptr_bin <= '0;
        end else if (wr_en && !full) begin
            mem[wr_addr] <= wr_data;
            wr_ptr_bin      <= wr_ptr_bin + 1'b1;
        end
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rd_ptr_bin <= '0;
            rd_data    <= '0;
        end else if (rd_en && !empty) begin
            rd_data    <= mem[rd_addr];
            rd_ptr_bin <= rd_ptr_bin + 1'b1;
        end
    end

    assign empty = (wr_ptr_bin == rd_ptr_bin);
    assign full  = (wr_ptr_bin == {~rd_ptr_bin[ADDR_WIDTH], rd_ptr_bin[ADDR_WIDTH-1:0]});

endmodule
