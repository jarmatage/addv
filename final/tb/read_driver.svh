class read_driver extends uvm_driver #(fifo_seq_item);
  virtual read_if #(8,4) vif;
  `uvm_component_utils(read_driver)

  function new(string n, uvm_component p); super.new(n,p); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual read_if#(8,4))::get(this,"","vif",vif))
      `uvm_fatal("NOVIF","read_if not set")
  endfunction

  task run_phase(uvm_phase phase);
    fifo_seq_item item;
    forever begin
      @(negedge vif.clk);
      seq_item_port.get_next_item(item);
      vif.en <= 1;
      wait(!vif.empty); // Wait for FIFO to not be empty
      #1;
      @(posedge vif.clk);
      vif.en <= 0;
      item.data = vif.data;
      `uvm_info("READ_DRIVER", $sformatf("data=%0d, addr=%0d, empty=%b, almost_empty=%b", item.data, vif.addr, vif.empty, vif.almost_empty), UVM_HIGH)
      seq_item_port.item_done();
    end
  endtask
endclass
