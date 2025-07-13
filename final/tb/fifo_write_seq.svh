class fifo_write_seq extends uvm_sequence #(fifo_seq_item);
  rand int unsigned burst_len;
  constraint c1 { burst_len inside {[1:32]}; }

  `uvm_object_utils(fifo_write_seq)

  task body();
    fifo_seq_item item;
    repeat (burst_len) begin
      `uvm_create(item)
      item.is_write = 1;
      assert(item.randomize() with { data dist {0  :=1, 255 :=1, [1:254]:=98}; });
      `uvm_send(item)
    end
  endtask
endclass 