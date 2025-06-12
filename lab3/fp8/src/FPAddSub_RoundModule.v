module FPAddSub_RoundModule(
    input  logic        ZeroSum,    // Sum is zero
    input  logic [8:0]  NormE,      // Normalized exponent
    input  logic [22:0] NormM,      // Normalized mantissa
    input  logic        R,          // Round bit
    input  logic        S,          // Sticky bit
    input  logic        G,
    input  logic        Sa,         // A's sign bit
    input  logic        Sb,         // B's sign bit
    input  logic        Ctrl,       // Control bit (operation)
    input  logic        MaxAB,
    output logic [31:0] Z,          // Final result
    output logic        EOF
);

	// Internal signals
	wire [23:0] RoundUpM;	// Rounded up sum with room for overflow
	wire [22:0] RoundM;		// The final rounded sum
	wire [8:0] RoundE;		// Rounded exponent (note extra bit due to poential overflow)
	wire RoundUp;			// Flag indicating that the sum should be rounded up
	wire ExpAdd;			// May have to add 1 to compensate for overflow 
	wire RoundOF;			// Rounding overflow
	
	// The cases where we need to round upwards (= adding one) in Round to nearest, tie to even
	assign RoundUp = (G & ((R | S) | NormM[0]));
	
	// Note that in the other cases (rounding down), the sum is already 'rounded'
	assign RoundUpM = (NormM + 1);						// The sum, rounded up by 1
	assign RoundM = (RoundUp ? RoundUpM[22:0] : NormM); // Compute final mantissa	
	assign RoundOF = RoundUp & RoundUpM[23]; 			// Check for overflow when rounding up

	// Calculate post-rounding exponent
	assign ExpAdd = (RoundOF ? 1'b1 : 1'b0); 			// Add 1 to exponent to compensate for overflow
	assign RoundE = ZeroSum ? 8'd0 : (NormE + ExpAdd); 	// Final exponent

	// If zero, need to determine sign according to rounding
	assign FSgn = (ZeroSum & (Sa ^ Sb)) | (ZeroSum ? (Sa & Sb & ~Ctrl) : ((~MaxAB & Sa) | ((Ctrl ^ Sb) & (MaxAB | Sa))));

	// Assign final result
	assign Z = {FSgn, RoundE[7:0], RoundM[22:0]};
	
	// Indicate exponent overflow
	assign EOF = RoundE[8];
	
endmodule
