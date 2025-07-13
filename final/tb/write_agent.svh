class write_driver extends uvm_driver #(fifo_seq_item);
  virtual write_if #(8,4) vif;
  `uvm_component_utils(write_driver)

  function new(string n, uvm_component p); super.new(n,p); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual write_if#(8,4))::get(this,"","vif",vif))
      `uvm_fatal("NOVIF","write_if not set")
  endfunction

  task run_phase(uvm_phase phase);
    fifo_seq_item item;
    forever begin
      seq_item_port.get_next_item(item);
      @(negedge vif.clk);
      vif.en   <= 1;
      vif.data <= item.data;
      @(posedge vif.clk);
      vif.en   <= 0;
      seq_item_port.item_done();
    end
  endtask
endclass

class write_agent extends uvm_agent;
  `uvm_component_utils(write_agent)

  write_driver     m_drv;
  uvm_sequencer #(fifo_seq_item) m_seqr;

  function new(string n, uvm_component p); super.new(n,p); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_drv  = write_driver::type_id::create("m_drv", this);
    m_seqr = uvm_sequencer#(fifo_seq_item)::type_id::create("m_seqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    m_drv.seq_item_port.connect(m_seqr.seq_item_export);
  endfunction
endclass 