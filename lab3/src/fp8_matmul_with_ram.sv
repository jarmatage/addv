//////////////////////////////////////////////////////////////////////////
// Top level with memories
//////////////////////////////////////////////////////////////////////////
module matrix_multiplication(
	input  logic                             clk,
	input  logic                             resetn,
	input  logic                             pe_resetn,
    input  logic [`AWIDTH-1:0]               bram_addr_a_ext,
    output logic [`MAT_MUL_SIZE*`DWIDTH-1:0] bram_rdata_a_ext,
    input  logic [`MAT_MUL_SIZE*`DWIDTH-1:0] bram_wdata_a_ext,
    input  logic [`MASK_WIDTH-1:0]           bram_we_a_ext,
    input  logic [`AWIDTH-1:0]               bram_addr_b_ext,
    output logic [`MAT_MUL_SIZE*`DWIDTH-1:0] bram_rdata_b_ext,
    input  logic [`MAT_MUL_SIZE*`DWIDTH-1:0] bram_wdata_b_ext,
    input  logic [`MASK_WIDTH-1:0]           bram_we_b_ext,
    input  logic [`AWIDTH-1:0]               bram_addr_c_ext,
    output logic [`MAT_MUL_SIZE*`DWIDTH-1:0] bram_rdata_c_ext,
    input  logic [`MAT_MUL_SIZE*`DWIDTH-1:0] bram_wdata_c_ext,
    input  logic [`MASK_WIDTH-1:0]           bram_we_c_ext,

    // APB signals
    input  logic [`REG_ADDRWIDTH-1:0] PADDR,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    input  logic [`REG_DATAWIDTH-1:0] PWDATA,
    output logic [`REG_DATAWIDTH-1:0] PRDATA,
    output logic                      PREADY
    );

	wire [`AWIDTH-1:0] bram_addr_a;
	wire [4*`DWIDTH-1:0] bram_rdata_a;
	wire [4*`DWIDTH-1:0] bram_wdata_a;
	wire [`MASK_WIDTH-1:0] bram_we_a;

	wire [`AWIDTH-1:0] bram_addr_b;
	wire [4*`DWIDTH-1:0] bram_rdata_b;
	wire [4*`DWIDTH-1:0] bram_wdata_b;
	wire [`MASK_WIDTH-1:0] bram_we_b;
	
	wire [`AWIDTH-1:0] bram_addr_c;
	wire [4*`DWIDTH-1:0] bram_rdata_c;
	wire [4*`DWIDTH-1:0] bram_wdata_c;
	wire [`MASK_WIDTH-1:0] bram_we_c;
	
    logic [3:0] state;
  
    //We will utilize port 0 (addr0, d0, we0, q0) to interface with the matmul.
    //Unused ports (port 1 signals addr1, d1, we1, q1) will be connected to the "external" signals i.e. signals that exposed to the external world.
    //Signals that are external end in "_ext".
    //addr is the address of the BRAM, d is the data to be written to the BRAM, we is write enable, and q is the data read from the BRAM. 
    ////////////////////////////////////////////////////////////////
    // RAM matrix A 
    ////////////////////////////////////////////////////////////////
    ram matrix_A (
        .addr0(bram_addr_a), 
        .d0(bram_wdata_a), 
        .we0(bram_we_a), 
        .q0(bram_rdata_a), 
        .addr1(bram_addr_a_ext), 
        .d1(bram_wdata_a_ext), 
        .we1(bram_we_a_ext), 
        .q1(bram_rdata_a_ext), 
        .clk(clk)
    );
    
    ////////////////////////////////////////////////////////////////
    // RAM matrix B 
    ////////////////////////////////////////////////////////////////
    ram matrix_B (
        .addr0(bram_addr_b), 
        .d0(bram_wdata_b), 
        .we0(bram_we_b), 
        .q0(bram_rdata_b), 
        .addr1(bram_addr_b_ext), 
        .d1(bram_wdata_b_ext), 
        .we1(bram_we_b_ext), 
        .q1(bram_rdata_b_ext), 
        .clk(clk)
    );
    
    ////////////////////////////////////////////////////////////////
    // RAM matrix C 
    ////////////////////////////////////////////////////////////////
    ram matrix_C (
        .addr0(bram_addr_c), 
        .d0(bram_wdata_c), 
        .we0(bram_we_c), 
        .q0(bram_rdata_c), 
        .addr1(bram_addr_c_ext), 
        .d1(bram_wdata_c_ext), 
        .we1(bram_we_c_ext), 
        .q1(bram_rdata_c_ext), 
        .clk(clk)
    );


    logic start_mat_mul;
    wire done_mat_mul;
    logic [4:0] flags;
	
    // APB interface
    apb_slave apb_mm (
        .PCLK(clk),
        .PRESETn(resetn),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA), 
        .PREADY(PREADY),
        .start(start_mat_mul),
        .address_mat_a(address_mat_a),
        .address_mat_b(address_mat_b),
        .address_mat_c(address_mat_c),
        .address_stride_a(address_stride_a),
        .address_stride_b(address_stride_b),
        .address_stride_c(address_stride_c),
        .done(done_mat_mul),
        .flags(flags)
    );

    wire c_data_available;

    //Connections for bram c (output matrix)
    //bram_addr_c -> connected to u_matmul_4x4 block
    //bram_rdata_c -> not used
    //bram_wdata_c -> connected to u_matmul_4x4 block
    //bram_we_c -> set to 1 when c_data is available

    assign bram_we_c = (c_data_available) ? 4'b1111 : 4'b0000;  

    //Connections for bram a (first input matrix)
    //bram_addr_a -> connected to u_matmul_4x4
    //bram_rdata_a -> connected to u_matmul_4x4
    //bram_wdata_a -> hardcoded to 0 (this block only reads from bram a)
    //bram_we_a -> hardcoded to 0 (this block only reads from bram a)

    assign bram_wdata_a = 32'b0;
    assign bram_we_a = 4'b0;
  
    //Connections for bram b (second input matrix)
    //bram_addr_b -> connected to u_matmul_4x4
    //bram_rdata_b -> connected to u_matmul_4x4
    //bram_wdata_b -> hardcoded to 0 (this block only reads from bram b)
    //bram_we_b -> hardcoded to 0 (this block only reads from bram b)

    assign bram_wdata_b = 32'b0;
    assign bram_we_b = 4'b0;
  
    //NC (not connected) wires 
    wire [`BB_MAT_MUL_SIZE*`DWIDTH-1:0] a_data_out_NC;
    wire [`BB_MAT_MUL_SIZE*`DWIDTH-1:0] b_data_out_NC;
    wire [`BB_MAT_MUL_SIZE*`DWIDTH-1:0] a_data_in_NC;
    wire [`BB_MAT_MUL_SIZE*`DWIDTH-1:0] b_data_in_NC;

    wire reset;
    assign reset = ~resetn;
    assign pe_reset = ~pe_resetn;

    //matmul instance
    matmul_4x4_systolic u_matmul_4x4(
        .clk(clk),
        .reset(reset),
        .pe_reset(pe_reset),
        .flags(flags),
        .start_mat_mul(start_mat_mul),
        .done_mat_mul(done_mat_mul),
        .address_mat_a(address_mat_a),
        .address_mat_b(address_mat_b),
        .address_mat_c(address_mat_c),
        .address_stride_a(address_stride_a),
        .address_stride_b(address_stride_b),
        .address_stride_c(address_stride_c),
        .a_data(bram_rdata_a),
        .b_data(bram_rdata_b),
        .a_data_in(a_data_in_NC),
        .b_data_in(b_data_in_NC),
        .c_data_in({`BB_MAT_MUL_SIZE*`DWIDTH{1'b0}}),
        .c_data_out(bram_wdata_c),
        .a_data_out(a_data_out_NC),
        .b_data_out(b_data_out_NC),
        .a_addr(bram_addr_a),
        .b_addr(bram_addr_b),
        .c_addr(bram_addr_c),
        .c_data_available(c_data_available),
        .validity_mask_a_rows(4'b1111),
        .validity_mask_a_cols_b_rows(4'b1111),
        .validity_mask_b_cols(4'b1111),
        .final_mat_mul_size(8'd4),
        .a_loc(8'd0),
        .b_loc(8'd0)
    );

endmodule
