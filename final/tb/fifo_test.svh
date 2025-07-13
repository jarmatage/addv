class fifo_test extends uvm_test;
  `uvm_component_utils(fifo_test)

  const static int DEPTH = (1 << `AWIDTH);

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
    phase.raise_objection(this);
    fill_for_loop();
    //alternating_read_write();
    //random_sequential_burts();
    //random_simultaneous_burts();
    phase.drop_objection(this);
  endtask

  task fill_for_loop();
    for (int i = 0; i < DEPTH; i++) begin
      wr_seq = fifo_write_seq::type_id::create("wr_seq");
      rd_seq = fifo_read_seq::type_id::create("rd_seq");
      wr_seq.burst_len = i;
      rd_seq.burst_len = i;
      wr_seq.start(m_env.w_ag.m_seqr);
      rd_seq.start(m_env.r_ag.m_seqr);
    end
  endtask

endclass
