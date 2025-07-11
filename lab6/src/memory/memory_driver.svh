class memory_driver extends uvm_driver#(memory_seq_item);
    `uvm_component_utils(memory_driver)

    virtual memory_if vif;
    mem_agent_mode_t mode;
    mem_array_t mem_model;
    memory_seq_item tr;

    // Constructor
    function new (string name = "memory_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual memory_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Failed to get virtual interface")
        if (!uvm_config_db#(mem_agent_mode_t)::get(this, "", "mode", mode))
            `uvm_fatal("NOMODE", "Failed to get agent mode")
        if (!uvm_config_db#(mem_array_t)::get(this, "", "mem_model", mem_model))
            `uvm_fatal("NOMEMMODEL", "Failed to get memory model")
    endfunction

    // Main run task
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        init_signals();
        wait_for_reset();
        get_and_drive();
    endtask

    task init_signals();
        if (mode == READ)
            vif.data = '0;
    endtask

    task wait_for_reset();
        wait(!vif.resetn);
    endtask

    task get_and_drive();
        forever begin
            wait(vif.en);
            #1;
            create_transfer();
            @(posedge vif.clk);
            send_transfer();
            #1;
        end
    endtask

    task create_transfer();
        tr = memory_seq_item::type_id::create("memory_seq_item");
        seq_item_port.get_next_item(tr);
        tr.addr <= vif.addr;
        tr.data <= (mode == WRITE) ? vif.data : mem_model[vif.addr];
        tr.mode <= mode;
    endtask

    task send_transfer();
        if (mode == WRITE) begin
            mem_model[vif.addr] <= tr.data;
            uvm_report_info("MEMORY WRITE", tr.convert2string());
        end else begin
            vif.data <= mem_model[vif.addr];
            uvm_report_info("MEMORY READ", tr.convert2string());
        end
        seq_item_port.item_done();
    endtask
endclass
