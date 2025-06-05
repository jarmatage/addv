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

    // Testbench internals
    int i, j;
    int evens[DEPTH];
    int odds[DEPTH];
    int vals[2*DEPTH];
    int write_seq[100];
    int read_seq[100];
    int read_snippet[10];

    // Test sequence
    initial begin
	$fsdbDumpvars();

	// Generate a random sequence to perform the writes
	for (int i = 0; i < 80; i++)
		write_seq[i] = 1;
        write_seq.shuffle();
        $display("Write Sequence: %p", write_seq);

	// Generate a random sequence to perform the reads
	for (int i = 0; i < 8; i++)
		read_snippet[i] = 1;
	for (int i = 0; i < 10; i++) begin
		read_snippet.shuffle();
		$display("Read Sequence %0d: %p", i, read_snippet);
		for (int j = 0; j < 10; j++)
			read_seq[10*i + j] = read_snippet[j];
	end
        
	// Generate even and odd values
	for (int i = 0; i < DEPTH; i++)
		evens[i] = $urandom_range(0, 50) * 2;
	$display("Evens: %p", evens);
	for (int i = 0; i < DEPTH; i++)
		odds[i] = $urandom_range(0, 50) * 2 + 1;
	$display("Odds: %p", odds);
	vals = {evens, odds};
	vals.shuffle();
	$display("Shuffled: %p", vals);
        
	// Reset
	rst_n = 0;
        ren = 0;
        wen = 0;
        din = 0;
        #25;
        rst_n = 1;
        #25;

	// Send input over 100 clock cycles
	j = 0;	
	for (int i = 0; i < 100;  i++) begin
		if (write_seq[i]) begin
			wen = 1'b1;
			din = vals[j];
			$display("Writing %0d value '%d' in clk cycle %0d", j, din, i);
			j = j + 1;
		end else
			wen <= 1'b0;
		@(posedge clk);
		#1;
	end

	// Wait one more clock cycle
	din = 0;
	wen <= 1'b0;
	@(posedge clk);
	#1;

	// Read back out over 100 clock cycles
	j = 0;
	for (int i = 0; i < 100; i++) begin
		ren = read_seq[i];
		@(posedge clk);
		#1;
		if (read_seq[i]) begin
			$display("Read %0d value '%d' in clk cycle %0d", j, dout, i);
			j = j + 1;
		end
	end

	$finish;
    end

endmodule

