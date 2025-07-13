package fifo_uvm_pkg;
  `include "uvm_macros.svh"
  import uvm_pkg::*;

  // *include every class file once so a single `import fifo_uvm_pkg::*;`
  `include "fifo_seq_item.svh"
  `include "fifo_monitor.svh"
  `include "fifo_scoreboard.svh"
  `include "fifo_checker.svh"
  `include "write_driver.svh"
  `include "write_agent.svh"
  `include "read_driver.svh"
  `include "read_agent.svh"
  `include "fifo_env.svh"
  `include "fifo_read_seq.svh"
  `include "fifo_write_seq.svh"
  `include "fifo_test.svh"
endpackage : fifo_uvm_pkg 