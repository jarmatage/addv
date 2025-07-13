module tb_async_fifo_uvm;
  // Set the timescale
  timeunit 1ns;
  timeprecision 100ps;

  // Import packages
  import uvm_pkg::*;
  import fifo_uvm_pkg::*;

  // parameters identical to RTL
  localparam DATA_WIDTH = 8;
  localparam ADDR_WIDTH = 4;
  localparam int DATA_DEPTH = 1 << ADDR_WIDTH;

  // clock + reset
  logic wclk = 0, rclk = 0, rst_n = 0;

  // programmable ratio from +WR_PER_RD
  int WR_PER_RD;
  time rd_delay;
  initial begin
    if(!$value$plusargs("WR_PER_RD=%d", WR_PER_RD)) WR_PER_RD = 1;
    rd_delay = WR_PER_RD * 5; // timescale 1ns ⇒ 5 ns base
  end
  always #5  wclk = ~wclk;                 // base 100 MHz
  always #(rd_delay) rclk = ~rclk;         // variable read clock

  // interfaces
  write_if #(DATA_WIDTH,ADDR_WIDTH) w_if (.clk(wclk), .rst_n(rst_n));
  read_if  #(DATA_WIDTH,ADDR_WIDTH) r_if (.clk(rclk), .rst_n(rst_n));

  // DUT
  async_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH))
             dut ( .write(w_if), .read(r_if) );

  // reset sequence (no run command!)
  initial begin
    rst_n = 0; repeat(4) @(posedge wclk); rst_n = 1;
  end

  // push interfaces into UVM config-db
  initial begin
    uvm_config_db#(virtual write_if)::set(null,"*","w_vif", w_if);
    uvm_config_db#(virtual read_if)::set(null,"*","r_vif", r_if);
  end

  // kick UVM (default to fifo_base_test if +UVM_TESTNAME not supplied)
  initial run_test("fifo_base_test");
endmodule 