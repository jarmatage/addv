class fifo_scoreboard extends uvm_component;
  `uvm_component_utils(fifo_scoreboard)

  uvm_analysis_export #(fifo_seq_item) sb_export;
  uvm_tlm_analysis_fifo #(fifo_seq_item) fifo;

  fifo_seq_item exp_q[$];

  function new(string name , uvm_component parent);
    super.new(name,parent);
    sb_export = new("sb_export", this);
    fifo      = new("fifo", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    sb_export.connect(fifo.analysis_export); // passive – monitor writes, we pull
  endfunction

  task run_phase(uvm_phase phase);
    fifo_seq_item txn;
    forever begin
      fifo.get(txn);
      if (txn.is_write)
        exp_q.push_back(txn);
      else begin
        if (exp_q.size() == 0)
          `uvm_error("SCOREBOARD","Read with no matching write")
        else begin
          fifo_seq_item exp = exp_q.pop_front();
          if (exp.data !== txn.data)
            `uvm_error("SCOREBOARD", $sformatf("Data mismatch exp=%0d got=%0d", exp.data, txn.data))
        end
      end
    end
  endtask
endclass 