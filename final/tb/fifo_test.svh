class fifo_test extends uvm_test;
  `uvm_component_utils(fifo_test)

  fifo_env m_env;
  fifo_write_seq wr_seq;
  fifo_read_seq rd_seq;

  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_env = fifo_env::type_id::create("m_env", this);
  endfunction

  task run_phase(uvm_phase phase);
    wr_seq = fifo_write_seq::type_id::create("wr_seq");
    rd_seq = fifo_read_seq::type_id::create("rd_seq");
    phase.raise_objection(this);
    fill_for_loop();
    alternating_read_write();
    random_sequential_burts();
    random_simultaneous_burts();
    wr_seq.start(m_env.w_ag.m_seqr); // start random writes
    phase.drop_objection(this);
  endtask
endclass
