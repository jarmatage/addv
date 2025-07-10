`include "uvm_macros.svh"
`include "apb_env_no_ram.svh"
`include "apb_sequence.svh"

class apb_test extends uvm_test;
	`uvm_component_utils(apb_test)

    // Matrix dimensions
    localparam int N = 4;

    // Matrices
    rand bit [7:0] matrix_a[N][N];
    rand bit [7:0] matrix_b[N][N];
    bit [7:0] matrix_c_expected[N][N];

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

		// Randomize A and B
		assert(this.randomize());
		foreach (matrix_c_expected[i, j]) begin
			matrix_c_expected[i][j] = 0;
			for (int k = 0; k < N; k++)
				matrix_c_expected[i][j] += matrix_a[i][k] * matrix_b[k][j];
		end

		// Configure memory models
		bit [31:0] mem_a[*], mem_b[*];
		foreach (matrix_a[i][j])
		mem_a[{i, j}] = matrix_a[i][j];
		foreach (matrix_b[i][j])
		mem_b[{i, j}] = matrix_b[i][j];

		uvm_config_db#(typeof(mem_a))::set(this, "env.agent_a.drv", "mem_model", mem_a);
		uvm_config_db#(typeof(mem_b))::set(this, "env.agent_b.drv", "mem_model", mem_b);
	endfunction


	task run_phase (uvm_phase phase);
		super.run_phase(phase);
		master_seq = apb_sequence::type_id::create("master_seq");
			
		phase.raise_objection(this, "Starting apb_test run phase");
		master_seq.start(env.master_agent.m_sequencer);
		//phase.drop_objection(this, "Finished apb_test in run phase");
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




