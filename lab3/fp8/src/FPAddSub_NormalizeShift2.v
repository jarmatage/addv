module FPAddSub_NormalizeShift2(
    input  logic [32:0] PSSum,      // The Pre-Shift-Sum
    input  logic [7:0]  CExp,
    input  logic [4:0]  Shift,      // Amount to be shifted
    output logic [22:0] NormM,      // Normalized mantissa
    output logic [8:0]  NormE,      // Adjusted exponent
    output logic        ZeroSum,    // Zero flag
    output logic        NegE,       // Flag indicating negative exponent
    output logic        R,          // Round bit
    output logic        S,          // Final sticky bit
    output logic        FG
);

	// Internal signals
	wire MSBShift;		// Flag indicating that a second shift is needed
	wire [8:0] ExpOF;	// MSB set in sum indicates overflow
	wire [8:0] ExpOK;   // MSB not set, no adjustment
	
	// Calculate normalized exponent and mantissa, check for all-zero sum
	assign MSBShift = PSSum[32];		        // Check MSB in unnormalized sum
	assign ZeroSum = ~|PSSum;			        // Check for all zero sum
	assign ExpOK = CExp - Shift;		        // Adjust exponent for new normalized mantissa
	assign NegE = ExpOK[8];			            // Check for exponent overflow
	assign ExpOF = CExp - Shift + 8'd1;		    // If MSB set, add one to exponent(x2)
	assign NormE = MSBShift ? ExpOF : ExpOK;    // Check for exponent overflow
	assign NormM = PSSum[31:9];		            // The new, normalized mantissa
	
	// Also need to compute sticky and round bits for the rounding stage
	assign FG = PSSum[8]; 
	assign R = PSSum[7];
	assign S = |PSSum[6:0];
	
endmodule
