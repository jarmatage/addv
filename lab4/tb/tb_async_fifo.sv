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
    logic [7:0] wcnt, rcnt;

    // Create DUT interfaces
    write_if #(DATA_WIDTH) write (wclk);
    read_if #(DATA_WIDTH) read (rclk);

    // Instantiate the DUT (data width = 8, address width = 4)
    async_fifo #(DATA_WIDTH, ADDR_WIDTH) dut(write.DUT, read.DUT, rst_n);

    // Generate both read and write clocks
    initial wclk = 0;
    always #5 wclk = ~wclk; // 10ns period = 100MHz
    initial rclk = 0;
    always #8 rclk = ~rclk; // 16ns period = 62.5MHz

    // Create testbench components
    mailbox #(transaction) txn_mail;
    monitor mon;
    scoreboard sb;

    initial begin
        mon = new(write, read);
        sb = new();
        txn_mail = new();
        mon.txn_mail = txn_mail;
        sb.txn_mail = txn_mail;
        fork
            mon.run();
            sb.run();
        join
    end

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
        write.en = 0;
        read.en = 0;
        write.data = 0;
        wcnt = 0;
        rcnt = 0;
        #40; // wait 5 read clock cycles then deassert the reset
        rst_n = 1;
        #40;
    endtask

    // Push data into FIFO
    task automatic push();
        @(negedge wclk);
        write.data = wcnt + 8'd1; // Each slot holds the value of its place in the queue
        $display("Pushing data: %0d", write.data);
        write.en = 1'b1;
        if (!write.full) wcnt = wcnt + 8'd1;
        @(posedge wclk);
        write.en = 1'b0;
    endtask

    // Pop data from the FIFO
    task automatic pop();
        @(negedge rclk);
        read.en = 1'b1;
        if (!read.empty) rcnt = rcnt + 8'd1;
        @(posedge rclk);
        #2;
        read.en = 1'b0;
    endtask

    // Check the FIFO's initial reset state
    task automatic check_reset();
        if (!read.empty) begin
            $error("ERROR: FIFO not empty after reset at time %t", $time);
            $finish;
        end
        if (!read.almost_empty) begin
            $error("ERROR: FIFO not almost empty after reset at time %t", $time);
            $finish;
        end
        if (write.full) begin
            $error("ERROR: FIFO should not be full after reset at time %t", $time);
            $finish;
        end
        if (write.almost_full) begin
            $error("ERROR: FIFO should not be almost_full after reset at time %t", $time);
            $finish;
        end
    endtask

    // Write to the FIFO until it is full
    task automatic fill_fifo();
        $display("\n--- Filling the FIFO ---\n");
        repeat (DATA_DEPTH) push();
        push(); // Perform one extra write attempt to test interface assertions
    endtask

    // Read from the FIFO until it is empty
    task automatic empty_fifo();
        $display("\n--- Emptying the FIFO ---\n");
        repeat (DATA_DEPTH) pop();
        pop(); // Perform one extra read attempt to test interface assertions
    endtask

    // Simultaneously read and write from the FIFO
    task automatic simultaneous_rw();
        $display("\n--- Performing Simultaneous Read and Write Operations ---\n");
        fork
            // Writer
            begin
                repeat (25) push();
            end

            // Reader
            begin
                @(posedge wclk); // Give the Writer a head start
                repeat (25) pop();
            end
        join

        // FIFO should be empty again
        #20;
        if (!read.empty) begin
            $error("ERROR: FIFO not empty after read/writes at time %t", $time);
            $finish;
        end
    endtask

endmodule
