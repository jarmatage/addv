import uvm_pkg::*;
`include "uvm_macros.svh"

import memory_pkg::*;
import apb_master_pkg::*;
import apb_slave_pkg::*;
`include "apb_test_no_ram.svh"

module matmul_tb;
    // Set the timescale
    timeunit 1ns;
    timeprecision 100ps;

    // DUT signals
    logic clk;
    logic resetn;
    memory_if ram_a(clk, resetn);
    memory_if ram_b(clk, resetn);
    memory_if ram_c(clk, resetn);
    apb_if apb(clk, resetn);

    // DUT
    matrix_multiplication dut(
        .ram_a(ram_a.DUT_READ),
        .ram_b(ram_b.DUT_READ),
        .ram_c(ram_c.DUT_WRITE),
        .apb(apb.slave)
    );

    // Clock generation  
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // Reset
    initial begin
        resetn = 1'b0;
        #55;
        resetn = 1'b1;
    end
    
    // Perform test    
    initial begin
        `ifdef DUMP
            $display("Dumping to FSDB");
            $fsdbDumpvars();
        `endif
        uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", apb);
        uvm_config_db#(virtual memory_if)::set(null, "*", "ram_a_vif", ram_a);
        uvm_config_db#(virtual memory_if)::set(null, "*", "ram_b_vif", ram_b);
        uvm_config_db#(virtual memory_if)::set(null, "*", "ram_c_vif", ram_c);
        run_test("apb_test");
    end

    // Inject errors
    initial begin
        #55;
        
        $display("Injecting error: forcing bram_we_c = 0");
        wait(dut.start_mat_mul)
        force dut.ram_c.en = 1'b0;
        #250;
        release dut.ram_c.en;
        #50;

        $display("Injecting error: forcing write/read enable = 1 during reset");
        resetn = 1'b0;
        force dut.ram_c.en = 1'b1;
        #20;
        resetn = 1'b1;
        release dut.ram_c.en;

        $display("Injecting error: forcing addr to invalid value 0x1FF");
        force dut.ram_a.addr = 10'd8;
        force dut.ram_a.en = 1'b1;
        #20;
        release dut.ram_a.addr;
        release dut.ram_a.en;

        $display("Injecting error: forcing stride to 0");
        force dut.start_mat_mul = 1'b1;
        force dut.address_stride_a = 1'b0;
        #20;
        release dut.address_stride_a;
        release dut.start_mat_mul;
        $display("Finished with errors");
        $finish;
    end
endmodule
