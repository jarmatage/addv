module FPAddSub_AlignModule (
	input  logic [30:0] A,			// Input A (32-bits)
	input  logic [30:0] B,			// Input B (32-bits)
	input  logic [9:0]  ShiftDet,
	output logic [7:0]  CExp,		// Common exponent
	output logic        MaxAB,		// High if B > A
	output logic [4:0]  Shift,		// Number of steps to smaller mantissa shift right
	output logic [22:0] Mmin,		// Smaller mantissa
	output logic [22:0] Mmax		// Larger mantissa
);

	assign MaxAB = (A[30:0] < B[30:0]);
	
	// Determine final shift value
	assign Shift = MaxAB ? ShiftDet[9:5] : ShiftDet[4:0];
	
	// Take out smaller mantissa and append shift space
	assign Mmin = MaxAB ? A[22:0] : B[22:0]; 
	
	// Take out larger mantissa	
	assign Mmax = MaxAB ? B[22:0]: A[22:0];	
	
	// Common exponent
	assign CExp = (MaxAB ? B[30:23] : A[30:23]);		
	
endmodule
