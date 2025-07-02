class instr_env extends uvm_env;
    `uvm_component_utils(instr_env)

    instr_monitor mon;
    instr_coverage cov;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = instr_monitor::type_id::create("mon", this);
        cov = instr_coverage::type_id::create("cov", this);
    endfunction


    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon.ap.connect(cov.imp);
    endfunction
endclass
