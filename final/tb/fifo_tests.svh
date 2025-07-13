class fifo_base_test extends uvm_test;
  `uvm_component_utils(fifo_base_test)

  fifo_env m_env;

  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = fifo_env::type_id::create("m_env", this);
  endfunction

  task run_phase(uvm_phase phase);
    fifo_write_seq wr_seq = fifo_write_seq::type_id::create("wr_seq");
    phase.raise_objection(this);

    assert(wr_seq.randomize());

    wr_seq.start(m_env.w_ag.m_seqr); // start random writes
    phase.drop_objection(this);
  endtask
endclass

// Override to sweep clock ratios
class fifo_corner_test extends fifo_base_test;
  `uvm_component_utils(fifo_corner_test)
  int wr_per_rd = 2; // default 2:1

  function new(string name="fifo_corner_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'($value$plusargs("WR_PER_RD=%0d", wr_per_rd));
    uvm_config_db#(int)::set(this,"","WR_PER_RD",wr_per_rd);
  endfunction
endclass 