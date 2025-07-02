module tb_mips ();
    instr_gen gen;

    // DUT signals
    logic clk, reset;
    wire [31:0] writedata, dataadr;
    wire memwrite;

    // Instantiate top module
    top dut(.*);

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

    // Setup instruction monitor
    instruction_monitor mon;

    initial begin
        mon = instruction_monitor::type_id::create("mon", this);
        uvm_config_db#(virtual imem_if)::set(null, "*", "vif", dut.my_imem_if);
    end

    // Initialize instruction memory
    initial begin
        gen = new();
        gen.gen_sequence();
        gen.display_all();
        $readmemh("memfile.dat", dut.imem.RAM, 0, 255);
    end

    // Main test sequence
    initial begin
        reset = 1'b1;
        #50;
        reset = 1'b0;
        wait (dut.imem.a == 8'hFF);
        $display("End of instruction memory reached, stopping simulation.");
        $finish;
    end
endmodule
