class instr_monitor extends uvm_monitor;
    `uvm_component_utils(instr_monitor)
    
    virtual imem_if vif;
    uvm_analysis_port #(instruction) instr_ap;
    logic [31:0] prev_pc;


    // Create a new instruction monitor object
    function new(string name = "instruction_monitor", uvm_component parent = null);
        super.new(name, parent);
        $display("Creating instruction monitor");
        instr_ap = new("instr_ap", this);
    endfunction


    // Set the virtual interface
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual imem_if)::get(null, "", "vif", vif))
            `uvm_fatal("NOVIF", "virtual interface not set in config_db")
    endfunction


    // Main sampling process
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        $display("Starting instruction monitor run phase");
        forever begin
            $display("[%0t] Waiting for clock edge", $time);
            @(posedge vif.clk);
            $display("[%0t] Got clock edge", $time);
            if (!vif.reset && prev_pc != vif.pc)
                send_instruction();
            prev_pc = vif.pc;
        end
    endtask


    // Send the current instruction to the analysis port
    task send_instruction();
        instruction instr;
        instr = instruction::type_id::create($sformatf("instr_%0d", vif.pc));
        instr.disassemble(vif.instr);
        $display("[%0t] Sending instruction '%0h' at PC '%0d'", $time, vif.instr, vif.pc);
        instr_ap.write(instr);
    endtask
endclass
