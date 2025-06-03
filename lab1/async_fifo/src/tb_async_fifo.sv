//------------------------------------------------------------------------------
// tb_async_fifo.sv
// SystemVerilog testbench for async_fifo.sv + helpers.
// Verifies:
//   1) Empty → fill (¾ → full) → drain (¼ → empty)
//   2) almost_full / almost_empty flags
//   3) Concurrent write/read under async clocks
//------------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_async_fifo;

  // ------------------------------------------------------------------------
  // 1) Parameters (match the FIFO)
  // ------------------------------------------------------------------------
  localparam int DATA_WIDTH  = 8;
  localparam int ADDR_WIDTH  = 8;           // 2^8 = 256 entries
  localparam int DEPTH       = (1 << ADDR_WIDTH);
  localparam int PTR_WIDTH   = ADDR_WIDTH + 1;

  // ------------------------------------------------------------------------
  // 2) Testbench Signals
  // ------------------------------------------------------------------------
  // Write side (push)
  logic                     write_clk;
  logic                     write_en;
  logic [DATA_WIDTH-1:0]    write_data;
  logic                     full;
  logic                     almost_full;

  // Read side (pop)
  logic                     read_clk;
  logic                     read_en;
  logic [DATA_WIDTH-1:0]    read_data;
  logic                     empty;
  logic                     almost_empty;

  // Global reset (active low)
  logic                     rst_n;

  // Local counters (for data patterns & checking)
  integer                   write_counter = 0;
  integer                   read_counter  = 0;

  // ------------------------------------------------------------------------
  // 3) Instantiate the DUT
  // ------------------------------------------------------------------------
  async_fifo #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
  ) dut (
    .wclk         (write_clk),
    .wen          (write_en),
    .wdata        (write_data),
    .full         (full),
    .almost_full  (almost_full),

    .rclk         (read_clk),
    .ren          (read_en),
    .rdata        (read_data),
    .empty        (empty),
    .almost_empty (almost_empty),

    .rst_n        (rst_n)
  );

  // ------------------------------------------------------------------------
  // 4) Clock Generation
  //    - write_clk: 100 MHz (10 ns period)
  //    - read_clk :  62.5 MHz (16 ns period)
  // ------------------------------------------------------------------------
  initial begin
    write_clk = 0;
    forever #5 write_clk = ~write_clk;
  end

  initial begin
    read_clk = 0;
    forever #8 read_clk = ~read_clk;
  end

  // ------------------------------------------------------------------------
  // 5) Reset Sequence
  // ------------------------------------------------------------------------
  initial begin
    rst_n = 0;
    write_en = 0;
    read_en  = 0;
    write_data = '0;
    write_counter = 0;
    read_counter  = 0;

    // Hold reset low for 2 write-clock edges
    repeat (2) @(posedge write_clk);
    rst_n = 1;  // deassert

    // Hold reset low for 2 read-clock edges (still the same rst_n)
    repeat (2) @(posedge read_clk);
    rst_n = 1;  // remains deasserted
  end

  // ------------------------------------------------------------------------
  // 6) Wave Dump (FSDB for Verdi)
  // ------------------------------------------------------------------------
  initial begin
    $fsdbDumpfile("fifo_tb.fsdb");
    $fsdbDumpvars(0, tb_async_fifo);
  end

  // ------------------------------------------------------------------------
  // 7) Task: write one element if not full (otherwise pulse to show ignore)
  // ------------------------------------------------------------------------
  task automatic do_write();
    begin
      if (!full) begin
        write_data = write_counter[DATA_WIDTH-1:0];
        write_en   = 1;
        @(posedge write_clk);
        write_en   = 0;
        write_counter++;
      end
      else begin
        // FIFO is full → pulse write_en anyway
        write_en = 1;
        @(posedge write_clk);
        write_en = 0;
        // Do not increment write_counter, since full blocked write
      end
    end
  endtask

  // ------------------------------------------------------------------------
  // 8) Task: read one element if not empty (otherwise pulse to show ignore)
  // ------------------------------------------------------------------------
  task automatic do_read();
    begin
      if (!empty) begin
        read_en = 1;
        @(posedge read_clk);
        read_en = 0;
        #1;  // wait for read_data to settle
        if (read_data !== read_counter[DATA_WIDTH-1:0]) begin
          $display("ERROR at time %0t: expected read_data=%0d, got %0d",
                   $time, read_counter, read_data);
          $finish;
        end
        read_counter++;
      end
      else begin
        // FIFO is empty → pulse read_en anyway
        read_en = 1;
        @(posedge read_clk);
        read_en = 0;
      end
    end
  endtask

  // ------------------------------------------------------------------------
  // 9) Main Stimulus: Scenario 1 & 2
  // ------------------------------------------------------------------------
  initial begin
    // Wait for reset deassertion (two domains)
    @(negedge rst_n);
    @(negedge rst_n);
    #1;

    // --- Check initial reset state ---
    if (!empty) begin
      $display("ERROR: FIFO not empty after reset at time %t", $time);
      $finish;
    end
    if (!almost_empty) begin
      $display("ERROR: almost_empty not asserted after reset at time %t", $time);
      $finish;
    end
    if (full) begin
      $display("ERROR: full should be 0 after reset at time %t", $time);
      $finish;
    end

    $display("\n>>> SCENARIO 1: EMPTY → FILL → FULL → DRAIN → EMPTY <<<\n");

    // 1a) Fill FIFO (DEPTH writes)
    repeat (DEPTH) begin
      @(posedge write_clk);
      do_write();

      // Check almost_full once >= 3/4 occupancy
      if (write_counter >= (3*DEPTH)/4) begin
        if (!almost_full) begin
          $display("ERROR: almost_full missing at write_count=%0d time=%t",
                   write_counter, $time);
          $finish;
        end
      end

      // Check full exactly at write_count == DEPTH
      if (write_counter == DEPTH) begin
        if (!full) begin
          $display("ERROR: full missing at write_count=%0d time=%t",
                   DEPTH, $time);
          $finish;
        end
      end
    end

    // 1b) One extra write attempt (should be ignored)
    @(posedge write_clk);
    do_write();
    if (write_counter != DEPTH) begin
      $display("ERROR: FIFO accepted write when full at time %t", $time);
      $finish;
    end

    // 1c) Drain FIFO (DEPTH reads)
    repeat (DEPTH) begin
      @(posedge read_clk);
      do_read();

      // Check almost_empty once occupancy ≤ 1/4
      if ((DEPTH - read_counter) <= (DEPTH/4)) begin
        if (!almost_empty) begin
          $display("ERROR: almost_empty missing at read_count=%0d time=%t",
                   read_counter, $time);
          $finish;
        end
      end

      // Check empty exactly at read_count == DEPTH
      if (read_counter == DEPTH) begin
        if (!empty) begin
          $display("ERROR: empty missing at read_count=%0d time=%t",
                   read_counter, $time);
          $finish;
        end
      end
    end

    $display("SCENARIO 1 PASSED (Empty→Full→Empty). \n");

    // Reset local counters for Scenario 2
    write_counter = 0;
    read_counter  = 0;

    $display(">>> SCENARIO 2: CONCURRENT WRITE/READ (ASYNC CLOCKS) <<<\n");

    // 2a) Fork two processes: writer vs reader
    fork
      begin : WRITER
        repeat (2*DEPTH) begin
          @(posedge write_clk);
          do_write();
        end
      end

      begin : READER
        // Give FIFO a head start (2 write cycles)
        repeat (2) @(posedge write_clk);
        repeat (2*DEPTH) begin
          @(posedge read_clk);
          do_read();
        end
      end
    join_any
    disable WRITER;
    disable READER;

    // At this point, FIFO should be empty again
    if (!empty) begin
      $display("ERROR: FIFO not empty after concurrent R/W at time %t", $time);
      $finish;
    end

    $display("SCENARIO 2 PASSED (Concurrent read/write). \n");
    #20;
    $display("ALL TESTS PASSED. Simulation completes at time %t\n", $time);
    $finish;
  end

  // ------------------------------------------------------------------------
  // 10) (Optional) Assertions for flag conflicts (full & almost_full, empty & almost_empty)
  // ------------------------------------------------------------------------
  //   property no_full_conflict;
  //     @(posedge write_clk) disable iff (!rst_n)
  //       !(full && almost_full);
  //   endproperty
  //   assert property (no_full_conflict)
  //     else $error("Conflict: full && almost_full at time %0t", $time);
  //
  //   property no_empty_conflict;
  //     @(posedge read_clk) disable iff (!rst_n)
  //       !(empty && almost_empty);
  //   endproperty
  //   assert property (no_empty_conflict)
  //     else $error("Conflict: empty && almost_empty at time %0t", $time);

endmodule
