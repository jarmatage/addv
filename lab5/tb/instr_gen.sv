class instr_gen extends uvm_sequence #(instruction);
    `uvm_object_utils(instr_gen)

    int imem_size = 256; // Size of instruction memory
    instruction instr_list[];
    bit [31:0] machine_code_list[];


    // Create a new instruction generator object
    function new(string name="my_instr_gen");
        super.new(name);
    endfunction

    
    // Generate pairs of instructions with gaps between until imem is full
    function void gen_sequence();
        gen_init();
        while (instr_list.size() < (imem_size - 6))
            gen_segment();
        for (int i = instr_list.size(); i < imem_size; i++)
            gen_nop();
        gen_machine_code();
    endfunction


    // Assemble the machine code for each instruction in the list
    function void gen_machine_code();
        machine_code_list = new [imem_size];
        for (int i = 0; i < instr_list.size(); i++)
            machine_code_list[i] = instr_list[i].assemble();
        $writememh("memfile.dat", machine_code_list, 0, imem_size - 1);
    endfunction


    // Add a new instruction to the instruction list
    function void add_instr(instruction instr);
        instr_list = new [instr_list.size() + 1] (instr_list);
        instr_list [instr_list.size() - 1] = instr;
    endfunction


    // Empty the instruction list and then initialize the reg file and dmem
    function void gen_init();
        instr_list.delete();
        for (int i = 1; i <= 4; i++)
            gen_init_reg(i);
        for (int i = 0; i <= 12; i += 4)
            gen_init_mem(i);
    endfunction


    // Generate an instruction that initializes a given register to 0
    function void gen_init_reg(int reg_num);
        instruction instr;
        instr = instruction::type_id::create("init_reg");
        assert(instr.randomize() with {
            opcode == 6'b000000;
            funct  == 6'b100000;
            rd     == reg_num;
            rs     == 5'd0;
            rt     == 5'd0;
        });
        add_instr(instr);
    endfunction


    // Generate an instruction that initializes a given memory address to 0
    function void gen_init_mem(int mem_addr);
        instruction instr;
        instr = instruction::type_id::create("init_mem");
        assert(instr.randomize() with {
            opcode == 6'b101011;
            rt     == 5'd0;
            imm    == mem_addr;
        });
        add_instr(instr);
    endfunction


    // Randomly select what sequence to generate
    function void gen_segment();
        int choice = $urandom_range(0, 9);
        case (choice)
            0: gen_register_dependency();
            1: gen_memory_dependency();
            2: gen_load_word_dependency();
            3: gen_branch_taken();
            4: gen_trickbox();
            default: gen_individual();
        endcase
    endfunction


    // Generate a pair of instructions with a register dependency
    function void gen_register_dependency();
        instruction a, b;
        a = instruction::type_id::create("reg_dep_A");
        b = instruction::type_id::create("reg_dep_B");

        assert(a.randomize() with {
            opcode == 6'b000000; // R-type
        });
        assert(b.randomize() with {
            opcode != 6'b100011; // Not a LW
            rt == a.rd; // RAW dependency (use rt since SW only uses rt)
        });

        add_instr(a);
        gen_gap();
        add_instr(b);
    endfunction


    // Generate a SW and LW pair with the same memory address
    function void gen_memory_dependency();
        instruction a, b;
        a = instruction::type_id::create("mem_dep_A");
        b = instruction::type_id::create("mem_dep_B");

        assert(a.randomize() with {
            opcode == 6'b101011; // SW
        });
        assert(b.randomize() with {
            opcode == 6'b100011; // LW
            imm == a.imm; // Same offset
        });

        add_instr(a);
        gen_gap();
        add_instr(b);
    endfunction


    // Generate load word dependency
    function void gen_load_word_dependency();
        instruction a, b;
        a = instruction::type_id::create("lw_dep_A");
        b = instruction::type_id::create("lw_dep_B");
        
        assert(a.randomize() with {
            opcode == 6'b100011; // LW
        });
        assert(b.randomize() with {
            opcode == 6'b000000; // R-type
            funct != 6'b000000; // Not a NOP
            rs == a.rt; // Use the loaded value
        });

        add_instr(a);
        gen_gap();
        add_instr(b);
    endfunction

    // Generate 0 to 4 random instructions
    function void gen_gap();
        int gap_size = $urandom_range(0, 3);
        for (int i = 0; i < gap_size; i++)
           gen_nop();
    endfunction

    
    // Generate a NOP instruction
    function void gen_nop();
        instruction instr;
        instr = instruction::type_id::create("nop");
        assert(instr.randomize() with {
            opcode == 6'b000000;
            funct  == 6'b000000;
            rd     == 5'd0;
            rs     == 5'd0;
            rt     == 5'd0;
        });
        add_instr(instr);
    endfunction


    // Generate a branch instruction that is guaranteed to be taken
    function void gen_branch_taken();
        instruction instr;
        instr = instruction::type_id::create("branch_taken");
        assert(instr.randomize() with {
            opcode == 6'b000100; // BEQ
            rs == rt; // Ensure branch condition is true
        });
        add_instr(instr);

        for (int i = 0; i < instr.imm; i++)
            gen_skipped(); // Instructions that should be skipped
    endfunction


    // Generate a TRICKBOX instruction that writes to a specific address
    function void gen_trickbox();
        instruction instr;
        instr = instruction::type_id::create("trickbox");
        instr.trick = 1;
        assert(instr.randomize() with {
            opcode == 6'b101011; // SW
            rt != 5'd0; // Read from register 1
            imm == 16'h1C; // Write to TRICKBOX address
        });
        add_instr(instr);
    endfunction


    // Generate a random instruction that should be skipped by the branch
    function void gen_skipped();
        instruction instr;
        instr = instruction::type_id::create("skipped_instr");
        assert(instr.randomize());
        add_instr(instr);
    endfunction


    // Generate a random instruction with no specific constraints
    function void gen_individual();
        instruction instr;
        instr = instruction::type_id::create("single_instr");
        assert(instr.randomize());
        add_instr(instr);
    endfunction


    // Display all instructions in the list
    task display_all();
        $display("\nInstruction Sequence:");
        foreach (instr_list[i])
            $display("[%0d] 0x%h, %s", i, machine_code_list[i], instr_list[i].get_name());
    endtask
endclass
