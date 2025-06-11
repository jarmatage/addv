///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Testbench template for MIPS processor
// - This testbench uses two arrays (expected_data and expectd_addr) to store data and addresses of expected operations
// - and for each memory write, it checks if the memory writes match the expected values

// - You need to modify these arrays to match the instructions in memfile.dat file used to initialize imem
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module MIPS_Testbench ();
    reg clk;
    reg reset;
    wire [31:0] writedata, dataadr;
    wire memwrite;

    integer i;
    integer j;

    // expected memory writes
    parameter N = 11; 
    reg [31:0] expected_data[N:1];
    reg [31:0] expected_addr[N:1]; 
    
    // Instantiate top module
    top dut(
        .clk(clk),
        .reset(reset),
        .writedata(writedata),
        .dataadr(dataadr),
        .memwrite(memwrite)
    );

    initial begin
        $fsdbDumpvars();
        #1_000;
        $display("ERROR: Timeout");
        $finish;
    end
    
    // Initialize expected data and addresses
    initial begin
        expected_data[1] = 32'd7;
        expected_addr[1] = 32'd56;

        expected_data[2] = 32'd4;
        expected_addr[2] = 32'd60;

        expected_data[3] = 32'd11;
        expected_addr[3] = 32'd64;

        expected_data[4] = 32'd0;
        expected_addr[4] = 32'd68;

        expected_data[5] = 32'd7;
        expected_addr[5] = 32'd80;  

        expected_data[6] = 32'd7;
        expected_addr[6] = 32'd76;

        expected_data[7] = 32'd7;
        expected_addr[7] = 32'd84;

        expected_data[8] = 32'd40;
        expected_addr[8] = 32'd88;

        expected_data[9] = 32'd15;
        expected_addr[9] = 32'd100;

        expected_data[10] = 32'd59;
        expected_addr[10] = 32'h5c;

        expected_data[11] = 32'd33;
        expected_addr[11] = 32'h60;
    end

    // Clock generation
    always begin
        clk <= 1'b0; 
        #5;
        clk <= 1'b1; 
        #5;
    end
    
    // Monitor memory write signals
    always begin
        // Initialize reset
        reset = 1'b1;
        @(posedge clk);
        @(posedge clk);
        reset = 1'b0;

        for(i = 1; i<=N; i=i+1) begin
            // Wait for memory write signal
            @(posedge memwrite);

            @(negedge clk);
            // Check if both data and address are expected values
            if (dataadr == expected_addr[i] && writedata == expected_data[i]) begin
                $display("Memory write %0d successful : wrote %h to address %h", i, writedata, dataadr);
            end else begin
                $display("ERROR: Memory write %0d : wrote %h to address %h ; Expected %h to address %h)", 
                         i, writedata, dataadr, expected_data[i], expected_addr[i]);
            end            
        end
        $display("TEST COMPLETE");
        $finish;
    end
endmodule
