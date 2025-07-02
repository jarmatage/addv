class instr_monitor extends uvm_monitor;
    `uvm_component_utils(instr_monitor)
    
    virtual imem_if vif;
    uvm_analysis_port #(instruction) instr_ap;
    logic [31:0] prev_pc;


    // Create a new instruction monitor object
    function new(string name = "instruction_monitor", uvm_component parent = null);
        super.new(name, parent);
        instr_ap = new("instr_ap", this);
    endfunction


    // Set the virtual interface
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual imem_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface must be set for instruction_monitor")
    endfunction


    // Main sampling process
    task run_phase(uvm_phase phase);
        instruction instr;
        forever begin
            @(posedge vif.clk);
            if (!vif.reset && prev_pc != vif.pc)
                send_instruction();
            prev_pc = vif.pc;
        end
    endtask


    // Send the current instruction to the analysis port
    task send_instruction();
        instruction instr;
        name = $sformatf("instr_%0d", vif.pc);
        instr = instruction::type_id::create(name);
        instr.disassemble(vif.instr);
        instr_ap.write(instr);
    endtask
endclass
