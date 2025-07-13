class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)

  write_agent       w_ag;
  read_agent        r_ag;
  fifo_monitor      mon;
  fifo_scoreboard   sb;
  fifo_checker      chk;

  int WR_PER_RD;
  covergroup rcg;
    cp_ratio: coverpoint WR_PER_RD {
      bins syn      = {1};
      bins fast_wr  = {2,3,4};
      bins fast_rd  = {0};
    }
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

    if(!uvm_config_db#(int)::get(this,"","WR_PER_RD", WR_PER_RD)) WR_PER_RD = 1;
  endfunction

  function void connect_phase(uvm_phase phase);
    mon.ap.connect(sb.sb_export);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    rcg.sample();
  endfunction
endclass 