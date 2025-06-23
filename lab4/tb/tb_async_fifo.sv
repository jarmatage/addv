module tb_async_fifo;
    // Set the timescale
    timeunit 1ns;
    timeprecision 100ps;

    // Setup FIFO parameters
    localparam int DATA_WIDTH = 8;
    localparam int ADDR_WIDTH = 4;
    localparam int DATA_DEPTH = 1 << ADDR_WIDTH;

    // Clock and reset signals
    logic wclk, rclk, rst_n;

    // Counts for tracking the number of pushes and pops
    logic [7:0] rcnt;
    logic [7:0] wcnt;

    // Create DUT interfaces
    write_if write #(DATA_WIDTH) (wclk);
    read_if  read  #(DATA_WIDTH) (rclk);

    // Instantiate the DUT (data width = 8, address width = 4)
    async_fifo #(DATA_WIDTH, ADDR_WIDTH) dut(write.DUT, read.DUT, rst_n);

    // Generate both read and write clocks
    initial wclk = 0;
    always #5 wclk = ~wclk; // 10ns period = 100MHz
    initial rclk = 0;
    always #8 rclk = ~rclk; // 16ns period = 62.5MHz

    // Main test sequence
    initial begin
        `ifdef DUMP
            $display("Dumping to FSDB");
            $fsdbDumpvars();
        `endif
        reset();
        check_reset();
        fill_fifo();
        empty_fifo();
        reset();
        check_reset();
        simultaneous_rw();
        #40;
        $finish;
    end

    // Reset the DUT
    task automatic reset();
        rst_n = 0;
        wen   = 0;
        ren   = 0;
        wdata = 0;
        wcnt  = 0;
        rcnt  = 0;
        #40; // wait 5 read clock cycles then deassert the reset
        rst_n = 1;
        #40;
    endtask

    // Push data into FIFO
    task automatic push();
        wdata <= wcnt + 8'd1; // Each slot holds the value of its place in the queue
        wen <= 1'b1;
        if (!full) wcnt <= wcnt + 8'd1;
        @(posedge wclk);
        #2;
        wen <= 1'b0;
    endtask

    // Pop data from the FIFO
    task automatic pop();
        ren <= 1'b1;
        if (!empty) rcnt <= rcnt + 8'd1;
        @(posedge rclk);
        #2;
        ren <= 1'b0;
    endtask

    // Check the FIFO's initial reset state
    task automatic check_reset();
        if (!empty) begin
            $display("ERROR: FIFO not empty after reset at time %t", $time);
            $finish;
        end
        if (!almost_empty) begin
            $display("ERROR: FIFO not almost empty after reset at time %t", $time);
            $finish;
        end
        if (full) begin
            $display("ERROR: FIFO should not be full after reset at time %t", $time);
            $finish;
        end
        if (almost_full) begin
            $display("ERROR: FIFO should not be almost_full after reset at time %t", $time);
            $finish;
        end
    endtask

    // Write to the FIFO until it is full
    task automatic fill_fifo();
        $display("\n--- Filling the FIFO ---\n");

        repeat (DATA_DEPTH) begin
            push();

            // Display each iteration
            $display("write %0d: full=%0b, almost_full=%0b, rdata=%0d", wcnt, full, almost_full, rdata);

            // Check that the full flag is correct
            if (wcnt != DATA_DEPTH && full) begin
                $display("ERROR: full flag was asserted at wcnt=%0d and time=%t", wcnt, $time);
                $finish;
            end
            if (wcnt == DATA_DEPTH && !full) begin
                $display("ERROR: full flag did not assert at wcnt=%0d and time=%t", wcnt, $time);
                $finish;
            end

            // Check that the almost full flag is correct
            if (wcnt < (DATA_DEPTH * 3/4) && almost_full) begin
                $display("ERROR: almost_full flag was asserted at wcnt=%0d and time=%t", wcnt, $time);
                $finish;
            end
            if (wcnt >= (DATA_DEPTH * 3/4) && !almost_full) begin
                $display("ERROR: almost_full flag did not assert at wcnt=%0d and time=%t", wcnt, $time);
                $finish;
            end
        end

        // Perform one extra write attempt
        push();
        if (wcnt != DATA_DEPTH) begin
            $display("ERROR: FIFO accepted write when full at time %t", $time);
            $finish;
        end
    endtask

    // Read from the FIFO until it is empty
    task automatic empty_fifo();
        $display("\n--- Emptying the FIFO ---\n");

        repeat (DATA_DEPTH) begin
            pop();

            // Display each iteration
            $display("read %0d: empty=%0b, almost_empty=%0b, rdata=%0d", rcnt, empty, almost_empty, rdata);

            // Check that the empty flag is correct
            if (rcnt != DATA_DEPTH && empty) begin
                $display("ERROR: empty flag was asserted at rcnt=%0d and time=%t", rcnt, $time);
                $finish;
            end
            if (rcnt == DATA_DEPTH && !empty) begin
                $display("ERROR: empty flag did not assert at rcnt=%0d and time=%t", rcnt, $time);
                $finish;
            end            

            // Check that the almost empty flag is correct
            if (rcnt < (DATA_DEPTH * 3/4) && almost_empty) begin
                $display("ERROR: almost_empty flag was asserted at rcnt=%0d and time=%t", rcnt, $time);
                $finish;
            end
            if (rcnt >= (DATA_DEPTH * 3/4) && !almost_empty) begin
                $display("ERROR: almost_empty flag did not assert at rcnt=%0d and time=%t", rcnt, $time);
                $finish;
            end
        end
    endtask

    // Simultaneously read and write from the FIFO
    task automatic simultaneous_rw();
        $display("\n--- Performing Simultaneous Read and Write Operations ---\n");

        fork
            // Writer
            begin
                repeat (2*DATA_DEPTH) push();
            end

            // Reader
            begin
                repeat (2) @(posedge wclk); // Give the Writer a head start
                repeat (2*DATA_DEPTH) begin
                    pop();
                    $display("rdata = %d", rdata);
                end
            end
        join

        // FIFO should be empty again
        #20;
        if (!empty) begin
            $display("ERROR: FIFO not empty after read/writes at time %t", $time);
            $finish;
        end
    endtask

endmodule
