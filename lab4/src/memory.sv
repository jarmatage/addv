module memory #( 
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 8
) (
    input  logic                  wclk,
    input  logic                  wen,
    input  logic                  full,
    input  logic [ADDR_WIDTH-1:0] waddr,
    input  logic [ADDR_WIDTH-1:0] raddr,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic [DATA_WIDTH-1:0] rdata
);

    localparam int DATA_DEPTH = (1 << ADDR_WIDTH);

    // Inject write data bug
    logic [DATA_WIDTH-1:0] wdata_bug;
    `ifdef BUGGED
        assign wdata_bug = (wdata == 'd21) ? '0 : wdata; // Bug: if wdata is 21, write 0 instead
    `else
        assign wdata_bug = wdata;
    `endif

    // Create memory block
    logic [DATA_WIDTH-1:0] mem [0:DATA_DEPTH-1];

    // Read from memory asynchronously
    assign rdata = mem[raddr];

    // Write to memory synchronously
    always_ff @(posedge wclk)
        if (wen && !full) mem[waddr] <= wdata_bug;
   
endmodule
