module systolic_data_setup (
    input  logic                             clk,
    input  logic                             reset,
    input  logic                             start_mat_mul,
    output logic [`AWIDTH-1:0]               a_addr,
    output logic [`AWIDTH-1:0]               b_addr,
    input  logic [`AWIDTH-1:0]               address_mat_a,
    input  logic [`AWIDTH-1:0]               address_mat_b,
    input  logic [`ADDR_STRIDE_WIDTH-1:0]    address_stride_a,
    input  logic [`ADDR_STRIDE_WIDTH-1:0]    address_stride_b,
    input  logic [`MAT_MUL_SIZE*`DWIDTH-1:0] a_data,
    input  logic [`MAT_MUL_SIZE*`DWIDTH-1:0] b_data,
    input  logic [7:0]                       clk_cnt,
    output logic [`DWIDTH-1:0]               a0_data,
    output logic [`DWIDTH-1:0]               a1_data_delayed_1,
    output logic [`DWIDTH-1:0]               a2_data_delayed_2,
    output logic [`DWIDTH-1:0]               a3_data_delayed_3,
    output logic [`DWIDTH-1:0]               b0_data,
    output logic [`DWIDTH-1:0]               b1_data_delayed_1,
    output logic [`DWIDTH-1:0]               b2_data_delayed_2,
    output logic [`DWIDTH-1:0]               b3_data_delayed_3,
    input  logic [`MASK_WIDTH-1:0]           validity_mask_a_rows,
    input  logic [`MASK_WIDTH-1:0]           validity_mask_a_cols_b_rows,
    input  logic [`MASK_WIDTH-1:0]           validity_mask_b_cols,
    input  logic [7:0]                       final_mat_mul_size,
    input  logic [7:0]                       a_loc,
    input  logic [7:0]                       b_loc
    );
    
    wire [`DWIDTH-1:0] a1_data;
    wire [`DWIDTH-1:0] a2_data;
    wire [`DWIDTH-1:0] a3_data;
    wire [`DWIDTH-1:0] b1_data;
    wire [`DWIDTH-1:0] b2_data;
    wire [`DWIDTH-1:0] b3_data;

    //////////////////////////////////////////////////////////////////////////
    // Logic to generate addresses to BRAM A
    //////////////////////////////////////////////////////////////////////////
    logic a_mem_access; //flag that tells whether the matmul is trying to access memory or not
    
    always_ff @(posedge clk) 
    begin
        if ((reset || ~start_mat_mul) || (clk_cnt >= (a_loc<<`LOG2_MAT_MUL_SIZE)+final_mat_mul_size)) begin
            a_addr <= address_mat_a-address_stride_a;
            a_mem_access <= 0;
        end
        else if ((clk_cnt >= (a_loc<<`LOG2_MAT_MUL_SIZE)) && (clk_cnt < (a_loc<<`LOG2_MAT_MUL_SIZE)+final_mat_mul_size)) 
        begin
            a_addr <= a_addr + address_stride_a;
            a_mem_access <= 1;
        end
    end  

    //////////////////////////////////////////////////////////////////////////
    // Logic to generate valid signals for data coming from BRAM A
    //////////////////////////////////////////////////////////////////////////
    logic [7:0] a_mem_access_counter;
    always_ff @(posedge clk) 
    begin
        if (reset || ~start_mat_mul) 
            a_mem_access_counter <= 0;
        else if (a_mem_access == 1) 
            a_mem_access_counter <= a_mem_access_counter + 1;  
        else 
            a_mem_access_counter <= 0;
    end

    wire a_data_valid; //flag that tells whether the data from memory is valid
    assign a_data_valid = 
        ((validity_mask_a_cols_b_rows[0]==1'b0 && a_mem_access_counter==1) ||
        (validity_mask_a_cols_b_rows[1]==1'b0 && a_mem_access_counter==2) ||
        (validity_mask_a_cols_b_rows[2]==1'b0 && a_mem_access_counter==3) ||
        (validity_mask_a_cols_b_rows[3]==1'b0 && a_mem_access_counter==4)) ?
        1'b0 : (a_mem_access_counter >= `MEM_ACCESS_LATENCY);
    
    //////////////////////////////////////////////////////////////////////////
    // Logic to delay certain parts of the data received from BRAM A (systolic data setup)
    //////////////////////////////////////////////////////////////////////////
    //Slice data into chunks and qualify it with whether it is valid or not
    assign a0_data = a_data[`DWIDTH-1:0] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[0]}};
    assign a1_data = a_data[2*`DWIDTH-1:`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[1]}};
    assign a2_data = a_data[3*`DWIDTH-1:2*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[2]}};
    assign a3_data = a_data[4*`DWIDTH-1:3*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[3]}};

    //For larger matmuls, more such delaying flops will be needed
    logic [`DWIDTH-1:0] a2_data_delayed_1;
    logic [`DWIDTH-1:0] a3_data_delayed_1;
    logic [`DWIDTH-1:0] a3_data_delayed_2;
    
    always_ff @(posedge clk) 
    begin
        if (reset || ~start_mat_mul || clk_cnt==0) 
        begin
            a1_data_delayed_1 <= 0;
            a2_data_delayed_1 <= 0;
            a2_data_delayed_2 <= 0;
            a3_data_delayed_1 <= 0;
            a3_data_delayed_2 <= 0;
            a3_data_delayed_3 <= 0;
        end
        else 
        begin
            a1_data_delayed_1 <= a1_data;
            a2_data_delayed_1 <= a2_data;
            a2_data_delayed_2 <= a2_data_delayed_1;
            a3_data_delayed_1 <= a3_data;
            a3_data_delayed_2 <= a3_data_delayed_1;
            a3_data_delayed_3 <= a3_data_delayed_2;
        end
    end

    //////////////////////////////////////////////////////////////////////////
    // Logic to generate addresses to BRAM B
    //////////////////////////////////////////////////////////////////////////
    logic b_mem_access; //flag that tells whether the matmul is trying to access memory or not

    always_ff @(posedge clk)
    begin
        if ((reset || ~start_mat_mul) || (clk_cnt >= (b_loc<<`LOG2_MAT_MUL_SIZE)+final_mat_mul_size)) 
        begin
            b_addr <= address_mat_b - address_stride_b;
            b_mem_access <= 0;
        end
        else if ((clk_cnt >= (b_loc<<`LOG2_MAT_MUL_SIZE)) && (clk_cnt < (b_loc<<`LOG2_MAT_MUL_SIZE)+final_mat_mul_size)) 
        begin
            b_addr <= b_addr + address_stride_b;
            b_mem_access <= 1;
        end
    end  

    //////////////////////////////////////////////////////////////////////////
    // Logic to generate valid signals for data coming from BRAM B
    //////////////////////////////////////////////////////////////////////////
    logic [7:0] b_mem_access_counter;
    always_ff @(posedge clk) 
    begin
        if (reset || ~start_mat_mul) 
            b_mem_access_counter <= 0;
        else if (b_mem_access == 1)
            b_mem_access_counter <= b_mem_access_counter + 1;  
        else
            b_mem_access_counter <= 0;
    end

    wire b_data_valid; //flag that tells whether the data from memory is valid
    assign b_data_valid = 
        ((validity_mask_a_cols_b_rows[0]==1'b0 && b_mem_access_counter==1) ||
        (validity_mask_a_cols_b_rows[1]==1'b0 && b_mem_access_counter==2) ||
        (validity_mask_a_cols_b_rows[2]==1'b0 && b_mem_access_counter==3) ||
        (validity_mask_a_cols_b_rows[3]==1'b0 && b_mem_access_counter==4)) ?
        1'b0 : (b_mem_access_counter >= `MEM_ACCESS_LATENCY);


    //////////////////////////////////////////////////////////////////////////
    // Logic to delay certain parts of the data received from BRAM B (systolic data setup)
    //////////////////////////////////////////////////////////////////////////
    //Slice data into chunks and qualify it with whether it is valid or not
    assign b0_data = b_data[`DWIDTH-1:0] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[0]}};
    assign b1_data = b_data[2*`DWIDTH-1:`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[1]}};
    assign b2_data = b_data[3*`DWIDTH-1:2*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[2]}};
    assign b3_data = b_data[4*`DWIDTH-1:3*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[3]}};

    //For larger matmuls, more such delaying flops will be needed
    logic [`DWIDTH-1:0] b2_data_delayed_1;
    logic [`DWIDTH-1:0] b3_data_delayed_1;
    logic [`DWIDTH-1:0] b3_data_delayed_2;
    
    always_ff @(posedge clk) 
    begin
        if (reset || ~start_mat_mul || clk_cnt==0) 
        begin
            b1_data_delayed_1 <= 0;
            b2_data_delayed_1 <= 0;
            b2_data_delayed_2 <= 0;
            b3_data_delayed_1 <= 0;
            b3_data_delayed_2 <= 0;
            b3_data_delayed_3 <= 0;
        end
        else 
        begin
            b1_data_delayed_1 <= b1_data;
            b2_data_delayed_1 <= b2_data;
            b2_data_delayed_2 <= b2_data_delayed_1;
            b3_data_delayed_1 <= b3_data;
            b3_data_delayed_2 <= b3_data_delayed_1;
            b3_data_delayed_3 <= b3_data_delayed_2;
        end
    end

endmodule
