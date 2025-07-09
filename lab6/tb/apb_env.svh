import uvm_pkg::*;
`include "uvm_macros.svh" 

import apb_master_pkg::*;
import apb_slave_pkg::*;

class apb_env extends uvm_env;
	`uvm_component_utils(apb_env)

	apb_master_agent  master_agent;
	apb_slave_agent  slave_agent;

	virtual apb_if vif;


	function new (string name = "apb_env", uvm_component parent = null);
		super.new(name, parent);
		$display("Creating APB environment");
	endfunction


	function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		
		master_agent = apb_master_agent::type_id::create("master_agent", this);
		slave_agent  = apb_slave_agent::type_id::create("slave_agent", this);
			
		if (!uvm_config_db#(virtual apb_if)::get(null, "", "apb_vif", vif)) begin
			`uvm_fatal(get_full_name(), "No virtual interface specified for env")
		end
	endfunction
endclass


