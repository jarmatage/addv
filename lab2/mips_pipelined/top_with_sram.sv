module top (
    input  logic        clk, reset,
    output logic [31:0] writedata,
    output logic [31:0] dataadr,
    output logic        memwrite
);
    wire [31:0] pc, instr, readdata;

    // instantiate processor and memories
    mips mips (
        .clk,
        .reset,
        .pc,
        .instr,
        .memwrite,
        .aluout(dataadr),
        .writedata,
        .readdata
    );
    imem imem (
        .a(pc[7:2]),
        .rd(instr)
    );
    dmem dmem (
        .clk, 
        .we(memwrite),
        .a(dataadr),
        .wd(writedata),
        .rd(readdata)
    );
endmodule


module dmem (
    input  logic        clk, we,
    input  logic [31:0] a, wd,
    output logic [31:0] rd
);
    // OpenRAM signals
    wire csb0;          // Chip select (active low)
    wire web0;          // Write enable (active low)
    wire [5:0] addr0;   // 6-bit address
    wire [31:0] din0;   // Data input
    wire [31:0] dout0;  // Data output
    

    assign csb0 = 1'b0;         // Always enabled
    assign web0 = ~we;          // Invert we (active high to active low)
    assign addr0 = a[7:2];      // Word-aligned address (6 bits)
    assign din0 = wd;           // Write data
    assign rd = dout0;          // Read data
    
    // OpenRAM instantiation
    SRAM_32x64_1rw dmem_ram (
        .clk0(clk),
        .csb0(csb0),
        .web0(web0),
        .addr0(addr0),
        .din0(din0),
        .dout0(dout0)
    );
endmodule


module imem (
    input  logic [5:0]  a,
    output logic [31:0] rd
);
    // OpenRAM interface signals
    wire clk0;          // Clock
    wire csb0;          // Chip select (active low)
    wire web0;          // Write enable (active low)
    wire [5:0] addr0;   // 6-bit address
    wire [31:0] din0;   // Data input
    wire [31:0] dout0;  // Data output
    
    // Control signal connections
    assign clk0 = 1'b0;         // No clock needed for read-only
    assign csb0 = 1'b0;         // Always enabled
    assign web0 = 1'b1;         // Always read (never write)
    assign addr0 = a;           // Address from processor
    assign din0 = 32'b0;        // No data to write
    assign rd = dout0;          // Read data
    
    // OpenRAM instantiation
    SRAM_32x64_1rw imem_ram (
        .clk0(clk0),
        .csb0(csb0),
        .web0(web0),
        .addr0(addr0),
        .din0(din0),
        .dout0(dout0)
    );
endmodule
