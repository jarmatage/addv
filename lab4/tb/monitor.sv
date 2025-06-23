class monitor;

    virtual write_if vwrite;
    virtual read_if  vread;
    mailbox #(transaction) txn_mail;
    transaction txn;
    int log_level = 0; // 0 = off, 1 = brief, 2 = verbose


    function new(virtual write_if vwrite, virtual read_if vread, mailbox txn_mail);
        this.vwrite = vwrite;
        this.vread = vread;
        this.txn_mail = txn_mail;

        // Get plusarg if it was passed on the command line
        void'($value$plusargs("log_level=%0d", log_level));
    endfunction


    task run();
        fork
            monitor_write();
            monitor_read();
        join
    endtask


    task monitor_write();
        forever begin
            @(posedge vwrite.clk);
            if (vwrite.en && !vwrite.full) begin
                txn = new();
                txn.is_write = 1'b1;
                txn.data = vwrite.data;
                txn.empty = vread.empty;
                txn.almost_empty = vread.almost_empty;
                txn.full = vwrite.full;
                txn.almost_full = vwrite.almost_full;
                txn.timestamp = $time;
                txn.print(log_level);
                txn_mail.put(txn);
            end
        end
    endtask


    task monitor_read();
        forever begin
            @(posedge vread.clk);
            if (vread.en && !vread.empty) begin
                txn = new();
                txn.is_write = 1'b1;
                txn.data = vread.data;
                txn.empty = vread.empty;
                txn.almost_empty = vread.almost_empty;
                txn.full = vwrite.full;
                txn.almost_full = vwrite.almost_full;
                txn.timestamp = $time;
                txn.print(log_level);
                txn_mail.put(txn);
            end
        end
    endtask

endclass
