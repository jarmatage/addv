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
    matrix_multiplication u_matmul(
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
endmodule
