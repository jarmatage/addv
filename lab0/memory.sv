module memory #( 
    parameter int DATA_WIDTH = 8,
    parameter int DATA_DEPTH = 64,
    parameter int ADDR_WIDTH = $clog2(DATA_DEPTH)
) (
    input  logic                  write_clk,
    input  logic                  write_en,
    input  logic [ADDR_WIDTH-1:0] write_addr,
    input  logic [ADDR_WIDTH-1:0] read_addr,
    input  logic [DATA_WIDTH-1:0] write_data,
    output logic [DATA_WIDTH-1:0] read_data
);

    // Create memory block
    logic [DATA_WIDTH-1:0] mem [0:DATA_DEPTH-1];

    // Read from memory asynchronously
    assign read_data = mem[read_addr];

    // Write to memory synchronously
    always_ff @(posedge write_clk) begin
        if (write_en)
            mem[write_addr] <= write_data;
    end
   
endmodule
