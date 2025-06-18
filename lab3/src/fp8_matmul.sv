//////////////////////////////////////////////////////////////////////////
// 4x4 Systolic Matrix Multiplier
//////////////////////////////////////////////////////////////////////////
module matmul_4x4_systolic (
    input  logic                             clk,
    input  logic                             reset,
    input  logic                             pe_reset,
    output logic [4:0]                       flags,
    input  logic                             start_mat_mul,
    output logic                             done_mat_mul,
    input  logic [`AWIDTH-1:0]               address_mat_a,
    input  logic [`AWIDTH-1:0]               address_mat_b,
    input  logic [`AWIDTH-1:0]               address_mat_c,
    input  logic [`ADDR_STRIDE_WIDTH-1:0]    address_stride_a,
    input  logic [`ADDR_STRIDE_WIDTH-1:0]    address_stride_b,
    input  logic [`ADDR_STRIDE_WIDTH-1:0]    address_stride_c,
    input  logic [`MAT_MUL_SIZE*`DWIDTH-1:0] a_data,
    input  logic [`MAT_MUL_SIZE*`DWIDTH-1:0] b_data,
    input  logic [`MAT_MUL_SIZE*`DWIDTH-1:0] a_data_in,
    input  logic [`MAT_MUL_SIZE*`DWIDTH-1:0] b_data_in,
    input  logic [`MAT_MUL_SIZE*`DWIDTH-1:0] c_data_in,
    output logic [`MAT_MUL_SIZE*`DWIDTH-1:0] c_data_out,
    output logic [`MAT_MUL_SIZE*`DWIDTH-1:0] a_data_out,
    output logic [`MAT_MUL_SIZE*`DWIDTH-1:0] b_data_out,
    output logic [`AWIDTH-1:0]               a_addr,
    output logic [`AWIDTH-1:0]               b_addr,
    output logic [`AWIDTH-1:0]               c_addr,
    output logic                             c_data_available,
    input  logic [`MASK_WIDTH-1:0]           validity_mask_a_rows,
    input  logic [`MASK_WIDTH-1:0]           validity_mask_a_cols_b_rows,
    input  logic [`MASK_WIDTH-1:0]           validity_mask_b_cols,
    input  logic [7:0]                       final_mat_mul_size,
    input  logic [7:0]                       a_loc,
    input  logic [7:0]                       b_loc
    );

    //////////////////////////////////////////////////////////////////////////
    // Logic for clock counting and when to assert done
    //////////////////////////////////////////////////////////////////////////

    //This is 7 bits because the expectation is that clock count will be pretty
    //small. For large matmuls, this will need to increased to have more bits.
    //In general, a systolic multiplier takes f(N)+P cycles, where N is the size 
    //of the matmul and P is the number of pipleine stages in the MAC block.
    //f(N) is a function describing the number of cycles taken to perform matmul
    //with a systolic array strcture.
    logic [7:0] clk_cnt;
    
    //Finding out number of cycles to assert matmul done.
    wire [7:0] clk_cnt_for_done;
    wire [7:0] cycles_for_matmul; 
        
    assign cycles_for_matmul = 8'd14;
    assign clk_cnt_for_done = (cycles_for_matmul + `NUM_CYCLES_IN_MAC) ;  


    always_ff @(posedge clk) begin
        if (reset || ~start_mat_mul) begin
            clk_cnt <= 0;
            done_mat_mul <= 0;
        end else if (clk_cnt == clk_cnt_for_done) begin
            done_mat_mul <= 1;
            clk_cnt <= clk_cnt + 1;
        end else if (done_mat_mul == 0) 
            clk_cnt <= clk_cnt + 1;   
        else begin
            done_mat_mul <= 0;
            clk_cnt <= clk_cnt + 1;
        end
    end


    wire [`DWIDTH-1:0] a0_data;
    wire [`DWIDTH-1:0] a1_data;
    wire [`DWIDTH-1:0] a2_data;
    wire [`DWIDTH-1:0] a3_data;
    wire [`DWIDTH-1:0] b0_data;
    wire [`DWIDTH-1:0] b1_data;
    wire [`DWIDTH-1:0] b2_data;
    wire [`DWIDTH-1:0] b3_data;
    wire [`DWIDTH-1:0] a1_data_delayed_1;
    wire [`DWIDTH-1:0] a2_data_delayed_1;
    wire [`DWIDTH-1:0] a2_data_delayed_2;
    wire [`DWIDTH-1:0] a3_data_delayed_1;
    wire [`DWIDTH-1:0] a3_data_delayed_2;
    wire [`DWIDTH-1:0] a3_data_delayed_3;
    wire [`DWIDTH-1:0] b1_data_delayed_1;
    wire [`DWIDTH-1:0] b2_data_delayed_1;
    wire [`DWIDTH-1:0] b2_data_delayed_2;
    wire [`DWIDTH-1:0] b3_data_delayed_1;
    wire [`DWIDTH-1:0] b3_data_delayed_2;
    wire [`DWIDTH-1:0] b3_data_delayed_3;
    
    //////////////////////////////////////////////////////////////////////////
    // Instantiation of systolic data setup
    //////////////////////////////////////////////////////////////////////////
    systolic_data_setup u_systolic_data_setup(
        .clk(clk),
        .reset(reset),
        .start_mat_mul(start_mat_mul),
        .a_addr(a_addr),
        .b_addr(b_addr),
        .address_mat_a(address_mat_a),
        .address_mat_b(address_mat_b),
        .address_stride_a(address_stride_a),
        .address_stride_b(address_stride_b),
        .a_data(a_data),
        .b_data(b_data),
        .clk_cnt(clk_cnt),
        .a0_data(a0_data),
        .a1_data_delayed_1(a1_data_delayed_1),
        .a2_data_delayed_2(a2_data_delayed_2),
        .a3_data_delayed_3(a3_data_delayed_3),
        .b0_data(b0_data),
        .b1_data_delayed_1(b1_data_delayed_1),
        .b2_data_delayed_2(b2_data_delayed_2),
        .b3_data_delayed_3(b3_data_delayed_3),
        .validity_mask_a_rows(validity_mask_a_rows),
        .validity_mask_a_cols_b_rows(validity_mask_a_cols_b_rows),
        .validity_mask_b_cols(validity_mask_b_cols),
        .final_mat_mul_size(final_mat_mul_size),
        .a_loc(a_loc),
        .b_loc(b_loc)
    );


    //////////////////////////////////////////////////////////////////////////
    // Logic to mux data_in coming from neighboring matmuls
    //////////////////////////////////////////////////////////////////////////
    wire [`DWIDTH-1:0] a0;
    wire [`DWIDTH-1:0] a1;
    wire [`DWIDTH-1:0] a2;
    wire [`DWIDTH-1:0] a3;
    wire [`DWIDTH-1:0] b0;
    wire [`DWIDTH-1:0] b1;
    wire [`DWIDTH-1:0] b2;
    wire [`DWIDTH-1:0] b3;
    
    wire [`DWIDTH-1:0] a0_data_in;
    wire [`DWIDTH-1:0] a1_data_in;
    wire [`DWIDTH-1:0] a2_data_in;
    wire [`DWIDTH-1:0] a3_data_in;
    assign a0_data_in = a_data_in[`DWIDTH-1:0];
    assign a1_data_in = a_data_in[2*`DWIDTH-1:`DWIDTH];
    assign a2_data_in = a_data_in[3*`DWIDTH-1:2*`DWIDTH];
    assign a3_data_in = a_data_in[4*`DWIDTH-1:3*`DWIDTH];
    
    wire [`DWIDTH-1:0] b0_data_in;
    wire [`DWIDTH-1:0] b1_data_in;
    wire [`DWIDTH-1:0] b2_data_in;
    wire [`DWIDTH-1:0] b3_data_in;
    assign b0_data_in = b_data_in[`DWIDTH-1:0];
    assign b1_data_in = b_data_in[2*`DWIDTH-1:`DWIDTH];
    assign b2_data_in = b_data_in[3*`DWIDTH-1:2*`DWIDTH];
    assign b3_data_in = b_data_in[4*`DWIDTH-1:3*`DWIDTH];
    
    //If b_loc is 0, that means this matmul block is on the top-row of the
    //final large matmul. In that case, b will take inputs from mem.
    //If b_loc != 0, that means this matmul block is not on the top-row of the
    //final large matmul. In that case, b will take inputs from the matmul on top
    //of this one.
    assign a0 = (b_loc==0) ? a0_data           : a0_data_in;
    assign a1 = (b_loc==0) ? a1_data_delayed_1 : a1_data_in;
    assign a2 = (b_loc==0) ? a2_data_delayed_2 : a2_data_in;
    assign a3 = (b_loc==0) ? a3_data_delayed_3 : a3_data_in;

    //If a_loc is 0, that means this matmul block is on the left-col of the
    //final large matmul. In that case, a will take inputs from mem.
    //If a_loc != 0, that means this matmul block is not on the left-col of the
    //final large matmul. In that case, a will take inputs from the matmul on left
    //of this one.
    assign b0 = (a_loc==0) ? b0_data           : b0_data_in;
    assign b1 = (a_loc==0) ? b1_data_delayed_1 : b1_data_in;
    assign b2 = (a_loc==0) ? b2_data_delayed_2 : b2_data_in;
    assign b3 = (a_loc==0) ? b3_data_delayed_3 : b3_data_in;
    

    wire [`DWIDTH-1:0] matrixC00;
    wire [`DWIDTH-1:0] matrixC01;
    wire [`DWIDTH-1:0] matrixC02;
    wire [`DWIDTH-1:0] matrixC03;
    wire [`DWIDTH-1:0] matrixC10;
    wire [`DWIDTH-1:0] matrixC11;
    wire [`DWIDTH-1:0] matrixC12;
    wire [`DWIDTH-1:0] matrixC13;
    wire [`DWIDTH-1:0] matrixC20;
    wire [`DWIDTH-1:0] matrixC21;
    wire [`DWIDTH-1:0] matrixC22;
    wire [`DWIDTH-1:0] matrixC23;
    wire [`DWIDTH-1:0] matrixC30;
    wire [`DWIDTH-1:0] matrixC31;
    wire [`DWIDTH-1:0] matrixC32;
    wire [`DWIDTH-1:0] matrixC33;
    

    //////////////////////////////////////////////////////////////////////////
    // Instantiation of the output logic
    //////////////////////////////////////////////////////////////////////////
    output_logic u_output_logic(
        .clk(clk),
        .reset(reset),
        .start_mat_mul(start_mat_mul),
        .done_mat_mul(done_mat_mul),
        .address_mat_c(address_mat_c),
        .address_stride_c(address_stride_c),
        .c_data_out(c_data_out),
        .c_data_in(c_data_in),
        .c_addr(c_addr),
        .c_data_available(c_data_available),
        .clk_cnt(clk_cnt),
        .row_latch_en(row_latch_en),
        .final_mat_mul_size(final_mat_mul_size),
        .matrixC00(matrixC00),
        .matrixC01(matrixC01),
        .matrixC02(matrixC02),
        .matrixC03(matrixC03),
        .matrixC10(matrixC10),
        .matrixC11(matrixC11),
        .matrixC12(matrixC12),
        .matrixC13(matrixC13),
        .matrixC20(matrixC20),
        .matrixC21(matrixC21),
        .matrixC22(matrixC22),
        .matrixC23(matrixC23),
        .matrixC30(matrixC30),
        .matrixC31(matrixC31),
        .matrixC32(matrixC32),
        .matrixC33(matrixC33)
    );

    //////////////////////////////////////////////////////////////////////////
    // Instantiations of the actual PEs
    //////////////////////////////////////////////////////////////////////////
    systolic_pe_matrix u_systolic_pe_matrix(
        .reset(reset),
        .clk(clk),
        .pe_reset(pe_reset),
        .flags(flags),
        .start_mat_mul(start_mat_mul),
        .a0(a0), 
        .a1(a1), 
        .a2(a2), 
        .a3(a3),
        .b0(b0), 
        .b1(b1), 
        .b2(b2), 
        .b3(b3),
        .matrixC00(matrixC00),
        .matrixC01(matrixC01),
        .matrixC02(matrixC02),
        .matrixC03(matrixC03),
        .matrixC10(matrixC10),
        .matrixC11(matrixC11),
        .matrixC12(matrixC12),
        .matrixC13(matrixC13),
        .matrixC20(matrixC20),
        .matrixC21(matrixC21),
        .matrixC22(matrixC22),
        .matrixC23(matrixC23),
        .matrixC30(matrixC30),
        .matrixC31(matrixC31),
        .matrixC32(matrixC32),
        .matrixC33(matrixC33),
        .a_data_out(a_data_out),
        .b_data_out(b_data_out)
    );

endmodule

//////////////////////////////////////////////////////////////////////////
// Systolically connected PEs
//////////////////////////////////////////////////////////////////////////
module systolic_pe_matrix(
    input  logic                             clk,
    input  logic                             reset,
    input  logic                             pe_reset,
    output logic [4:0]                       flags,
    input  logic                             start_mat_mul,
    input  logic [`DWIDTH-1:0]               a0, 
    input  logic [`DWIDTH-1:0]               a1, 
    input  logic [`DWIDTH-1:0]               a2, 
    input  logic [`DWIDTH-1:0]               a3,
    input  logic [`DWIDTH-1:0]               b0, 
    input  logic [`DWIDTH-1:0]               b1, 
    input  logic [`DWIDTH-1:0]               b2, 
    input  logic [`DWIDTH-1:0]               b3,
    output logic [`DWIDTH-1:0]               matrixC00,
    output logic [`DWIDTH-1:0]               matrixC01,
    output logic [`DWIDTH-1:0]               matrixC02,
    output logic [`DWIDTH-1:0]               matrixC03,
    output logic [`DWIDTH-1:0]               matrixC10,
    output logic [`DWIDTH-1:0]               matrixC11,
    output logic [`DWIDTH-1:0]               matrixC12,
    output logic [`DWIDTH-1:0]               matrixC13,
    output logic [`DWIDTH-1:0]               matrixC20,
    output logic [`DWIDTH-1:0]               matrixC21,
    output logic [`DWIDTH-1:0]               matrixC22,
    output logic [`DWIDTH-1:0]               matrixC23,
    output logic [`DWIDTH-1:0]               matrixC30,
    output logic [`DWIDTH-1:0]               matrixC31,
    output logic [`DWIDTH-1:0]               matrixC32,
    output logic [`DWIDTH-1:0]               matrixC33,
    output logic [`MAT_MUL_SIZE*`DWIDTH-1:0] a_data_out,
    output logic [`MAT_MUL_SIZE*`DWIDTH-1:0] b_data_out
    );

    wire [`DWIDTH-1:0] a00to01, a01to02, a02to03, a03to04;
    wire [`DWIDTH-1:0] a10to11, a11to12, a12to13, a13to14;
    wire [`DWIDTH-1:0] a20to21, a21to22, a22to23, a23to24;
    wire [`DWIDTH-1:0] a30to31, a31to32, a32to33, a33to34;
    
    wire [`DWIDTH-1:0] b00to10, b10to20, b20to30, b30to40; 
    wire [`DWIDTH-1:0] b01to11, b11to21, b21to31, b31to41;
    wire [`DWIDTH-1:0] b02to12, b12to22, b22to32, b32to42;
    wire [`DWIDTH-1:0] b03to13, b13to23, b23to33, b33to43;

    wire [4:0] flags00, flags01, flags02, flags03;
    wire [4:0] flags10, flags11, flags12, flags13;
    wire [4:0] flags20, flags21, flags22, flags23;
    wire [4:0] flags30, flags31, flags32, flags33;
    
    wire effective_rst;
    assign effective_rst = reset | pe_reset;
    
    
    //There are a total of 16 PEs arranged in a mesh structure like in the lecture slides. 	
	//Each PE has a number. PE00 is the top-left PE. PE01 is the second PE on the first row. 
	//PE10 is the first PE on the second row. PE33 is the bottom right PE.	
    //Signals a0, a1, a2, a3 are coming from matrix A. They need to be be connected to the first column of PEs.
	//b0, b1, b2, b3 signals are coming from matrix B. They need to be connected to the first row of the PEs.
	//Signals axytozw go from PExy to PEzw horizontally.
	//Signals bxytozw go from PExy to PEzw vertically.
	//Signals matrixCxx are the output results from each PE.
	//Reset and clock signals of all PEs are the same.	

	processing_element pe00(.reset(effective_rst), .clk(clk), .flags(flags00), .in_a(a0),      .in_b(b0), .out_a(a00to01), .out_b(b00to10), .out_c(matrixC00));
	processing_element pe01(.reset(effective_rst), .clk(clk), .flags(flags01), .in_a(a00to01), .in_b(b1), .out_a(a01to02), .out_b(b01to11), .out_c(matrixC01));
	processing_element pe02(.reset(effective_rst), .clk(clk), .flags(flags02), .in_a(a01to02), .in_b(b2), .out_a(a02to03), .out_b(b02to12), .out_c(matrixC02));
	processing_element pe03(.reset(effective_rst), .clk(clk), .flags(flags03), .in_a(a02to03), .in_b(b3), .out_a(a03to04), .out_b(b03to13), .out_c(matrixC03));

	processing_element pe10(.reset(effective_rst), .clk(clk), .flags(flags10), .in_a(a1),      .in_b(b00to10), .out_a(a10to11), .out_b(b10to20), .out_c(matrixC10));
	processing_element pe11(.reset(effective_rst), .clk(clk), .flags(flags11), .in_a(a10to11), .in_b(b01to11), .out_a(a11to12), .out_b(b11to21), .out_c(matrixC11));
	processing_element pe12(.reset(effective_rst), .clk(clk), .flags(flags12), .in_a(a11to12), .in_b(b02to12), .out_a(a12to13), .out_b(b12to22), .out_c(matrixC12));
	processing_element pe13(.reset(effective_rst), .clk(clk), .flags(flags13), .in_a(a12to13), .in_b(b03to13), .out_a(a13to14), .out_b(b13to23), .out_c(matrixC13));

	processing_element pe20(.reset(effective_rst), .clk(clk), .flags(flags20), .in_a(a2),      .in_b(b10to20), .out_a(a20to21), .out_b(b20to30), .out_c(matrixC20));
	processing_element pe21(.reset(effective_rst), .clk(clk), .flags(flags21), .in_a(a20to21), .in_b(b11to21), .out_a(a21to22), .out_b(b21to31), .out_c(matrixC21));
	processing_element pe22(.reset(effective_rst), .clk(clk), .flags(flags22), .in_a(a21to22), .in_b(b12to22), .out_a(a22to23), .out_b(b22to32), .out_c(matrixC22));
	processing_element pe23(.reset(effective_rst), .clk(clk), .flags(flags23), .in_a(a22to23), .in_b(b13to23), .out_a(a23to24), .out_b(b23to33), .out_c(matrixC23));

	processing_element pe30(.reset(effective_rst), .clk(clk), .flags(flags30), .in_a(a3),      .in_b(b20to30), .out_a(a30to31), .out_b(b30to40), .out_c(matrixC30));
	processing_element pe31(.reset(effective_rst), .clk(clk), .flags(flags31), .in_a(a30to31), .in_b(b21to31), .out_a(a31to32), .out_b(b31to41), .out_c(matrixC31));
	processing_element pe32(.reset(effective_rst), .clk(clk), .flags(flags32), .in_a(a31to32), .in_b(b22to32), .out_a(a32to33), .out_b(b32to42), .out_c(matrixC32));
	processing_element pe33(.reset(effective_rst), .clk(clk), .flags(flags33), .in_a(a32to33), .in_b(b23to33), .out_a(a33to34), .out_b(b33to43), .out_c(matrixC33));

    assign a_data_out = {a33to34,a23to24,a13to14,a03to04};
    assign b_data_out = {b33to43,b32to42,b31to41,b30to40};

    assign flags = flags00 | flags01 | flags02 | flags03 |
                   flags10 | flags11 | flags12 | flags13 |
                   flags20 | flags21 | flags22 | flags23 |
                   flags30 | flags31 | flags32 | flags33;

endmodule

//////////////////////////////////////////////////////////////////////////
// Processing element (PE)
//////////////////////////////////////////////////////////////////////////
module processing_element(
    input  logic                reset,
    input  logic                clk,
    output logic [4:0]          flags,
    input  logic [`DWIDTH-1:0]  in_a,
    input  logic [`DWIDTH-1:0]  in_b,
    output logic [`DWIDTH-1:0]  out_a,
    output logic [`DWIDTH-1:0]  out_b,
    output logic [`DWIDTH-1:0]  out_c
    );

    logic [`DWIDTH-1:0] out_mac;

    assign out_c = out_mac;
    
    fp8_mac u_mac(.a(in_a), .b(in_b), .out(out_mac), .reset(reset), .clk(clk), .flags(flags));

    always_ff @(posedge clk) begin
        if (reset) begin
            out_a <= 0;
            out_b <= 0;
        end else begin  
            out_a <= in_a;
            out_b <= in_b;
        end
    end

endmodule
