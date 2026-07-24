class reset_seq extends uvm_sequence#(riscv_seq_item);
    `uvm_object_utils(reset_seq)

    function new(string name = "reset_seq");
        super.new(name);
    endfunction

    virtual task body();
        req = riscv_seq_item::type_id::create("req");
        start_item(req);
        req.rst = 0; // Active-low reset
        finish_item(req);
        
        #20;
        
        req = riscv_seq_item::type_id::create("req");
        start_item(req);
        req.rst = 1; // Release reset
        finish_item(req);
    endtask
endclass
