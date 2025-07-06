module output_logic (
    input logic clk,
    input logic reset,
    input logic start_mat_mul,
    input logic done_mat_mul,
    input logic [`AWIDTH-1:0] address_mat_c,
    input logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_c,
    input logic [`MAT_MUL_SIZE*`DWIDTH-1:0] c_data_in,
    output logic [`MAT_MUL_SIZE*`DWIDTH-1:0] c_data_out,
    output logic [`AWIDTH-1:0] c_addr,
    output logic c_data_available,
    input logic [7:0] clk_cnt,
    output logic row_latch_en,
    input logic [7:0] final_mat_mul_size,
    input logic [`DWIDTH-1:0] matrixC00,
    input logic [`DWIDTH-1:0] matrixC01,
    input logic [`DWIDTH-1:0] matrixC02,
    input logic [`DWIDTH-1:0] matrixC03,
    input logic [`DWIDTH-1:0] matrixC10,
    input logic [`DWIDTH-1:0] matrixC11,
    input logic [`DWIDTH-1:0] matrixC12,
    input logic [`DWIDTH-1:0] matrixC13,
    input logic [`DWIDTH-1:0] matrixC20,
    input logic [`DWIDTH-1:0] matrixC21,
    input logic [`DWIDTH-1:0] matrixC22,
    input logic [`DWIDTH-1:0] matrixC23,
    input logic [`DWIDTH-1:0] matrixC30,
    input logic [`DWIDTH-1:0] matrixC31,
    input logic [`DWIDTH-1:0] matrixC32,
    input logic [`DWIDTH-1:0] matrixC33
    );

    //////////////////////////////////////////////////////////////////////////
    // Logic to capture matrix C data from the PEs and shift it out
    //////////////////////////////////////////////////////////////////////////
    assign row_latch_en = ((clk_cnt == ((final_mat_mul_size<<2) - final_mat_mul_size -1 + `NUM_CYCLES_IN_MAC)));
    
    logic start_capturing_c_data;
    integer counter;
    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] c_data_out_1;
    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] c_data_out_2;
    logic [`MAT_MUL_SIZE*`DWIDTH-1:0] c_data_out_3;

    wire [`MAT_MUL_SIZE*`DWIDTH-1:0] col0;
    wire [`MAT_MUL_SIZE*`DWIDTH-1:0] col1;
    wire [`MAT_MUL_SIZE*`DWIDTH-1:0] col2;
    wire [`MAT_MUL_SIZE*`DWIDTH-1:0] col3;
    assign col0 = {matrixC30, matrixC20, matrixC10, matrixC00};
    assign col1 = {matrixC31, matrixC21, matrixC11, matrixC01};
    assign col2 = {matrixC32, matrixC22, matrixC12, matrixC02};
    assign col3 = {matrixC33, matrixC23, matrixC13, matrixC03};
    
    //If save_output_to_accum is asserted, that means we are not intending to shift
    //out the outputs, because the outputs are still partial sums. 
    wire condition_to_start_shifting_output;
    assign condition_to_start_shifting_output = row_latch_en;
    
    //For larger matmuls, this logic will have more entries in the case statement
    always_ff @(posedge clk) begin
        if (reset | ~start_mat_mul) begin
            start_capturing_c_data <= 1'b0;
            c_data_available <= 1'b0;
            c_addr <= address_mat_c - address_stride_c;
            c_data_out <= 0;
            counter <= 0;
            c_data_out_1 <= 0; 
            c_data_out_2 <= 0; 
            c_data_out_3 <= 0; 
        end else if (condition_to_start_shifting_output) begin
            start_capturing_c_data <= 1'b1;
            c_data_available <= 1'b1;
            c_addr <= c_addr + address_stride_c;
            c_data_out <= col0; 
            c_data_out_1 <= col1; 
            c_data_out_2 <= col2; 
            c_data_out_3 <= col3; 
            counter <= counter + 1;
        end else if (done_mat_mul) begin
            start_capturing_c_data <= 1'b0;
            c_data_available <= 1'b0;
            c_addr <= address_mat_c + address_stride_c;
            c_data_out <= 0;
            c_data_out_1 <= 0;
            c_data_out_2 <= 0;
            c_data_out_3 <= 0;
        end else if (counter >= `MAT_MUL_SIZE) begin
            c_addr <= c_addr + address_stride_c;
            c_data_out <= c_data_out_1;
            c_data_out_1 <= c_data_out_2;
            c_data_out_2 <= c_data_out_3;
            c_data_out_3 <= c_data_in;
        end else if (start_capturing_c_data) begin
            c_data_available <= 1'b1;
            c_addr <= c_addr + address_stride_c;
            counter <= counter + 1;
            c_data_out <= c_data_out_1;
            c_data_out_1 <= c_data_out_2;
            c_data_out_2 <= c_data_out_3;
            c_data_out_3 <= c_data_in;
        end
    end

endmodule
