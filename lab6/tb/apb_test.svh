`include "uvm_macros.svh"
`include "apb_env.svh"
`include "apb_sequence.svh"

class apb_test extends uvm_test;
	`uvm_component_utils(apb_test)
  
	apb_env env;
	
	apb_master_config 	m_apb_master_config;
	apb_slave_config 	m_apb_slave_config;
	
	virtual apb_if vif;
	apb_sequence master_seq;


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
	endfunction


	task run_phase (uvm_phase phase);
		super.run_phase(phase);
		master_seq = apb_sequence::type_id::create("master_seq");
			
		phase.raise_objection(this, "Starting apb_test run phase");
		master_seq.start(env.master_agent.m_sequencer);
		//phase.drop_objection(this, "Finished apb_test in run phase");
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




