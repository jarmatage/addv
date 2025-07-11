`include "uvm_macros.svh"
`include "apb_env_no_ram.svh"
`include "apb_sequence.svh"

class apb_test extends uvm_test;
	`uvm_component_utils(apb_test)

    // Matrices
    mem_array_t mem_a;
    mem_array_t mem_b;
	mem_array_t mem_c;
	mem_array_t expected_c;

	apb_env env;
	
	apb_master_config 	m_apb_master_config;
	apb_slave_config 	m_apb_slave_config;
	
	virtual apb_if vif;
	apb_sequence master_seq;

	memory_seq mem_seq_a;
	memory_seq mem_seq_b;
	memory_seq mem_seq_c;


	function new (string name = "apb_test", uvm_component parent = null);
		super.new(name, parent);
		$display("Creating APB test");
	endfunction


	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		
		env = apb_env::type_id::create("env", this);
		
		m_apb_master_config = apb_master_config::type_id::create("m_apb_master_config"); 		
		m_apb_slave_config  = apb_slave_config::type_id::create("m_apb_slave_config"); 		
			
		uvm_config_db#(apb_master_config)::set(null, "", "apb_master_config", m_apb_master_config);
		uvm_config_db#(apb_slave_config)::set(null, "", "apb_slave_config", m_apb_slave_config);
		
		if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", vif)) begin
			`uvm_fatal(get_full_name(), "No virtual interface specified for this test instance")
		end

		// Randomize A and B
		for (int i = 0; i < 4; i++) begin
			mem_c[i] = 32'd0;
			expected_c[i] = 32'd0;
			mem_a[i] = rand_row();
			mem_b[i] = rand_row();
		end

		// Fixed value for class bringup
        // mem_a[3]  = {8'b1_011_0110, 8'b0_101_0001, 8'b0_001_0111, 8'b0_010_0110};
        // mem_a[2]  = {8'b1_100_1000, 8'b1_010_0010, 8'b0_010_0110, 8'b0_011_1100};
        // mem_a[1]  = {8'b0_011_0011, 8'b1_001_0100, 8'b1_011_0110, 8'b0_101_0111};
        // mem_a[0]  = {8'b0_100_0001, 8'b0_001_0001, 8'b0_000_0000, 8'b1_011_0111};
        // mem_b[3]  = {8'b0_011_1000, 8'b0_001_0000, 8'b0_011_0011, 8'b0_100_0000};
        // mem_b[2]  = {8'b0_000_1000, 8'b0_010_0100, 8'b0_010_0110, 8'b1_100_1000};
        // mem_b[1]  = {8'b0_011_0000, 8'b1_011_0000, 8'b0_011_0100, 8'b0_011_0000};
        // mem_b[0]  = {8'b0_110_0100, 8'b0_001_0001, 8'b0_000_0000, 8'b0_011_0111};

		// Set the matrices in the environment
		uvm_config_db#(mem_array_t)::set(this, "env.ram_a.driver", "mem_model", mem_a);
		uvm_config_db#(mem_array_t)::set(this, "env.ram_b.driver", "mem_model", mem_b);
		uvm_config_db#(mem_array_t)::set(this, "env.ram_c.driver", "mem_model", mem_c);
	endfunction


	task run_phase (uvm_phase phase);
		super.run_phase(phase);
		master_seq = apb_sequence::type_id::create("master_seq");
		mem_seq_a = memory_seq::type_id::create("mem_seq_a");
		mem_seq_b = memory_seq::type_id::create("mem_seq_b");
		mem_seq_c = memory_seq::type_id::create("mem_seq_c");

		phase.raise_objection(this, "Starting apb_test run phase");

		fork
			mem_seq_a.start(env.ram_a.sequencer);
			mem_seq_b.start(env.ram_b.sequencer);
			mem_seq_c.start(env.ram_c.sequencer);
			master_seq.start(env.master_agent.m_sequencer);
		join_any
		
		`uvm_info("INFO", "displaying matrix A:", UVM_LOW);
		display_row_major(mem_a);
		`uvm_info("INFO", "displaying matrix B:", UVM_LOW);
		display_col_major(mem_b);
		#55;
		`uvm_info("INFO", "displaying matrix C:", UVM_LOW);
		display_row_major(env.ram_c.driver.mem_model);
		`uvm_info("INFO", "displaying expected C:", UVM_LOW);
		compute_expected_c();

		phase.drop_objection(this, "Finished apb_test in run phase");
	endtask


	function void end_of_elaboration_phase (uvm_phase phase);
		super.end_of_elaboration_phase(phase);

		// Print topology
		`uvm_info("TOPOLOGY", "Printing UVM topology...", UVM_LOW)
		uvm_top.print_topology();

		// Print env
		`uvm_info("PRINT_ENV", "Printing ENV...", UVM_LOW)
		env.print();
  	endfunction


	function automatic byte rand_fp8();
		byte fp8;
		bit       s;
		bit [2:0] e;
		bit [3:0] m;

		// Randomize parts
		s = $urandom_range(0, 1);
		e = $urandom_range(0, 5); // exclude 7 (111) to avoid INF/NaN
		m = $urandom_range(0, 15);

		// Compose final fp8
		fp8 = {s, e, m}; // s is MSB
		$display("rand_fp8: %b", fp8);
		return fp8;
	endfunction


	function automatic [31:0] rand_row();
		byte b0 = rand_fp8();
		byte b1 = rand_fp8();
		byte b2 = rand_fp8();
		byte b3 = rand_fp8();
		return {b0, b1, b2, b3};
	endfunction


	function void compute_expected_c();
		// Compute expected C = A * B
		for (int i = 0; i < 4; i++) begin
			for (int j = 0; j < 4; j++) begin
				for (int k = 0; k < 4; k++) begin
					expected_c[i] = 32'd0;
				end
			end
		end
	endfunction


    task display_row_major(input mem_array_t mem);
        for (int i = 0; i <= 24; i += 8) begin
            $write("|");
            for (int j = 0; j < 4; j++) begin
                $write(" ");
                display_fp8(mem[j][i+:8]);
            end
            $display(" |");
        end
    endtask
    
	
	task display_col_major(input mem_array_t mem);
        for (int i = 0; i < 4; i++) begin
            $write("|");
            for (int j = 0; j <= 24; j += 8) begin
                $write(" ");
                display_fp8(mem[i][j+:8]);
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
