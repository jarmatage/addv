//////////////////////////////////////////////////////////////////////////
// Processing element (PE)
//////////////////////////////////////////////////////////////////////////
module processing_element(
    input  logic                reset,
    input  logic                clk,
    input  logic                is_fp8, // unused by this file but used in matmul.sv
    output logic [4:0]          flags,
    input  logic [`DWIDTH-1:0]  in_a,
    input  logic [`DWIDTH-1:0]  in_b,
    output logic [`DWIDTH-1:0]  out_a,
    output logic [`DWIDTH-1:0]  out_b,
    output logic [`DWIDTH-1:0]  out_c
    );

    logic [`DWIDTH-1:0] out_mac;

    assign out_c = out_mac;
    
    fp8_mac u_mac(.a(in_a), .b(in_b), .out(out_mac), .reset(reset), .clk(clk), .flags(flags));

    always_ff @(posedge clk) begin
        if (reset) begin
            out_a <= 0;
            out_b <= 0;
        end else begin  
            out_a <= in_a;
            out_b <= in_b;
        end
    end

endmodule
