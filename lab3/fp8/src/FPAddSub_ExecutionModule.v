module FPAddSub_ExecutionModule(
    input  logic [22:0] Mmax,   // The larger mantissa
    input  logic [23:0] Mmin,   // The smaller mantissa
    input  logic        Sa,     // Sign bit of larger number
    input  logic        Sb,     // Sign bit of smaller number
    input  logic        MaxAB,  // Indicates the larger number (0/A, 1/B)
    input  logic        OpMode, // Operation to be performed (0/Add, 1/Sub)
    output logic [32:0] Sum,    // The result of the operation
    output logic        PSgn,   // The sign for the result
    output logic        Opr     // The effective (performed) operation
);

    // Resolve sign to determine operation
	assign Opr = (OpMode^Sa^Sb); 		

	// Perform effective operation
	assign Sum = (OpMode^Sa^Sb) ? ({1'b1, Mmax, 8'd0} - {Mmin, 8'd0}) : ({1'b1, Mmax, 8'd0} + {Mmin, 8'd0});
	
	// Assign result sign
	assign PSgn = (MaxAB ? Sb : Sa);

endmodule
