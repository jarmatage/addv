module FPAddSub_ExceptionModule(
	input  logic [31:0] Z,          // Final product
	input  logic        NegE,       // Negative exponent?
	input  logic        R,          // Round bit
	input  logic        S,          // Sticky bit
	input  logic [4:0]  InputExc,   // Exceptions in inputs A and B
	input  logic        EOF,
	output logic [31:0] P,          // Final result
	output logic [4:0]  Flags       // Exception flags
);

	// Exception flags
	wire Overflow;      // Overflow flag
	wire Underflow;	    // Underflow flag
	wire DivideByZero;	// Divide-by-Zero flag (always 0 in Add/Sub)
	wire Invalid;       // Invalid inputs or result
	wire Inexact;	    // Result is inexact because of rounding
	
	// Result is too big to be represented
	assign Overflow = EOF | InputExc[1] | InputExc[0];
	
	// Result is too small to be represented
	assign Underflow = NegE & (R | S);
	
	// Infinite result computed exactly from finite operands
	assign DivideByZero = &(Z[30:23]) & ~|(Z[30:23]) & ~InputExc[1] & ~InputExc[0];
	
	// Invalid inputs or operation
	assign Invalid = |(InputExc[4:2]);
	
	// Inexact answer due to rounding, overflow or underflow
	assign Inexact = (R | S) | Overflow | Underflow;
	
	// Put pieces together to form final result
	assign P = Z;
	
	// Collect exception flags	
	assign Flags = {Overflow, Underflow, DivideByZero, Invalid, Inexact}; 	
	
endmodule
