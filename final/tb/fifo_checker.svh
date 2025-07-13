class fifo_checker extends uvm_component;
  `uvm_component_utils(fifo_checker)

  virtual write_if #(8,4) w_vif;
  virtual read_if  #(8,4) r_vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual write_if#(8,4))::get(this,"","w_vif", w_vif))
      `uvm_fatal("NOVIF","Write VIF missing")
    if(!uvm_config_db#(virtual read_if#(8,4))::get(this,"","r_vif", r_vif))
      `uvm_fatal("NOVIF","Read VIF missing")
  endfunction

  // Module instance cannot be placed inside a class. The dpi_checker is expected
  // to be instantiated in the top-level testbench or via a bind directive.
endclass 