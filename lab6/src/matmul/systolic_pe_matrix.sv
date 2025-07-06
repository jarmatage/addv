//////////////////////////////////////////////////////////////////////////
// Systolically connected PEs
//////////////////////////////////////////////////////////////////////////
module systolic_pe_matrix(
    input  logic                             clk,
    input  logic                             reset,
    input  logic                             pe_reset,
    input  logic                             is_fp8,
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

	processing_element pe00(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags00), .in_a(a0),      .in_b(b0), .out_a(a00to01), .out_b(b00to10), .out_c(matrixC00));
	processing_element pe01(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags01), .in_a(a00to01), .in_b(b1), .out_a(a01to02), .out_b(b01to11), .out_c(matrixC01));
	processing_element pe02(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags02), .in_a(a01to02), .in_b(b2), .out_a(a02to03), .out_b(b02to12), .out_c(matrixC02));
	processing_element pe03(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags03), .in_a(a02to03), .in_b(b3), .out_a(a03to04), .out_b(b03to13), .out_c(matrixC03));

	processing_element pe10(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags10), .in_a(a1),      .in_b(b00to10), .out_a(a10to11), .out_b(b10to20), .out_c(matrixC10));
	processing_element pe11(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags11), .in_a(a10to11), .in_b(b01to11), .out_a(a11to12), .out_b(b11to21), .out_c(matrixC11));
	processing_element pe12(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags12), .in_a(a11to12), .in_b(b02to12), .out_a(a12to13), .out_b(b12to22), .out_c(matrixC12));
	processing_element pe13(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags13), .in_a(a12to13), .in_b(b03to13), .out_a(a13to14), .out_b(b13to23), .out_c(matrixC13));

	processing_element pe20(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags20), .in_a(a2),      .in_b(b10to20), .out_a(a20to21), .out_b(b20to30), .out_c(matrixC20));
	processing_element pe21(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags21), .in_a(a20to21), .in_b(b11to21), .out_a(a21to22), .out_b(b21to31), .out_c(matrixC21));
	processing_element pe22(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags22), .in_a(a21to22), .in_b(b12to22), .out_a(a22to23), .out_b(b22to32), .out_c(matrixC22));
	processing_element pe23(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags23), .in_a(a22to23), .in_b(b13to23), .out_a(a23to24), .out_b(b23to33), .out_c(matrixC23));

	processing_element pe30(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags30), .in_a(a3),      .in_b(b20to30), .out_a(a30to31), .out_b(b30to40), .out_c(matrixC30));
	processing_element pe31(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags31), .in_a(a30to31), .in_b(b21to31), .out_a(a31to32), .out_b(b31to41), .out_c(matrixC31));
	processing_element pe32(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags32), .in_a(a31to32), .in_b(b22to32), .out_a(a32to33), .out_b(b32to42), .out_c(matrixC32));
	processing_element pe33(.reset(effective_rst), .clk(clk), .is_fp8(is_fp8), .flags(flags33), .in_a(a32to33), .in_b(b23to33), .out_a(a33to34), .out_b(b33to43), .out_c(matrixC33));

    assign a_data_out = {a33to34,a23to24,a13to14,a03to04};
    assign b_data_out = {b33to43,b32to42,b31to41,b30to40};

    assign flags = flags00 | flags01 | flags02 | flags03 |
                   flags10 | flags11 | flags12 | flags13 |
                   flags20 | flags21 | flags22 | flags23 |
                   flags30 | flags31 | flags32 | flags33;

endmodule
