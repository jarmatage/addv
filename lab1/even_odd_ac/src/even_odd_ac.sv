`timescale 1ns / 1ps

module even_odd_ac #(
    parameter int DATA_W = 8,
    parameter int DEPTH = 40
) (
    input  logic             clk,
    input  logic             rst_n,

    // write interface
    input  logic              wen,
    input  logic [DATA_W-1:0] din,

    // read interface
    input  logic              ren,
    output logic [DATA_W-1:0] dout
);
    
    localparam int ADDR_W = $clog2(DEPTH);

    // Internal signals
    logic even_full;
    logic odd_full;
    logic even_empty;
    logic odd_empty;
    logic even_wr_en;
    logic odd_wr_en;
    logic even_rd_en;
    logic odd_rd_en;
    logic [DATA_W-1:0] even_rd_data;
    logic [DATA_W-1:0] odd_rd_data;
    logic state;

    // Create even FIFO
    sync_fifo #(
        .DATA_WIDTH(DATA_W),
        .ADDR_WIDTH(ADDR_W)
    ) even_fifo (
        .clk      (clk),
        .reset_n  (rst_n),
        .wr_en    (even_wr_en),
        .wr_data  (din),
        .full     (even_full),
        .rd_en    (even_rd_en),
        .rd_data  (even_rd_data),
        .empty    (even_empty)    
    );

    // Create odd FIFO
    sync_fifo #(
        .DATA_WIDTH(DATA_W),
        .ADDR_WIDTH(ADDR_W)
    ) odd_fifo (
        .clk      (clk),
        .reset_n  (rst_n),
        .wr_en    (odd_wr_en),
        .wr_data  (din),
        .full     (odd_full),
        .rd_en    (odd_rd_en),
        .rd_data  (odd_rd_data),
        .empty    (odd_empty)
    );

    // Determine which FIFO to write to
    assign even_wr_en = wen && !din[0];
    assign odd_wr_en  = wen && din[0];

    // Determine which FIFO to read from
    assign even_rd_en = ren && !state;
    assign odd_rd_en  = ren && state;
    assign dout = state ? even_rd_data: odd_rd_data;

    // Alternate between even and odd reading
    always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n)
		state <= 1'b0;
	else if (ren)
		state <= !state;
    end

endmodule

