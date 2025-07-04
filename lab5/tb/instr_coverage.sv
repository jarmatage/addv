class instr_coverage extends uvm_subscriber #(instruction);
    `uvm_component_utils(instr_coverage)

    uvm_analysis_imp #(instruction, instr_coverage) imp;
    instruction instr, prev_instr;
    int gap;


    covergroup instr_fields_cg;
        // Opcode
        opcode_cp : coverpoint instr.opcode {
            bins RTYPE = {6'h00};
            bins LW  = {6'h23};
            bins SW  = {6'h2B};
            bins BEQ = {6'h04};
        }

        // Function code
        funct_cp : coverpoint instr.funct {
            bins NOP = {6'h00};
            bins ADD = {6'h20};
            bins AND = {6'h24};
        }

        // ADD
        add_rs : coverpoint instr.rs iff (instr.opcode == 6'h00 && instr.funct == 6'h20) {
            bins rs_vals[] = {[0:4]};
        }
        add_rt : coverpoint instr.rt iff (instr.opcode == 6'h00 && instr.funct == 6'h20) {
            bins rt_vals[] = {[0:4]};
        }
        add_rd : coverpoint instr.rd iff (instr.opcode == 6'h00 && instr.funct == 6'h20) {
            bins rd_vals[] = {[1:4]};
        }
        add_throw_away : coverpoint instr.rd iff (instr.opcode == 6'h00 && instr.funct == 6'h20) {
            bins rd_vals[] = {0};
        }
        add_cross : cross add_rs, add_rt, add_rd;

        // AND
        and_rs : coverpoint instr.rs iff (instr.opcode == 6'h00 && instr.funct == 6'h24) {
            bins rs_vals[] = {[0:4]};
        }
        and_rt : coverpoint instr.rt iff (instr.opcode == 6'h00 && instr.funct == 6'h24) {
            bins rt_vals[] = {[0:4]};
        }
        and_rd : coverpoint instr.rd iff (instr.opcode == 6'h00 && instr.funct == 6'h24) {
            bins rd_vals[] = {[1:4]};
        }
        and_throw_away : coverpoint instr.rd iff (instr.opcode == 6'h00 && instr.funct == 6'h24) {
            bins rd_vals[] = {0};
        }
        and_cross : cross and_rs, and_rt, and_rd;

        // LW
        lw_rs : coverpoint instr.rs iff (instr.opcode == 6'h23) {
            bins rs_vals[] = {0};
        }
        lw_rt : coverpoint instr.rt iff (instr.opcode == 6'h23) {
            bins rt_vals[] = {[0:4]};
        }
        lw_imm : coverpoint instr.imm iff (instr.opcode == 6'h23) {
            bins imm_vals[] = {16'h0, 16'h4, 16'h8, 16'hC};
        }
        lw_cross : cross lw_rs, lw_rt, lw_imm;

        // SW
        sw_rs : coverpoint instr.rs iff (instr.opcode == 6'h2B) {
            bins rs_vals[] = {0};
        }
        sw_rt : coverpoint instr.rt iff (instr.opcode == 6'h2B) {
            bins rt_vals[] = {[0:4]};
        }
        sw_imm : coverpoint instr.imm iff (instr.opcode == 6'h2B) {
            bins imm_vals[] = {16'h0, 16'h4, 16'h8, 16'hC};
        }
        sw_cross : cross sw_rs, sw_rt, sw_imm;

        // BEQ
        beq_rs : coverpoint instr.rs iff (instr.opcode == 6'h04) {
            bins rs_vals[] = {[0:4]};
        }
        beq_rt : coverpoint instr.rt iff (instr.opcode == 6'h04) {
            bins rt_vals[] = {[0:4]};
        }
        beq_imm : coverpoint instr.imm iff (instr.opcode == 6'h04) {
            bins imm_vals[] = {16'd1, 16'd2, 16'd3, 16'd4};
        }
        beq_cross : cross beq_rs, beq_rt, beq_imm;
    endgroup


    covergroup branching_cg;
        branch_taken : coverpoint instr.rs {
            bins rs_eq_rt[] = {[0:4]} iff (instr.rs == instr.rt && instr.opcode == 6'h04);
        }
        branch_not_taken_rs : coverpoint instr.rs {
            bins rs_ne_rt[] = {[0:4]} iff (instr.rs != instr.rt && instr.opcode == 6'h04);
        }
        branch_not_taken_rt : coverpoint instr.rt {
            bins rt_ne_rs[] = {[0:4]} iff (instr.rs != instr.rt && instr.opcode == 6'h04);
        }
    endgroup


    covergroup instr_gap_cg;
        reg_dep : coverpoint gap iff (
            prev_instr.opcode == 6'h00 && 
            instr.opcode != 6'h23 && 
            instr.rt == prev_instr.rd
        ) {
            bins gap_vals[] = {[0:3]};
        }
        mem_dep : coverpoint gap iff (
            prev_instr.opcode == 6'h2B &&
            instr.opcode == 6'h23 &&
            instr.imm == prev_instr.imm
        ) {
            bins gap_vals[] = {[0:3]};
        }
        lw_dep : coverpoint gap iff (
            prev_instr.opcode == 6'h23 &&
            instr.opcode == 6'h00 &&
            instr.funct != 6'h00 &&
            instr.rs == prev_instr.rt
        ) {
            bins gap_vals[] = {[0:3]};
        }
    endgroup


    function new(string name, uvm_component parent);
        super.new(name, parent);
        $display("Creating instruction coverage collector");
        imp = new("imp", this);
        instr_fields_cg = new();
        branching_cg = new();
        instr_gap_cg = new();
        gap = 0;
    endfunction


    virtual function void write(instruction t);
        bit [31:0] code = t.assemble();
        instr = t;
        instr_fields_cg.sample();
        branching_cg.sample();

        if (code == 32'd0) begin
            gap++;
        end else begin
            if (prev_instr != null)
                instr_gap_cg.sample();
            prev_instr = instr;
        end
    endfunction
endclass
