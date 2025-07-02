class instr_coverage extends uvm_subscriber #(instruction);
    `uvm_component_utils(instr_coverage)

    uvm_analysis_imp #(instruction, instr_coverage) imp;
    instruction prev_instr;


    covergroup instr_fields_cg;
    endgroup


    covergroup instr_order_cg;
    endgroup


    covergroup instr_gap_cg;
    endgroup


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


    function void write(instruction t);
        instr_fields_cg.sample();
        if (prev_instr != null) begin
            instr_order_cg.sample();
            instr_gap_cg.sample();
        end
        prev_instr = t;
    endfunction
endclass
