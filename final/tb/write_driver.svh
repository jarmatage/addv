class write_driver extends uvm_driver #(fifo_seq_item);
  virtual write_if #(8,4) vif;
  `uvm_component_utils(write_driver)

  fifo_seq_item item;

  function new(string n, uvm_component p); super.new(n,p); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual write_if#(8,4))::get(this,"","vif",vif))
      `uvm_fatal("NOVIF","write_if not set")
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    init_signals();
    wait_for_reset();
    
    item = fifo_seq_item::type_id::create("write_item");
    forever begin
      @(negedge vif.clk);
      if (!vif.full) begin
        seq_item_port.get_next_item(item);
        vif.data = item.data;
        vif.en   = 1;
        @(posedge vif.clk);
        #2;
        vif.en   <= 0;
        `uvm_info("WRITE_DRIVER", $sformatf("data=%0d, addr=%0d, full=%b, almost_full=%b", item.data, vif.addr, vif.full, vif.almost_full), UVM_HIGH)
        seq_item_port.item_done();
      end
    end
  endtask

  task init_signals();
    vif.en = 0;
    vif.data = '0;
  endtask

  task wait_for_reset();
    wait(!vif.rst_n); // Wait for reset to be asserted
    wait(vif.rst_n);  // Wait for reset to be released
  endtask
endclass
