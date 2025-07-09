`include "memory_defines.svh"

class memory_driver extends uvm_driver#(memory_seq_item);
    `uvm_component_utils(memory_driver)

    virtual memory_if vif;
    mem_agent_mode_t mode;
    bit [31:0] mem_model[*];
    memory_seq_item item;

    // Constructor
    function new (string name = "memory_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual memory_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Failed to get virtual interface")
        if (!uvm_config_db#(mem_agent_mode_t)::get(this, "", "mode", mode))
            `uvm_fatal("NOMODE", "Failed to get agent mode")
    endfunction


    // Main run task
    task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            @(posedge vif.clk);
            if (vif.en) begin
                if (mode == memory_seq_item::READ) begin
                    read();
                end else if (mode == memory_seq_item::WRITE) begin
                    write();
                end else begin
                    `uvm_fatal("INVALID_MODE", $sformatf("Invalid mode: %s", mode.name()));
                end
            end else begin
                `uvm_info(get_type_name(), "Waiting for enable signal", UVM_LOW);
            end
        end
    endtask

    task read();
        item = memory_seq_item::type_id::create("mem_read");
        item.mode = memory_seq_item::READ;
        item.addr = vif.addr;
        start_item(item);
        item.data = mem_model[item.addr];
        finish_item(item);
    endtask

    task write();
        item = memory_seq_item::type_id::create("mem_write");
        item.mode = memory_seq_item::WRITE;
        item.addr = vif.addr;
        item.data = vif.data;
        start_item(item);
        mem_model[item.addr] = item.data;
        finish_item(item);
    endtask

    task display_row_major();
        for (int i = 0; i <= 24; i += 8) begin
            $write("|");
            for (int j = 0; j < 4; j++) begin
                $write(" ");
                display_fp8(mem_model[j][i+:8]);
            end
            $display(" |");
        end
    endtask

    task display_col_major();
        for (int i = 0; i < 4; i++) begin
            $write("|");
            for (int j = 0; j <= 24; j += 8) begin
                $write(" ");
                display_fp8(mem_model[i][j+:8]);
            end
            $display(" |");
        end
    endtask

    task display_fp8(input logic [7:0] fp);
        real abs_fp;

        if (fp[7]) begin
            abs_fp = -fp8_to_real(fp);
            $write("-");
        end else begin
            abs_fp = fp8_to_real(fp);
            $write("+");
        end

        if (fp[6:0] == 7'b111_0000)
            $write("inf     ");
        else if (fp[6:4] == 3'b111)
            $write("nan     ");
        else if (fp[6:0] == 7'b000_0000)
            $write("0.000000");
        else
            $write("%f", abs_fp);
    endtask   

    function real fp8_to_real(input logic [7:0] fp);
        logic sign;
        logic [2:0] exp;
        logic [3:0] mant;
        int unbiased_exp;
        real r_mant;

        sign = fp[7];
        exp  = fp[6:4];
        mant = fp[3:0];

        if (exp == 0 && mant == 0) return 0.0;

        unbiased_exp = exp - 3;
        r_mant = 1.0 + mant / 16.0;
        return (sign ? -1.0 : 1.0) * r_mant * (2.0 ** unbiased_exp);
    endfunction

endclass
