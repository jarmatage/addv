// SystemVerilog Testbench for MIPS Processor
module MIPS_Testbench();
    // Clock and reset signals
    logic clk;
    logic reset;

    // DUT outputs
    logic [31:0] writedata;
    logic [31:0] dataadr;
    logic        memwrite;

    // Loop index
    int i, j;

    // Expected memory writes
    parameter int N = 2;
    logic [31:0] expected_data [1:N];
    logic [31:0] expected_addr [1:N];

    // Instantiate top module
    top dut (
        .clk       (clk),
        .reset     (reset),
        .writedata (writedata),
        .dataadr   (dataadr),
        .memwrite  (memwrite)
    );

    // Initial setup
    initial begin
        // Expected values
        expected_data[1] = 32'h7;
        expected_addr[1] = 32'h50;
        expected_data[2] = 32'h7;
        expected_addr[2] = 32'h54;

        // Initialize clock and reset
        clk   = 0;
        reset = 1;
        #10;
        reset = 0;
    end

    // Clock generation
    always #5 clk = ~clk;

    // Monitor memory writes
    initial begin
        for (i = 1; i <= N; i++) begin
            @(posedge memwrite);
            @(negedge clk);
            if (dataadr == expected_addr[i] && writedata == expected_data[i]) begin
                $display("Memory write %0d successful: wrote %h to address %h", i, writedata, dataadr);
            end else begin
                $display("ERROR: Memory write %0d: wrote %h to address %h; expected %h to address %h", 
                         i, writedata, dataadr, expected_data[i], expected_addr[i]);
            end
        end
        $display("TEST COMPLETE");
        $finish;
    end
endmodule
