class instr_test extends uvm_test;
    `uvm_component_utils(instr_test)

    instr_env env;


    function new (string name = "instr_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction


    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        env = instr_env::type_id::create("instr_env", this);
    endfunction
endclass
