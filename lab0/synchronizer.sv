module synchronizer #(
    parameter int WIDTH = 8
) (
    input  logic             clk,
    input  logic [WIDTH-1:0] async_data,
    output logic [WIDTH-1:0] sync_data
);

    logic [WIDTH-1:0] unstable_data;

    always_ff @(posedge clk) begin
        unstable_data <= async_data;
        sync_data <= unstable_data;
    end

endmodule
