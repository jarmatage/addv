`include "uvm_macros.svh"

class apb_sequence extends uvm_sequence #(apb_master_seq_item);
    `uvm_object_utils(apb_sequence)

    logic [`DATA_WIDTH-1:0] done;
    int poll_count;

    function new(string name = "apb_sequence");
        super.new(name);
    endfunction


    task body();
        // Write to address registers
        `uvm_info(get_type_name(), "\nWriting to ADDR_MAT_A", UVM_MEDIUM)
        write(4'd1, 16'd0);
        `uvm_info(get_type_name(), "\nWriting to ADDR_MAT_B", UVM_MEDIUM)
        write(4'd2, 16'd0);
        `uvm_info(get_type_name(), "\nWriting to ADDR_MAT_C", UVM_MEDIUM)
        write(4'd3, 16'd0);

        // Write to stride registers
        `uvm_info(get_type_name(), "\nWriting to STRIDE_A", UVM_MEDIUM)
        write(4'd4, 16'd1);
        `uvm_info(get_type_name(), "\nWriting to STRIDE_B", UVM_MEDIUM)
        write(4'd5, 16'd1);
        `uvm_info(get_type_name(), "\nWriting to STRIDE_C", UVM_MEDIUM)
        write(4'd6, 16'd1);

        // Write to start register
        `uvm_info(get_type_name(), "\nWriting to START", UVM_MEDIUM)
        write(4'd0, 16'd1);

        // Poll done register until done
        `uvm_info(get_type_name(), "\nPolling the DONE register", UVM_MEDIUM)
        read(1, 4'd7, done);
        poll_count = 0;
        while (!done[0]) begin
            read(0, 4'd7, done);
            poll_count++;
        end
        `uvm_info(get_type_name(), $sformatf(
            "\nDONE register indicated completion after %0d polls, fp8 status flags = %b", poll_count, done[5:1]), UVM_MEDIUM)
    endtask


    task write(input [`ADDR_WIDTH-1:0] addr, input [`DATA_WIDTH-1:0] data);
        apb_master_seq_item item;
        item = apb_master_seq_item::type_id::create("write_transaction");
        item.apb_tr = 1; // WRITE transaction
        item.addr = addr;
        item.data = data;
        item.delay = 1;
        start_item(item);
        finish_item(item);
    endtask


    task read(input int delay, input [`ADDR_WIDTH-1:0] addr, output [`DATA_WIDTH-1:0] data);
        apb_master_seq_item item;
        item = apb_master_seq_item::type_id::create("read_transaction");
        item.apb_tr = 0; // READ transaction
        item.addr = addr;
        item.delay = delay;
        start_item(item);
        finish_item(item);
        data = item.data;
    endtask
endclass
