module seq_mac(
    input logic [`DWIDTH-1:0] a,
    input logic [`DWIDTH-1:0] b,
    input logic reset,
    input logic clk,
    output logic [`DWIDTH-1:0] out
    );

    logic [`DWIDTH-1:0] a_flop, b_flop, mult;

    always_ff @(posedge clk) begin
        if (reset) begin
            out <= 0;
            a_flop <= 0;
            b_flop <= 0;
            mult <= 0;
        end else begin
            a_flop <= a;
            b_flop <= b;

            mult <= a_flop * b_flop; 
            out <= mult + out; 
        end
    end

endmodule
