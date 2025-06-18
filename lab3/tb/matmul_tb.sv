module matmul_tb;
    // Set the timescale
    timeunit 1ns;
    timeprecision 100ps;

    // DUT signals
    logic clk;
    logic resetn;
    logic pe_resetn;
    logic [`AWIDTH-1:0]               bram_addr_a_ext;
    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] bram_rdata_a_ext;
    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] bram_wdata_a_ext;
    logic [`MASK_WIDTH-1:0]           bram_we_a_ext;
    logic [`AWIDTH-1:0]               bram_addr_b_ext;
    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] bram_rdata_b_ext;
    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] bram_wdata_b_ext;
    logic [`MASK_WIDTH-1:0]           bram_we_b_ext;
    logic [`AWIDTH-1:0]               bram_addr_c_ext;
    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] bram_rdata_c_ext;
    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] bram_wdata_c_ext;
    logic [`MASK_WIDTH-1:0]           bram_we_c_ext;
    logic [`REG_ADDRWIDTH-1:0]        PADDR;
    logic                             PWRITE;
    logic                             PSEL;
    logic                             PENABLE;
    logic [`REG_DATAWIDTH-1:0]        PWDATA;
    logic [`REG_DATAWIDTH-1:0]        PRDATA;
    logic                             PREADY;

    // DUT
    matrix_multiplication u_matmul(.*);
    
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
        PADDR = '0;
        PWRITE = 1'b0;
        PSEL = 1'b0;
        PENABLE = 1'b0;
        PWDATA = '0;
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

        // Switch to int8
        set_matrices_int8();
        display_inputs_int8();
        #115;
        $display("\nWriting to APB...");
        write(4'd8, 16'd0);  // is_fp8
        write(4'd0, 16'd1);  // Start

        // Wait for the done flag
        $display("\nListening for done signal...");
        wait_done(4'd7);     // Done
        write(4'd0, 16'd0);  // Start
        #100;         
        display_output_int8();

        $display("\nAll done!");
        $finish;
    end
    
    ////////////////////////////////////////////
    // Task to write into the configuration block of the DUT
    ////////////////////////////////////////////
    task write(input [`REG_ADDRWIDTH-1:0] addr, input [`REG_DATAWIDTH-1:0] data);
        @(negedge clk);
        PSEL = 1;
        PWRITE = 1;
        PADDR = addr;
        PWDATA = data;
        @(negedge clk);
        PENABLE = 1;
        @(negedge clk);
        PSEL = 0;
        PENABLE = 0;
        PWRITE = 0;
        PADDR = 0;
        PWDATA = 0;
        $display("%t: PADDR %h, PWDATA %h", $time, addr, data);
    endtask

    ////////////////////////////////////////////
    // Task to read from the configuration block of the DUT
    ////////////////////////////////////////////
    task read(input [`REG_ADDRWIDTH-1:0] addr, output [`REG_DATAWIDTH-1:0] data);
        @(negedge clk);
        PSEL = 1;
        PWRITE = 0;
        PADDR = addr;
        @(negedge clk);
        PENABLE = 1;
        @(negedge clk);
        PSEL = 0;
        PENABLE = 0;
        data = PRDATA;
        PADDR = 0;
        $display("%t: PADDR %h, PRDATA %h",$time, addr,data);
    endtask

    ////////////////////////////////////////////
    // Task to listen for the done signal
    ////////////////////////////////////////////
    task wait_done(input [`REG_ADDRWIDTH-1:0] addr);
        @(negedge clk);
        PSEL = 1;
        PWRITE = 0;
        PADDR = addr;
        @(negedge clk);
        PENABLE = 1;

        do begin
            @(negedge clk);
            status = PRDATA;
            $display("%t: PADDR %h, PRDATA %b",$time, addr, status);
        end while (status[0] == 1'b0);

        PSEL = 0;
        PENABLE = 0;
        PADDR = 0;
    endtask

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

    task automatic display_inputs_int8();
        $display("\nA =");
        for (int i = 0; i <= 24; i += 8) begin
            $write("|");
            for (int j = 0; j < 4; j++) begin
                    $write(" %d", u_matmul.matrix_A.ram[j][i+:8]);
            end
            $display(" |");
        end

        $display("\nB =");
        for (int i = 0; i < 4; i++) begin
            $write("|");
            for (int j = 0; j <= 24; j += 8) begin
                    $write(" %d", u_matmul.matrix_B.ram[i][j+:8]);
            end
            $display(" |");
        end
    endtask

    task automatic display_output_int8();
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
