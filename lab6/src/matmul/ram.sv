module ram (
    input  logic [`AWIDTH-1:0]             addr0,
    input  logic [`MASK_WIDTH*`DWIDTH-1:0] d0,
    input  logic [`MASK_WIDTH-1:0]         we0,
    output logic [`MASK_WIDTH*`DWIDTH-1:0] q0,
    input  logic [`AWIDTH-1:0]             addr1,
    input  logic [`MASK_WIDTH*`DWIDTH-1:0] d1,
    input  logic [`MASK_WIDTH-1:0]         we1,
    output logic [`MASK_WIDTH*`DWIDTH-1:0] q1,
    input  logic                           clk
    );

    logic [31:0] ram[((1<<`AWIDTH)-1):0];

    always @(posedge clk) begin // keep as "always" to avoid multiple drivers error
        if (|we0) ram[addr0] <= d0;
        q0 <= ram[addr0];
    end

    always @(posedge clk) begin // keep as "always" to avoid multiple drivers error
        if (|we1) ram[addr1] <= d1;
        q1 <= ram[addr1];
    end
    
endmodule
