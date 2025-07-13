class read_agent extends uvm_agent;
  `uvm_component_utils(read_agent)

  read_driver      m_drv;
  uvm_sequencer #(fifo_seq_item) m_seqr;

  function new(string n, uvm_component p); super.new(n,p); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_drv  = read_driver::type_id::create("m_drv", this);
    m_seqr = uvm_sequencer#(fifo_seq_item)::type_id::create("m_seqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    m_drv.seq_item_port.connect(m_seqr.seq_item_export);
  endfunction
endclass 