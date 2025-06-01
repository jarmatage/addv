module counter #(
    parameter int MAX = 64,
    parameter int WIDTH = $clog2(MAX)
) (
    input  logic             inc,
    input  logic             dec,
    input  logic             clk,
    input  logic             rst_n, // async reset
    output logic             full,
    output logic             almost_full,
    output logic             empty,
    output logic             almost_empty,
    output logic [WIDTH-1:0] count
);

    localparam logic [WIDTH-1:0] INCR = WIDTH'('d1);
    localparam logic [WIDTH-1:0] EMPTY = WIDTH'('d0);
    localparam logic [WIDTH-1:0] FULL = MAX[WIDTH-1:0];
    localparam logic [WIDTH-1:0] ALMOST_FULL = FULL * 3 / 4;
    localparam logic [WIDTH-1:0] ALMOST_EMPTY = FULL / 4;

    assign full         = count == FULL;
    assign empty        = count == EMPTY;
    assign almost_full  = count == ALMOST_FULL;
    assign almost_empty = count == ALMOST_EMPTY; 

    always_ff @ (posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= EMPTY;
        else if (inc && !dec && !full)
            count <= count + INCR;
        else if (!inc && dec && !empty)
            count <= count - INCR;
    end

endmodule
