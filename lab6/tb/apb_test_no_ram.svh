`include "uvm_macros.svh"
`include "apb_env_no_ram.svh"
`include "apb_sequence.svh"

class apb_test extends uvm_test;
	`uvm_component_utils(apb_test)

    // Matrix dimensions
    localparam int N = 4;

    // Matrices
    rand bit [31:0] mem_a[N];
    rand bit [31:0] mem_b[N];

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
		assert(this.randomize());

		// TODO: Compute expected C

		// Set the matrices in the environment
		uvm_config_db#(bit [31:0] [4])::set(this, "env.ram_a.driver", "mem_model", mem_a);
		uvm_config_db#(bit [31:0] [4])::set(this, "env.ram_b.driver", "mem_model", mem_b);
	endfunction


	task run_phase (uvm_phase phase);
		super.run_phase(phase);
		master_seq = apb_sequence::type_id::create("master_seq");
		mem_seq_a = memory_seq::type_id::create("mem_seq_a");
		mem_seq_b = memory_seq::type_id::create("mem_seq_b");
		mem_seq_c = memory_seq::type_id::create("mem_seq_c");

		phase.raise_objection(this, "Starting apb_test run phase");
		fork
			master_seq.start(env.master_agent.m_sequencer);
			mem_seq_a.start(env.ram_a.sequencer);
			mem_seq_b.start(env.ram_b.sequencer);
			mem_seq_c.start(env.ram_c.sequencer);
		join
		
		`uvm_info("INFO", "displaying matrix A", UVM_LOW);
		env.ram_a.driver.display_row_major();
		`uvm_info("INFO", "displaying matrix B", UVM_LOW);
		env.ram_b.driver.display_col_major();
		`uvm_info("INFO", "displaying matrix C", UVM_LOW);
		env.ram_c.driver.display_row_major();

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
endclass




