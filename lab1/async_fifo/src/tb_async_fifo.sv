`timescale 1ns/1ps

module tb_async_fifo;

    // Setup FIFO parameters
    localparam int DATA_WIDTH = 8;
    localparam int ADDR_WIDTH = 4;
    localparam int DATA_DEPTH = 1 << ADDR_WIDTH;

    // Create write side signals
    logic                  wclk;
    logic                  wen;
    logic [DATA_WIDTH-1:0] wdata;
    logic                  full;
    logic                  almost_full;

    // Create read side signals
    logic                  rclk;
    logic                  ren;
    logic [DATA_WIDTH-1:0] rdata;
    logic                  empty;
    logic                  almost_empty;

    // Global reset (active low)
    logic rst_n;

    // Counts for tracking the number of pushes and pops
    logic [7:0] rcnt;
    logic [7:0] wcnt;

    // Instantiate the DUT (data width = 8, address width = 4)
    async_fifo #(DATA_WIDTH, ADDR_WIDTH) dut(.*);

    // Generate both read and write clocks
    initial wclk = 0;
    always #5 wclk = ~wclk; // 10ns period = 100MHz
    initial rclk = 0;
    always #8 rclk = ~rclk; // 16ns period = 62.5MHz

    // Reset the DUT
    initial begin
        rst_n = 0;
        wen   = 0;
        ren   = 0;
        wdata = 0;
        #40; // wait 5 read clock cycles then deassert the reset
        rst_n = 1;
        #40;
    end

    // Main test sequence
    initial begin
        check_reset();
        fill_fifo();
        empty_fifo();
        simultaneous_rw();
        #40;
        $fsdbDumpvars(); // Create a waveform FSDB for Verdi
        $finish;
    end

    // Push data into FIFO
    task automatic push();
        wdata <= wcnt + 8'd1; // Each slot holds the value of its place in the queue
        wen <= 1'b1;
        if (!full) wcnt <= wcnt + 8'd1;
        @(posedge wclk);
        wen <= 1'b0;
    endtask

    // Pop data from the FIFO
    task automatic pop(output logic [DATA_WIDTH-1:0] data);
        ren <= 1'b1;
        if (!empty) rcnt <= rcnt + 8'd1;
        @(posedge rclk);
        ren <= 1'b0;
        data = rdata;
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
    endtask

    // Write to the FIFO until it is full
    task automatic fill_fifo();
        $display("\n--- Filling the FIFO ---\n")

        repeat (DATA_DEPTH) begin
            push();

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

            // Display each iteration
            $display("write %0d: full=%0b, almost_full=%0b", wcnt, full, almost_full)
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
        $display("\n--- Emptying the FIFO ---\n")

        repeat (DATA_DEPTH) begin
            pop();

            // Check that the empty flag is correct
            if (rcnt == DATA_DEPTH && !empty) begin
                $display("ERROR: empty flag did not assert at rcnt=%0d and time=%t", rcnt, $time);
                $finish;
            end

            // Check that the almost empty flag is correct
            if (rcnt >= (DEPTH * 3/4) && !almost_empty) begin
                $display("ERROR: almost_empty flag did not assert at rcnt=%0d and time=%t", rcnt, $time);
                $finish;
            end
        end

        // Reset the counts now that the FIFO is empty
        wcnt = 0;
        rcnt = 0;
    endtask

    // Simultaneously read and write from the FIFO
    task automatic simultaneous_rw();
        $display("\n--- Performing Simultaneous Read and Write Operations ---\n");

        fork
            begin : Writer
                repeat (2*DATA_DEPTH) push();
            end
            begin : Reader
                repeat (2) @(posedge wclk); // Give the Writer a head start
                repeat (2*DATA_DEPTH) pop();
            end
        join_any
        disable Writer;
        disable Reader;

        // FIFO should be empty again
        #20;
        if (!empty) begin
            $display("ERROR: FIFO not empty after read/writes at time %t", $time);
            $finish;
        end
    endtask

endmodule
