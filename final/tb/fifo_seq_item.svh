class fifo_seq_item extends uvm_sequence_item;
  rand bit         is_write;
  rand byte        data;
  // sampled flags (read domain view)
  bit empty, almost_empty, full, almost_full;
  time timestamp;

  `uvm_object_utils_begin(fifo_seq_item)
    `uvm_field_int(is_write , UVM_DEFAULT)
    `uvm_field_int(data     , UVM_DEFAULT | UVM_BIN)
  `uvm_object_utils_end

  function new(string name="fifo_seq_item");
    super.new(name);
  endfunction
endclass 