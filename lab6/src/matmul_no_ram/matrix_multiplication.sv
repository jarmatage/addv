//////////////////////////////////////////////////////////////////////////
// Top level with memories
//////////////////////////////////////////////////////////////////////////
module matrix_multiplication(
    ram_read_if ram_a,
    ram_read_if ram_b,
    ram_write_if ram_c,
    apb_if apb
    );


    logic [`AWIDTH-1:0] address_mat_a, address_mat_b, address_mat_c;
    logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_a, address_stride_b, address_stride_c;

    logic start_mat_mul;
    wire done_mat_mul;
    logic [4:0] flags;
    logic is_fp8;
	
    // APB interface
    apb_slave apb_mm (
        .apb(apb),
        .start(start_mat_mul),
        .is_fp8(is_fp8),
        .address_mat_a(address_mat_a),
        .address_mat_b(address_mat_b),
        .address_mat_c(address_mat_c),
        .address_stride_a(address_stride_a),
        .address_stride_b(address_stride_b),
        .address_stride_c(address_stride_c),
        .done(done_mat_mul),
        .flags(flags)
    );

  
    //NC (not connected) wires 
    wire [`BB_MAT_MUL_SIZE*`DWIDTH-1:0] a_data_out_NC;
    wire [`BB_MAT_MUL_SIZE*`DWIDTH-1:0] b_data_out_NC;
    wire [`BB_MAT_MUL_SIZE*`DWIDTH-1:0] a_data_in_NC;
    wire [`BB_MAT_MUL_SIZE*`DWIDTH-1:0] b_data_in_NC;

    wire reset;
    assign reset = ~apb.PRESET_N;

    //matmul instance
    matmul_4x4_systolic u_matmul_4x4(
        .a_mem_access(ram_a.en),
        .b_mem_access(ram_b.en),
        .clk(apb.PCLK),
        .reset(reset),
        .pe_reset(reset),
        .is_fp8(is_fp8),
        .flags(flags),
        .start_mat_mul(start_mat_mul),
        .done_mat_mul(done_mat_mul),
        .address_mat_a(address_mat_a),
        .address_mat_b(address_mat_b),
        .address_mat_c(address_mat_c),
        .address_stride_a(address_stride_a),
        .address_stride_b(address_stride_b),
        .address_stride_c(address_stride_c),
        .a_data(ram_a.data),
        .b_data(ram_b.data),
        .a_data_in(a_data_in_NC),
        .b_data_in(b_data_in_NC),
        .c_data_in({`BB_MAT_MUL_SIZE*`DWIDTH{1'b0}}),
        .c_data_out(ram_c.data),
        .a_data_out(a_data_out_NC),
        .b_data_out(b_data_out_NC),
        .a_addr(ram_a.addr),
        .b_addr(ram_b.addr),
        .c_addr(ram_c.addr),
        .c_data_available(ram_c.en),
        .validity_mask_a_rows(4'b1111),
        .validity_mask_a_cols_b_rows(4'b1111),
        .validity_mask_b_cols(4'b1111),
        .final_mat_mul_size(8'd4),
        .a_loc(8'd0),
        .b_loc(8'd0)
    );

endmodule
