class instruction extends uvm_sequence_item;
    `uvm_object_utils(instruction)

    rand bit [5:0]  opcode;
    rand bit [4:0]  rs, rt, rd;
    rand bit [5:0]  funct;
    rand bit [15:0] imm;


    constraint opcode_range {
        opcode inside {
            6'b000000, // R-type
            6'b100011, // I-type, LW
            6'b101011, // I-type, SW
            6'b000100  // I-type, BEQ
        };
    }


    constraint rs_range {
        if (opcode == 6'b000000 || opcode == 6'b000100) 
            rs inside {5'd0, 5'd1, 5'd2, 5'd3, 5'd4}; // R-type or BEQ
        else
            rs == 5'd0; // Make base address 0 for LW/SW
    }


    constraint rt_range {
        rt inside {5'd0, 5'd1, 5'd2, 5'd3, 5'd4};
    }


    constraint rd_range {
        rd inside {5'd1, 5'd2, 5'd3, 5'd4};
    }


    constraint funct_range {
        funct inside {
            6'b100000, // ADD
            6'b100100  // AND
        };
    }


    constraint imm_range {
        if (opcode == 6'b000100) {
            imm inside {16'd1, 16'd2, 16'd3, 16'd4}; // Specific offsets for BEQ
        } else {
            imm inside {16'h0, 16'h4, 16'h8, 16'hC}; // Aligned addresses for LW/SW
        }
    }


    function new(string name="my_instruction");
        super.new(name);
    endfunction


    function bit [31:0] assemble();
        if (opcode == 6'b000000)
            return {opcode, rs, rt, rd, 5'h0, funct}; // R-type
        else
            return {opcode, rs, rt, imm}; // I-type
    endfunction


    function void disassemble(bit [31:0] instr);
        opcode = instr[31:26];
        rs = instr[25:21];
        rt = instr[20:16];

        if (opcode == 6'b000000) begin
            rd = instr[15:11];
            funct = instr[5:0];
        end else begin
            imm = instr[15:0];
        end
    endfunction
endclass
