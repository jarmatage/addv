`timescale 1ns / 1ps

module even_odd_ac #(
    parameter int DATA_W = 8,
    parameter int DEPTH = 40
) (
    input  logic             clk,
    input  logic             rst_n,

    // write interface
    input  logic             wen,
    input  logic [DATA_W-1:0] din,

    // read interface
    input  logic             ren,
    output logic [DATA_W-1:0] dout
);
    
    localparam int ADDR_W = $clog2(DEPTH);


    logic              even_wr_en, odd_wr_en;
    logic [DATA_W-1:0] even_wr_data, odd_wr_data;
    logic              even_full, odd_full;


    always_comb begin
        even_wr_en   = 1'b0;
        odd_wr_en    = 1'b0;
        even_wr_data = '0;
        odd_wr_data  = '0;



        if (write_en_in) begin
            if (data_in[0] == 1'b0) begin
                // route to even FIFO if not full
                if (!even_full) begin
                    even_wr_en   = 1'b1;
                    even_wr_data = data_in;
                end
            end else begin
                // route to odd FIFO if not full
                if (!odd_full) begin
                    odd_wr_en   = 1'b1;
                    odd_wr_data = data_in;
                end
            end
        end
    end

    sync_fifo #(
        .DATA_WIDTH(DATA_W),
        .ADDR_WIDTH(ADDR_W)
    ) even_fifo (
        .clk    (clk),
        .reset_n  (reset_n),
        .wr_en    (even_wr_en),
        .wr_data  (even_wr_data),
        .full     (even_full),
        .rd_en    (),            // driven by read logic below
        .rd_data  (),            // we capture it in even_fifo_dout
        .empty    ()             // we capture in even_fifo_empty
    );


    sync_fifo #(
        .DATA_WIDTH(DATA_W),
        .ADDR_WIDTH(ADDR_W)
    ) odd_fifo (
        .clk      (clk),
        .reset_n  (reset_n),
        .wr_en    (odd_wr_en),
        .wr_data  (odd_wr_data),
        .full     (odd_full),
        .rd_en    (),            // driven by read logic below
        .rd_data  (),            // we capture it in odd_fifo_dout
        .empty    ()             // we capture in odd_fifo_empty
    );


    // Capture each FIFO’s empty flag and rd_data output.
    logic              even_fifo_empty, odd_fifo_empty;
    logic [DATA_W-1:0] even_fifo_dout, odd_fifo_dout;


    assign even_fifo_empty = even_fifo.empty;
    assign odd_fifo_empty  = odd_fifo.empty;
    assign even_fifo_dout  = even_fifo.rd_data;
    assign odd_fifo_dout   = odd_fifo.rd_data;

    typedef enum logic {READ_EVEN = 1'b0, READ_ODD = 1'b1} read_sel_t;
    read_sel_t curr_sel;


    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            curr_sel <= READ_EVEN;
        end else begin
            if (valid_out) begin
                curr_sel <= (curr_sel == READ_EVEN) ? READ_ODD : READ_EVEN;
            end
        end
    end


    logic even_fifo_rd_en, odd_fifo_rd_en;

    always_comb begin
        even_fifo_rd_en = 1'b0;
        odd_fifo_rd_en  = 1'b0;
        data_out        = '0;
        valid_out       = 1'b0;


        if (read_en_in) begin
            if (curr_sel == READ_EVEN) begin
                if (!even_fifo_empty) begin
                    even_fifo_rd_en = 1'b1;
                    data_out        = even_fifo_dout;
                    valid_out       = 1'b1;
                end else if (!odd_fifo_empty) begin
                    odd_fifo_rd_en  = 1'b1;
                    data_out        = odd_fifo_dout;
                    valid_out       = 1'b1;
                end

            end else begin  // curr_sel == READ_ODD
                if (!odd_fifo_empty) begin
                    odd_fifo_rd_en = 1'b1;
                    data_out       = odd_fifo_dout;
                    valid_out      = 1'b1;
                end else if (!even_fifo_empty) begin
                    even_fifo_rd_en = 1'b1;
                    data_out        = even_fifo_dout;
                    valid_out       = 1'b1;
                end
                // if both empty, valid_out remains 0
            end
        end
    end


    assign even_fifo.rd_en = even_fifo_rd_en;
    assign odd_fifo.rd_en  = odd_fifo_rd_en;


endmodule

