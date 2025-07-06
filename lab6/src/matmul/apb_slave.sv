module apb_slave (
    // APB Interface
    input  logic                      PCLK,
    input  logic                      PRESETn,
    input  logic [`REG_ADDRWIDTH-1:0] PADDR,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    input  logic [`REG_DATAWIDTH-1:0] PWDATA,
    output logic [`REG_DATAWIDTH-1:0] PRDATA,
    output logic                      PREADY,

    // Control/Status Registers (CPU Writes)
    output logic                          start,
    output logic                          is_fp8,
	output logic [`AWIDTH-1:0]            address_mat_a,
	output logic [`AWIDTH-1:0]            address_mat_b,
	output logic [`AWIDTH-1:0]            address_mat_c,
	output logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_a,
	output logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_b,
	output logic [`ADDR_STRIDE_WIDTH-1:0] address_stride_c,

    // Control/Status Registers (CPU Reads)
    input logic       done,
    input logic [4:0] flags
    );

    // CSR Address Map
    localparam ADDR_START    = 4'd0;
    localparam ADDR_MAT_A    = 4'd1;
    localparam ADDR_MAT_B    = 4'd2;
    localparam ADDR_MAT_C    = 4'd3;
    localparam ADDR_STRIDE_A = 4'd4;
    localparam ADDR_STRIDE_B = 4'd5;
    localparam ADDR_STRIDE_C = 4'd6;
    localparam ADDR_DONE     = 4'd7;
    localparam ADDR_IS_FP8   = 4'd8;

    // Define states
    typedef enum logic [1:0] {
        IDLE         = 2'b00,
        SETUP        = 2'b01,
        READ_ACCESS  = 2'b10,
        WRITE_ACCESS = 2'b11
    } state_t;

    state_t state, next_state;

    // State transition logic
    always_ff @(posedge PCLK) begin
        if (!PRESETn) begin
            state <= IDLE;
        end else begin 
            state <= next_state;
        end
    end

    // Always ready
    assign PREADY = 1'b1; 

    // Next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (PSEL && !PENABLE)
                    next_state = SETUP;
            end
            SETUP: begin
                if (!PSEL || !PENABLE)
                    next_state = IDLE;
                else if (PWRITE) begin
                    next_state = WRITE_ACCESS;
                end else begin
                    next_state = READ_ACCESS;
                end
            end
            WRITE_ACCESS, READ_ACCESS: begin
                if (!PSEL || !PENABLE)
                    next_state = IDLE;
            end
        endcase
    end

    // Write to CSRs
    always_ff @(posedge PCLK) begin
        if (!PRESETn) begin
            start            <= '0;
            is_fp8           <= '0;
            address_mat_a    <= '0;
            address_mat_b    <= '0;
            address_mat_c    <= '0;
            address_stride_a <= '0;
            address_stride_b <= '0;
            address_stride_c <= '0;
        end else if (PWRITE && PENABLE && next_state == WRITE_ACCESS) begin
            case (PADDR)
                ADDR_START:    start            <= PWDATA[0];
                ADDR_IS_FP8:   is_fp8           <= PWDATA[0];
                ADDR_MAT_A:    address_mat_a    <= PWDATA[`AWIDTH-1:0];
                ADDR_MAT_B:    address_mat_b    <= PWDATA[`AWIDTH-1:0];
                ADDR_MAT_C:    address_mat_c    <= PWDATA[`AWIDTH-1:0];
                ADDR_STRIDE_A: address_stride_a <= PWDATA[`ADDR_STRIDE_WIDTH-1:0];
                ADDR_STRIDE_B: address_stride_b <= PWDATA[`ADDR_STRIDE_WIDTH-1:0];
                ADDR_STRIDE_C: address_stride_c <= PWDATA[`ADDR_STRIDE_WIDTH-1:0];
            endcase
        end
    end

    // Read from CSRs
    always_ff @(posedge PCLK) begin
        if (!PRESETn) begin
            PRDATA <= '0;
        end else if (!PWRITE && PENABLE && next_state == READ_ACCESS) begin
            case (PADDR)
                ADDR_START:    PRDATA <= {15'd0, start};
                ADDR_IS_FP8:   PRDATA <= {31'd0, is_fp8};
                ADDR_MAT_A:    PRDATA <= address_mat_a;
                ADDR_MAT_B:    PRDATA <= address_mat_b;
                ADDR_MAT_C:    PRDATA <= address_mat_c;
                ADDR_STRIDE_A: PRDATA <= address_stride_a;
                ADDR_STRIDE_B: PRDATA <= address_stride_b;
                ADDR_STRIDE_C: PRDATA <= address_stride_c;
                ADDR_DONE:     PRDATA <= {10'd0, flags, done};
                default:       PRDATA <= 'x; // Default case to avoid latches
            endcase
        end
    end

endmodule
