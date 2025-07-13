class fifo_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_monitor)

  // virtual interface comes from config-db
  virtual write_if #(8,4) w_vif;
  virtual read_if  #(8,4) r_vif;

  uvm_analysis_port #(fifo_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual write_if#(8,4))::get(this,"","w_vif", w_vif))
      `uvm_fatal("NOVIF","Write interface not set")
    if(!uvm_config_db#(virtual read_if#(8,4))::get(this,"","r_vif", r_vif))
      `uvm_fatal("NOVIF","Read interface not set")
  endfunction

  // coverage group inside the monitor
  covergroup fifo_cg;
    cp_depth  : coverpoint (w_vif.full  ? 16 :
                             r_vif.empty ? 0  :
                             8 ) { bins empty = {0};
                                   bins mid[] = {[1:15]};
                                   bins full  = {16}; }
    cp_flags  : coverpoint {w_vif.full,r_vif.empty};
    cross cp_depth, cp_flags;
  endgroup

  task run_phase(uvm_phase phase);
    fifo_seq_item txn;
    forever begin
      // --- write side ------------------------------------------------------
      @(posedge w_vif.clk);
      if (w_vif.en && !w_vif.full) begin
        txn = fifo_seq_item::type_id::create("txn");
        txn.is_write = 1;
        txn.data     = w_vif.data;
        txn.timestamp= $time;
        ap.write(txn);
      end

      // --- read side -------------------------------------------------------
      @(posedge r_vif.clk);
      if (r_vif.en && !r_vif.empty) begin
        txn = fifo_seq_item::type_id::create("txn");
        txn.is_write = 0;
        txn.data     = r_vif.data;
        txn.timestamp= $time;
        ap.write(txn);
      end
    end
  endtask
endclass 