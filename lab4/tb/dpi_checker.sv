import "DPI-C" context function void push(byte data);
import "DPI-C" context function byte pop();
import "DPI-C" context function bit  is_empty();
import "DPI-C" context function bit  is_full();
import "DPI-C" context function void reset();

module dpi_checker (
    write_if write,     // Push interface
    read_if  read       // Pop interface
);

    logic is_full, is_empty;
    logic [7:0] expected_rdata;

    // Call C push() on every write
    always @(write.clk) begin
        if (write.en)
            push(write.data);
    end

    // Call C pop() on every read and compare data
    always @(read.clk) begin
        if (read.en) begin
            expected_rdata = pop();
            if (expected_rdata != read.data)
                $error("[%0t] ERROR: read data '%0d' does not match C model '%0d'", $time, txn.data, expected.data);
        end
    end

    // Continuously check full and empty flags
    always @(write.clk) begin
        is_full = is_full();
        if (is_full != write.full)
            $error("[%0t] ERROR: full flag mismatch, expected: %b, got: %b", $time, is_full, write.full);
    end
    always @(read.clk) begin
        is_empty = is_empty();
        if (is_empty != read.empty)
            $error("[%0t] ERROR: empty flag mismatch, expected: %b, got: %b", $time, is_empty, read.empty);
    end

endmodule
