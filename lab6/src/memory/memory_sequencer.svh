class memory_sequencer extends uvm_sequencer#(memory_seq_item);
    `uvm_component_utils(memory_sequencer)

    function new(string name = "memory_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass
