import uvm_pkg::*;
`include "uvm_macros.svh"

import apb_master_pkg::*;
import apb_slave_pkg::*;
`include "apb_test.svh"

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
    
    // Start instruction test
    initial begin
        uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", apb);
        run_test("apb_test");
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
    
    // Timeout
    initial begin
        #2_000;
        $display("ERROR: Timeout");
        $finish;
    end

    // Perform test    
    initial begin
        `ifdef DUMP
            $display("Dumping to FSDB");
            $fsdbDumpvars();
        `endif

        set_matrices_fp8();
        display_inputs_fp8();

        // Setup the control registers
        #115;
        $display("\nWriting to APB...");
        write(4'd1, 16'd0);  // Mat A
        write(4'd2, 16'd0);  // Mat B
        write(4'd3, 16'd0);  // Mat C
        write(4'd4, 16'd1);  // Stride A
        write(4'd5, 16'd1);  // Stride B
        write(4'd6, 16'd1);  // Stride C
        write(4'd8, 16'd1);  // is_fp8
        write(4'd0, 16'd1);  // Start

        // Wait for the done flag
        $display("\nListening for done signal...");
        wait_done(4'd7);     // Done
        write(4'd0, 16'd0);  // Start
        #100;         
        display_output_fp8();

        $display("\nAll done!");
        $finish;
    end
    
    ////////////////////////////////////////////
    // Task to write into the configuration block of the DUT
    ////////////////////////////////////////////
    task write(input [`ADDR_WIDTH-1:0] addr, input [`DATA_WIDTH-1:0] data);
        @(negedge clk);
        apb.PSEL = 1;
        apb.PWRITE = 1;
        apb.PADDR = addr;
        apb.PWDATA = data;
        @(negedge clk);
        apb.PENABLE = 1;
        @(negedge clk);
        apb.PSEL = 0;
        apb.PENABLE = 0;
        apb.PWRITE = 0;
        apb.PADDR = 0;
        apb.PWDATA = 0;
        $display("%t: PADDR %h, PWDATA %h", $time, addr, data);
    endtask

    ////////////////////////////////////////////
    // Task to read from the configuration block of the DUT
    ////////////////////////////////////////////
    task read(input [`ADDR_WIDTH-1:0] addr, output [`DATA_WIDTH-1:0] data);
        @(negedge clk);
        apb.PSEL = 1;
        apb.PWRITE = 0;
        apb.PADDR = addr;
        @(negedge clk);
        apb.PENABLE = 1;
        @(negedge clk);
        apb.PSEL = 0;
        apb.PENABLE = 0;
        data = apb.PRDATA;
        apb.PADDR = 0;
        $display("%t: PADDR %h, PRDATA %h",$time, addr,data);
    endtask

    ////////////////////////////////////////////
    // Task to listen for the done signal
    ////////////////////////////////////////////
    task wait_done(input [`ADDR_WIDTH-1:0] addr);
        @(negedge clk);
        apb.PSEL = 1;
        apb.PWRITE = 0;
        apb.PADDR = addr;
        @(negedge clk);
        apb.PENABLE = 1;

        do begin
            @(negedge clk);
            status = apb.PRDATA;
            $display("%t: PADDR %h, PRDATA %b",$time, addr, status);
        end while (status[0] == 1'b0);

        apb.PSEL = 0;
        apb.PENABLE = 0;
        apb.PADDR = 0;
    endtask

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

    ////////////////////////////////////////////
    // Helpers for displaying the FP8 values
    ////////////////////////////////////////////
    task automatic display_inputs_fp8();
        $display("\nA =");
        for (int i = 0; i <= 24; i += 8) begin
            $write("|");
            for (int j = 0; j < 4; j++) begin
                $write(" ");
                display_fp8(u_matmul.matrix_A.ram[j][i+:8]);
            end
            $display(" |");
        end

        $display("\nB =");
        for (int i = 0; i < 4; i++) begin
            $write("|");
            for (int j = 0; j <= 24; j += 8) begin
                $write(" ");
                display_fp8(u_matmul.matrix_B.ram[i][j+:8]);
            end
            $display(" |");
        end
    endtask

    task automatic display_output_fp8();
        $display("\nOutput =");
        for (int i = 0; i <= 24; i += 8) begin
            $write("|");
            for (int j = 0; j < 4; j++) begin
                $write(" ");
                display_fp8(u_matmul.matrix_C.ram[j][i+:8]);
            end
            $display(" |");
        end
        $display("flags = %b", status[5:1]);
    endtask

    task display_fp8(input logic [7:0] fp);
        real abs_fp;

        if (fp[7]) begin
            abs_fp = -fp8_to_real(fp);
            $write("-");
        end else begin
            abs_fp = fp8_to_real(fp);
            $write("+");
        end

        if (fp[6:0] == 7'b111_0000)
            $write("inf     ");
        else if (fp[6:4] == 3'b111)
            $write("nan     ");
        else if (fp[6:0] == 7'b000_0000)
            $write("0.000000");
        else
            $write("%f", abs_fp);
    endtask   

    function real fp8_to_real(input logic [7:0] fp);
        logic sign;
        logic [2:0] exp;
        logic [3:0] mant;
        int unbiased_exp;
        real r_mant;

        sign = fp[7];
        exp  = fp[6:4];
        mant = fp[3:0];

        if (exp == 0 && mant == 0) return 0.0;

        unbiased_exp = exp - 3;
        r_mant = 1.0 + mant / 16.0;
        return (sign ? -1.0 : 1.0) * r_mant * (2.0 ** unbiased_exp);
    endfunction

endmodule
