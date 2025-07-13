class fifo_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_monitor)

  fifo_seq_item txn; // transaction item

  // virtual interface comes from config-db
  virtual write_if #(8,4) w_vif;
  virtual read_if  #(8,4) r_vif;

  uvm_analysis_port #(fifo_seq_item) ap;

  covergroup address_cg;
    cp_waddr: coverpoint w_vif.addr {
      bins waddr_vals[] = {[0:15]};
    }
    cp_raddr: coverpoint r_vif.addr {
      bins raddr_vals[] = {[0:15]};
    }
    //cross cp_waddr, cp_raddr;
  endgroup

  covergroup pointer_cg;
    cp_wptr: coverpoint w_vif.ptr {
      bins wptr_vals[] = {[0:15]};
    }
    cp_rptr: coverpoint r_vif.ptr {
      bins rptr_vals[] = {[0:15]};
    }
    //cross cp_wptr, cp_rptr;
  endgroup

  covergroup flags_cg;
    cp_full: coverpoint w_vif.full {
      bins full_vals[] = {0, 1};
    }
    cp_almost_full: coverpoint w_vif.almost_full {
      bins almost_full_vals[] = {0, 1};
    }
    cp_waddr: coverpoint w_vif.addr {
      bins wad_vals[] = {[0:15]};
    }
    cross cp_full, cp_almost_full, cp_waddr iff (!(w_vif.full == 1 && w_vifalmost_full == 0));

    cp_empty: coverpoint r_vif.empty {
      bins empty_vals[] = {0, 1};
    }
    cp_almost_empty: coverpoint r_vif.almost_empty {
      bins almost_empty_vals[] = {0, 1};
    }
    cp_raddr: coverpoint r_vif.addr {
      bins rad_vals[] = {[0:15]};
    }
    cross cp_empty, cp_almost_empty, cp_raddr iff (!(r_vif.empty == 1 && r_vif.almost_empty == 0));
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
    address_cg = new();
    pointer_cg = new();
    flags_cg = new();
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual write_if#(8,4))::get(this,"","w_vif", w_vif))
      `uvm_fatal("NOVIF","Write interface not set")
    if(!uvm_config_db#(virtual read_if#(8,4))::get(this,"","r_vif", r_vif))
      `uvm_fatal("NOVIF","Read interface not set")
  endfunction

  task run();
    fork
      monitor_write();
      monitor_read();
    join
  endtask

  task monitor_write();
    forever begin
      @(posedge w_vif.clk);
      if (!w_vif.full && w_vif.en) begin
        txn = fifo_seq_item::type_id::create("write_item");
        txn.is_write = 1'b1;
        txn.data = w_vif.data;
        ap.write(txn);
      end
      address_cg.sample();
      pointer_cg.sample();
      flags_cg.sample();
    end
  endtask


  task monitor_read();
    forever begin
      @(posedge r_vif.clk);
      if (!r_vif.empty && r_vif.en) begin
        txn = fifo_seq_item::type_id::create("read_item");
        txn.is_write = 1'b0;
        txn.data = r_vif.data;
        ap.write(txn);
      end
      address_cg.sample();
      pointer_cg.sample();
      flags_cg.sample();
    end
  endtask
endclass
