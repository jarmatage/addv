class instr_coverage extends uvm_subscriber #(instruction);
    `uvm_component_utils(instr_coverage)

    uvm_analysis_imp #(instruction, instr_coverage) imp;
    instruction t; // current instruction
    instruction prev_instr;


    covergroup instr_fields_cg;
        opcode_cp : coverpoint t.opcode {
            bins ADD = {6'h00};
            bins LW  = {6'h23};
            bins SW  = {6'h2B};
            bins BEQ = {6'h04};
        }
    endgroup


    function new(string name, uvm_component parent);
        super.new(name, parent);
        $display("Creating instruction coverage collector");
        imp = new("imp", this);
    endfunction


    virtual function void write(instruction t);
        instr_fields_cg.sample();
    endfunction
endclass
