`include "memory_defines.svh"

class memory_seq_item extends uvm_sequence_item;
    `uvm_object_utils(memory_seq_item)

    // Data members
    typedef enum {READ, WRITE} mem_agent_mode_t;
    mem_agent_mode_t mode;
    bit [31:0] addr;
    bit [31:0] data;

    // Constructor
    function new(string name = "memory_seq_item");
        super.new(name);
    endfunction

    // Display as string
    function string convert2string();
        return $psprintf("\n \
-------------------------MEMORY_TRANSFER------------------------- \n \
MODE=%s \n \
ADDR=%0h \n \
DATA=%0h \n \
--------------------------------------------------------------", mode, addr, data);
    endfunction
endclass
