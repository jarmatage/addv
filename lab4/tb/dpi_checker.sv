module dpi_checker (
    write_if write,     // Push interface
    read_if  read       // Pop interface
);

    integer result;
    always begin
        @(posedge clk);
        result = add(a, b);
        $display("Result from C function: %0d", result);
        @(negedge clk);
        if (result != c) $error("Failed");
        else $display("Pass");
    end

endmodule
