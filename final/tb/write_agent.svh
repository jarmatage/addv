class write_agent extends uvm_agent;
  `uvm_component_utils(write_agent)

  write_driver     m_drv;
  uvm_sequencer #(fifo_seq_item) m_seqr;

  virtual write_if vif;

  function new(string n, uvm_component p); super.new(n,p); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_drv  = write_driver::type_id::create("m_drv", this);
    m_seqr = uvm_sequencer#(fifo_seq_item)::type_id::create("m_seqr", this);

    // Get the virtual interface from the configuration database
    if(!uvm_config_db#(virtual write_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "No virtual interface specified for write agent")
    end

    // Pass the virtual interface to the driver
    uvm_config_db#(virtual write_if)::set(this, "m_drv", "vif", vif);
  endfunction

  function void connect_phase(uvm_phase phase);
    m_drv.seq_item_port.connect(m_seqr.seq_item_export);
  endfunction
endclass 