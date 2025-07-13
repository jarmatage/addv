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
    `uvm_info(get_type_name(), "Starting Fill For Loop", UVM_LOW)
    fill_for_loop();
    `uvm_info(get_type_name(), "Starting Alternating Read/Write", UVM_LOW)
    alternating_read_write();
    `uvm_info(get_type_name(), "Starting Random Sequential Bursts", UVM_LOW)
    random_sequential_burts();

    #100;
    `uvm_info(get_type_name(), "Starting Random Simultaneous Bursts", UVM_LOW)
    random_simultaneous_burts();
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

  task alternating_read_write();
    for (int i = 0; i < 512; i++) begin
      wr_seq = fifo_write_seq::type_id::create("wr_seq");
      rd_seq = fifo_read_seq::type_id::create("rd_seq");
      wr_seq.burst_len = 1;
      rd_seq.burst_len = 1;
      wr_seq.start(m_env.w_ag.m_seqr);
      rd_seq.start(m_env.r_ag.m_seqr);
    end
  endtask

  task random_sequential_burts();
    for (int i = 0; i < 512; i++) begin
      wr_seq = fifo_write_seq::type_id::create("wr_seq");
      rd_seq = fifo_read_seq::type_id::create("rd_seq");
      assert(wr_seq.randomize() with { burst_len < DEPTH; });
      rd_seq.burst_len = wr_seq.burst_len;
      wr_seq.start(m_env.w_ag.m_seqr);
      rd_seq.start(m_env.r_ag.m_seqr);
    end
  endtask

  task random_simultaneous_burts();
    fork
      random_writes();
      random_reads();
    join
  endtask

  task random_writes();
    int wcnt = 1024;
    while (wcnt > 0) begin
      wr_seq = fifo_write_seq::type_id::create("wr_seq");
      assert(wr_seq.randomize() with { burst_len <= wcnt; });
      wr_seq.start(m_env.w_ag.m_seqr);
      wcnt -= wr_seq.burst_len;
      #(`WCLK_T * 6);
    end
  endtask

  task random_reads();
    int rcnt = 1024;
    while (rcnt > 0) begin
      rd_seq = fifo_read_seq::type_id::create("rd_seq");
      assert(rd_seq.randomize() with { burst_len <= rcnt; });
      rd_seq.start(m_env.r_ag.m_seqr);
      rcnt -= rd_seq.burst_len;
      #(`RCLK_T * 6);
    end
  endtask

	function void end_of_elaboration_phase (uvm_phase phase);
		super.end_of_elaboration_phase(phase);

		// Print topology
		`uvm_info("TOPOLOGY", "Printing UVM topology...", UVM_LOW)
		uvm_top.print_topology();

		// Print env
		`uvm_info("PRINT_ENV", "Printing ENV...", UVM_LOW)
		m_env.print();
  endfunction
endclass
