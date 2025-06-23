class transaction;

    bit is_write = 1'b1; // Default to write transaction
    bit [7:0] data;
    bit empty;
    bit almost_empty;
    bit full;
    bit almost_full;
    time timestamp;


    function new();
    endfunction


    function string brief();
        if (is_write)
            return $sformatf("[%0t] WRITE TRANSACTION", timestamp);
        else
            return $sformatf("[%0t] READ TRANSACTION", timestamp);
    endfunction


    function string verbose();
        return $sformatf("data = %0d, empty = %b, almost_empty = %b, full = %b, almost_full = %b",
            data, empty, almost_empty, full, almost_full);
    endfunction


    task print(int log_level = 0);
        case (log_level)
            1: $display("%s", brief());
            2: $display("%s: %s", brief(), verbose());
            default: ;
        endcase
    endtask 

endclass
