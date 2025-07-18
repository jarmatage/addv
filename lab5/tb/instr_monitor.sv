class instr_monitor extends uvm_monitor;
    `uvm_component_utils(instr_monitor)
    
    virtual mips_if vif;
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
        if (!uvm_config_db#(virtual mips_if)::get(null, "", "vif", vif))
            `uvm_fatal("NOVIF", "virtual interface not set in config_db")
    endfunction


    // Main sampling process
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this, "Keeping simulation alive");
        $display("Starting instruction monitor run phase");
        forever begin
            @(posedge vif.clk);
            if (!vif.reset && prev_pc != vif.pc)
                send_instruction();
            trickbox();
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


    // Trick box
    task trickbox();
        if (!vif.reset && vif.memwrite && vif.dataadr == 32'h1C)
            $display("[TRICK-BOX] CPU says: 0x%08x (%0d)", vif.writedata, vif.writedata);
    endtask
endclass
