class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)

  write_agent       w_ag;
  read_agent        r_ag;
  fifo_monitor      mon;
  fifo_scoreboard   sb;
  fifo_checker      chk;

  virtual write_if w_vif;
  virtual read_if  r_vif;

  covergroup clock_periods;
    wperiod: coverpoint (`WCLK_T) {
      bins wt_vals[] = {5, 10, 15, 20};
    }

    rperiod: coverpoint (`RCLK_T) {
      bins rt_vals[] = {5, 10, 15, 20};
    }

    cross wperiod, rperiod;
  endgroup

  function new(string n, uvm_component p);
    super.new(n,p);
    rcg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    w_ag = write_agent      ::type_id::create("w_ag", this);
    r_ag = read_agent       ::type_id::create("r_ag", this);
    mon  = fifo_monitor     ::type_id::create("mon" , this);
    sb   = fifo_scoreboard  ::type_id::create("sb"  , this);
    chk  = fifo_checker     ::type_id::create("chk" , this);

    // Get the virtual interfaces from the config-db
    if(!uvm_config_db#(virtual write_if)::get(this, "", "w_vif", w_vif)) begin
      `uvm_fatal("NOVIF", "No virtual interface specified for fifo environment")
    end
    if(!uvm_config_db#(virtual read_if)::get(this, "", "r_vif", r_vif)) begin
      `uvm_fatal("NOVIF", "No virtual interface specified for fifo environment")
    end

    // Pass the virtual interfaces to the agents
    uvm_config_db#(virtual write_if)::set(this, "w_ag", "vif", w_vif);
    uvm_config_db#(virtual read_if)::set(this, "r_ag", "vif", r_vif);
  endfunction

  function void connect_phase(uvm_phase phase);
    mon.ap.connect(sb.sb_export);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    clock_periods.sample();
  endfunction
endclass 