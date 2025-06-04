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
    logic [DATA_W-1:0] even_wr_data, odd_wr_data;
    logic [DATA_W-1:0] even_rd_data, odd_rd_data;

    // Create even FIFO
    sync_fifo #(
        .DATA_WIDTH(DATA_W),
        .ADDR_WIDTH(ADDR_W)
    ) even_fifo (
        .clk      (clk),
        .reset_n  (rst_n),
        .wr_en    (even_wr_en),
        .wr_data  (even_wr_data),
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
        .reset_n  (reset_n),
        .wr_en    (odd_wr_en),
        .wr_data  (odd_wr_data),
        .full     (odd_full),
        .rd_en    (odd_rd_en),
        .rd_data  (odd_rd_data),
        .empty    (odd_empty)
    );

    // Determine which FIFO to write to
    assign even_wr_en = wen && !din[0];
    assign odd_wr_en  = wen && din[0];

    // Setup FSM for reading
    typedef enum logic {EVEN_NEXT, ODD_NEXT} state_t;
    state_t state, next_state;

    // Add a reset for the FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= EVEN_NEXT;
        else
            state <= next_state;
    end


    always_comb begin
        // Default values
        even_rd_en = 1'b0;
        odd_rd_en  = 1'b0;
        dout       = (DATA_W)'(0);
        next_state = state;

        case (state)
            EVEN_NEXT: begin
                if (ren && !even_empty) begin
                    even_rd_en = 1'b1;
                    dout       = even_rd_data;
                    next_state = ODD_NEXT;
                end
            end

            ODD_NEXT: begin
                if (ren && !odd_empty) begin
                    odd_rd_en  = 1'b1;
                    dout       = odd_rd_data;
                    next_state = EVEN_NEXT;
                end
            end
        endcase
    end

endmodule
