import uvm_pkg::*;
`include "uvm_macros.svh"

import apb_master_pkg::*;
import apb_slave_pkg::*;
`include "apb_test.svh"

import memory_pkg::*;

module matmul_tb;
    // Set the timescale
    timeunit 1ns;
    timeprecision 100ps;

    // DUT signals
    logic clk;
    logic resetn;
    logic pe_resetn;
    apb_if apb(clk, resetn);

    // DUT
    matrix_multiplication u_matmul(
        .clk(clk),
        .resetn(resetn),
        .pe_resetn(pe_resetn),
        .apb(apb.slave)
    );
    
    // Save the output of the done register
    logic [15:0] status;

    // Clock generation  
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // Reset
    initial begin
        resetn = 1'b0;
        pe_resetn = 1'b0;
        apb.PADDR = '0;
        apb.PWRITE = 1'b0;
        apb.PSEL = 1'b0;
        apb.PENABLE = 1'b0;
        apb.PWDATA = '0;
        status = '0;
        #55;
        resetn = 1'b1;
        pe_resetn = 1'b1;
    end
    
    // Perform test    
    initial begin
        `ifdef DUMP
            $display("Dumping to FSDB");
            $fsdbDumpvars();
        `endif
        uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", apb);
        set_matrices_fp8();
        display_inputs_fp8();
        run_test("apb_test");
    end

    // Display the output
    initial begin
        #2_000;
        display_output_fp8();
        $display("\nAll done!");
        $finish;
    end

    ////////////////////////////////////////////
    // Fill the RAMs with FP8 values
    ////////////////////////////////////////////
    task automatic set_matrices_fp8();
        //A is stored in ROW MAJOR format
        //A[0][0] (8'h08) should be the least significant byte of ram[0]
        //The first column of A should be read together. So, it needs to be 
        //placed in the first matrix_A ram location.
        //This is due to Verilog conventions declaring {MSB, ..., LSB}
        u_matmul.matrix_A.ram[3]  = {8'b1_011_0110, 8'b0_101_0001, 8'b0_001_0111, 8'b0_010_0110}; 
        u_matmul.matrix_A.ram[2]  = {8'b1_100_1000, 8'b1_010_0010, 8'b0_010_0110, 8'b0_011_1100};
        u_matmul.matrix_A.ram[1]  = {8'b0_011_0011, 8'b1_001_0100, 8'b1_011_0110, 8'b0_101_0111};
        u_matmul.matrix_A.ram[0]  = {8'b0_100_0001, 8'b0_001_0001, 8'b0_000_0000, 8'b1_011_0111};

        //B is stored in COL MAJOR format
        //B[0][0] (8'h01) should be the least significant of ram[0]
        //The first row of B should be read together. So, it needs to be 
        //placed in the first matrix_B ram location. 
        u_matmul.matrix_B.ram[3]  = {8'b0_011_1000, 8'b0_001_0000, 8'b0_011_0011, 8'b0_100_0000}; 
        u_matmul.matrix_B.ram[2]  = {8'b0_000_1000, 8'b0_010_0100, 8'b0_010_0110, 8'b1_100_1000};
        u_matmul.matrix_B.ram[1]  = {8'b0_011_0000, 8'b1_011_0000, 8'b0_011_0100, 8'b0_011_0000};
        u_matmul.matrix_B.ram[0]  = {8'b0_110_0100, 8'b0_001_0001, 8'b0_000_0000, 8'b0_011_0111};
    endtask
endmodule
