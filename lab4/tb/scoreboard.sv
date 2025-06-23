class scoreboard;

    mailbox #(transaction) txn_mail;
    transaction txn;
    transaction expected;
    transaction q[$];


    function new();
    endfunction 


    task run();
        forever begin
            txn_mail.get(txn);
            if (txn.is_write)
                q.push_back(txn);   // Store the write transaction in the queue
            else
                check_read();    // Check the read transaction against the queue
        end
    endtask


    function void check_read();
        // Check if the read transaction matches the expected write transaction
        if (q.size() == 0)
            $error("[%0t] ERROR: read transaction received with no matching write transaction", $time);
        else begin
            expected = q.pop_front();
            if (expected.data != txn.data)
                $error("[%0t] ERROR: read data '%0d' does not match expected data '%0d'", $time, txn.data, expected.data);
            else
                $display("[%0t] SCOREBOARD: read data '%0d' matches expected data", $time, txn.data);
        end
    endfunction

endclass
