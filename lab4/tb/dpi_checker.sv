module dpi_checker (
    write_if write,     // Push interface
    read_if  read       // Pop interface
);

    import "DPI-C" context function void push(byte data);
    import "DPI-C" context function byte pop();
    import "DPI-C" context function bit  is_empty();
    import "DPI-C" context function bit  is_full();
    import "DPI-C" context function void reset();

    byte expected_rdata;

    // Call C push() on every write
    always_ff @(posedge write.clk) begin
        if (write.en)
            push(write.data);
    end

    // Call C pop() on every read and compare data
    always_ff @(posedge read.clk) begin
        if (read.en) begin
            expected_rdata = pop();
            if (!read.empty && expected_rdata == read.data)
                $display("[%0t] INFO: read data '%0d' matches C model", $time, read.data);
            else
                $error("[%0t] ERROR: read data '%0d' does not match C model '%0d'", $time, read.data, expected_rdata);
        end
    end

    // Continuously check full and empty flags
    always_ff @(posedge write.clk) begin
        if (is_full() != write.full)
            $error("[%0t] ERROR: full flag mismatch, expected: %b, got: %b", $time, is_full(), write.full);
    end
    always_ff @(posedge read.clk) begin
        if (is_empty() != read.empty)
            $error("[%0t] ERROR: empty flag mismatch, expected: %b, got: %b", $time, is_empty(), read.empty);
    end

    // Reset the C model on reset signal
    always_ff @(negedge write.rst_n or negedge read.rst_n) reset();

endmodule
