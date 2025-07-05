module tb_mips ();
    instr_gen gen;

    // DUT signals
    logic clk, reset;
    wire [31:0] writedata, dataadr;
    wire memwrite;

    // Imem interface
    mips_if my_mips_if (.clk(clk), .reset(reset));

    // Instantiate top module
    top dut(my_mips_if.DUT);

    // Clock generation
    initial clk = 1'b0;
    always #5 clk = ~clk; // 10ns clock period

    // FSDB dump
    initial begin
        `ifdef DUMP
            $display("Dumping to FSDB");
            $fsdbDumpvars();
        `endif
    end

    // Initialize instruction memory
    initial begin
        gen = new();
        gen.gen_sequence();
        gen.display_all();
        $readmemh("memfile.dat", dut.imem.RAM, 0, 255);
    end

    // Start instruction test
    initial begin
        uvm_config_db#(virtual mips_if)::set(null, "*", "vif", my_mips_if);
        run_test("instr_test");
    end

    // Main test sequence
    initial begin
        reset = 1'b1;
        #50;
        reset = 1'b0;
        $display("Reset deasserted, starting program.");
        wait (dut.imem.a == 8'hFF);
        $display("End of instruction memory reached, stopping simulation.");
        $finish;
    end
endmodule
