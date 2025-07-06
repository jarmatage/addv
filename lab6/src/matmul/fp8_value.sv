typedef struct packed {
    logic       sign;
    logic [2:0] exp;
    logic [3:0] mant;
} fp8_value;
