`include "uvm_macros.svh"

class apb_env extends uvm_env;
	`uvm_component_utils(apb_env)

	apb_master_agent master_agent;
	memory_slave_agent ram_a;
	memory_slave_agent ram_b;
	memory_slave_agent ram_c;

	virtual apb_if vif;
	virtual memory_if ram_a_vif;
	virtual memory_if ram_b_vif;
	virtual memory_if ram_c_vif;


	function new (string name = "apb_env", uvm_component parent = null);
		super.new(name, parent);
		$display("Creating APB environment");
	endfunction


	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		
		master_agent = apb_master_agent::type_id::create("master_agent", this);
		ram_a = memory_slave_agent::type_id::create("ram_a", this);
		ram_b = memory_slave_agent::type_id::create("ram_b", this);
		ram_c = memory_slave_agent::type_id::create("ram_c", this);
			
		if (!uvm_config_db#(virtual apb_if)::get(null, "", "apb_vif", vif)) begin
			`uvm_fatal(get_full_name(), "No virtual interface specified for env")
		end
		if (!uvm_config_db#(virtual memory_if)::get(null, "", "ram_a_vif", ram_a_vif)) begin
			`uvm_fatal(get_full_name(), "No virtual interface specified for RAM A")
		end
		if (!uvm_config_db#(virtual memory_if)::get(null, "", "ram_b_vif", ram_b_vif)) begin
			`uvm_fatal(get_full_name(), "No virtual interface specified for RAM B")
		end
		if (!uvm_config_db#(virtual memory_if)::get(null, "", "ram_c_vif", ram_c_vif)) begin
			`uvm_fatal(get_full_name(), "No virtual interface specified for RAM C")
		end

		uvm_config_db#(virtual memory_if)::set(this, "ram_a", "vif", ram_a_vif);
		uvm_config_db#(virtual memory_if)::set(this, "ram_b", "vif", ram_b_vif);
		uvm_config_db#(virtual memory_if)::set(this, "ram_c", "vif", ram_c_vif);

		uvm_config_db#(virtual memory_if)::set(this, "ram_a", "mode", 0);
		uvm_config_db#(virtual memory_if)::set(this, "ram_b", "mode", 0);
		uvm_config_db#(virtual memory_if)::set(this, "ram_c", "mode", 1);
	endfunction
endclass


