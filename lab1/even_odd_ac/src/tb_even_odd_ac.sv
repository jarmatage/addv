`timescale 1ns / 1ps

module tb_even_odd_ac;

    localparam int WIDTH = 8;  // width of data
    localparam int DEPTH = 40; // the amount each fifo needs to hold

    // Setup signals for DUT
    logic clk, rst_n, ren, wen;
    logic [WIDTH-1:0] din, dout;

    // Instantiate DUT
    even_odd_ac #(WIDTH, DEPTH) dut(.*);

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10ns period = 100MHz

    // Reset the DUT
    initial begin
        rst_n = 0;
        ren = 0;
        wen = 0;
        din = 0;
        #25;
        rst_n = 1;
        #25;
    end

    // Testbench internals
    int evens[DEPTH];
    int odds[DEPTH];
    int write_seq[100] = '{80{1'b1}, 20{1'b0}};

    initial begin
        $display("Random sequence: %p", write_seq);
        write_seq.shuffle();
        $display("Random sequence: %p", write_seq);
        $finish;
    end

    // Input stimulus process
    initial begin
        clk = 0;
        rst = 1;
        in_valid = 0;
        in_data = 0;
        output_count = 0;

        // Fill arrays
        for (i = 0; i < 40; i++) begin
            even_vals[i] = i * 2;
            odd_vals[i]  = i * 2 + 1;
            mixed_vals[i] = even_vals[i];
            mixed_vals[i + 40] = odd_vals[i];
        end

        // Shuffle
        shuffle_array(mixed_vals, shuffled_vals, 80);

        // Reset
        #20;
        rst = 0;

        // Send input
        for (i = 0; i < 80; i++) begin
            @(posedge clk);
            in_valid <= 1;
            in_data <= shuffled_vals[i];
        end

        // Hold last input one extra cycle
        @(posedge clk);
        in_valid <= 0;

        // Wait for output
        while (output_count < 80) begin
            @(posedge clk);
            if (out_valid) begin
                output_vals[output_count] = out_data;
                output_count++;
            end
        end

        // Verify alternating pattern
        for (i = 0; i < 80; i++) begin
            if ((i % 2 == 0) && (output_vals[i] % 2 != 0)) begin
                $display("❌ ERROR at output %0d: expected EVEN, got %0d", i, output_vals[i]);
                $fatal;
            end else if ((i % 2 == 1) && (output_vals[i] % 2 != 1)) begin
                $display("❌ ERROR at output %0d: expected ODD, got %0d", i, output_vals[i]);
                $fatal;
            end
        end

        $display("✅ Test passed: Output alternates correctly between even and odd.");
        $finish;
    end

endmodule
