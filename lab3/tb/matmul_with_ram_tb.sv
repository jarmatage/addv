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


module matmul_tb;
    // Set the timescale
    timeunit 1ns;
    timeprecision 100ps;

    // DUT signals
    logic clk;
    logic resetn;
    logic is_fp8;
    logic pe_resetn;
    logic start;
    wire done;

    // DUT
    matrix_multiplication u_matmul(
        .clk(clk), 
        .resetn(resetn), 
        .is_fp8(is_fp8),
        .pe_resetn(pe_resetn), 
        .address_mat_a(10'b0),
        .address_mat_b(10'b0),
        .address_mat_c(10'b0),
        .address_stride_a(8'd1),
        .address_stride_b(8'd1),
        .address_stride_c(8'd1),
        .start(start),
	    .done(done)
    );
    
    // Clock generation  
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end
    
    // Reset
    initial begin
        resetn = 1'b0;
        is_fp8 = 1'b0;
        pe_resetn = 1'b0;
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
        set_matrices_int8();
        start = 1'b0;
        #115;
        start = 1'b1;
        @(posedge done);
        start = 1'b0;
        #100;         
        display_output();
        $finish;
    end
    
    //  A           B        Output       Output in hex
    // 8 4 6 8   1 1 3 0   98 90 82 34    62 5A 52 22
    // 3 3 3 7   0 1 4 3   75 63 51 26    4B 3F 33 1A
    // 5 2 1 6   3 5 3 1   62 48 44 19    3E 30 2C 13
    // 9 1 0 5   9 6 3 2   54 40 46 13    36 28 2E 0D
    task automatic set_matrices_int8();
        //A is stored in ROW MAJOR format
        //A[0][0] (8'h08) should be the least significant byte of ram[0]
        //The first column of A should be read together. So, it needs to be 
        //placed in the first matrix_A ram location.
        //This is due to Verilog conventions declaring {MSB, ..., LSB}
        u_matmul.matrix_A.ram[3]  = {8'h05, 8'h06, 8'h07, 8'h08}; 
        u_matmul.matrix_A.ram[2]  = {8'h00, 8'h01, 8'h03, 8'h06};
        u_matmul.matrix_A.ram[1]  = {8'h01, 8'h02, 8'h03, 8'h04};
        u_matmul.matrix_A.ram[0]  = {8'h09, 8'h05, 8'h03, 8'h08};

        //B is stored in COL MAJOR format
        //B[0][0] (8'h01) should be the least significant of ram[0]
        //The first row of B should be read together. So, it needs to be 
        //placed in the first matrix_B ram location. 
        u_matmul.matrix_B.ram[3]  = {8'h02, 8'h03, 8'h06, 8'h09};
        u_matmul.matrix_B.ram[2]  = {8'h01, 8'h03, 8'h05, 8'h03};
        u_matmul.matrix_B.ram[1]  = {8'h03, 8'h04, 8'h01, 8'h00};
        u_matmul.matrix_B.ram[0]  = {8'h00, 8'h03, 8'h01, 8'h01};
    endtask

    task automatic display_output();
        $display("\nOutput =");
        for (int i = 0; i <= 24; i += 8) begin
            $write("|");
	    for (int j = 0; j < 4; j++) begin
                $write(" %d", u_matmul.matrix_C.ram[j][i+:8]);
	    end
            $display(" |");
        end
    endtask

endmodule
