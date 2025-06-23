`timescale 1ns/1ps

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

    // Create memory block
    logic [DATA_WIDTH-1:0] mem [0:DATA_DEPTH-1];

    // Read from memory asynchronously
    assign rdata = mem[raddr];

    // Write to memory synchronously
    always_ff @(posedge wclk)
        if (wen && !full) mem[waddr] <= wdata;
   
endmodule
