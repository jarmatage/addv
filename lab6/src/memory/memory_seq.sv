class memory_seq extends uvm_sequence#(memory_seq_item);
    `uvm_object_utils(memory_seq)

    memory_seq_item tr;

    function new(string name = "memory_seq");
        super.new(name);
    endfunction


    virtual task body();
        forever begin
            tr = memory_seq_item::type_id::create("memory_seq_item");
            start_item(tr);
            finish_item(tr);
        end
    endtask
endclass
