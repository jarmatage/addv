class memory_slave_agent extends uvm_agent;
    `uvm_component_utils(memory_slave_agent)

    virtual memory_if vif;
    mem_agent_mode_t mode;

    // Agent components
    memory_driver driver;
    memory_sequencer sequencer;

    // Constructor
    function new(string name = "memory_slave_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual memory_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Interface not set in config_db")
        if (!uvm_config_db#(mem_agent_mode_t)::get(this, "", "mode", mode))
            `uvm_fatal("NOMODE", "Mode not set in config_db")

        driver = memory_driver::type_id::create("memory_driver", this);
        sequencer = memory_sequencer::type_id::create("memory_sequencer", this);

        uvm_config_db#(virtual memory_if)::set(this, "driver", "vif", vif);
        uvm_config_db#(mem_agent_mode_t)::set(this, "driver", "mode", mode);
    endfunction

    // Connect phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass