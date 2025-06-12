module FPAddSub_AlignShift1(
	input  logic [22:0] MminP,	// Smaller mantissa after 16|12|8|4 shift
	input  logic [2:0]  Shift,	// Shift amount
	output logic [23:0] Mmin	// The smaller mantissa
);
	
	// Internal signals
	logic [23:0] Lvl1;
	logic [23:0] Lvl2;
	logic [47:0] Stage1;
	integer i; // Loop variable
	
	// Rotate by 16
	assign Lvl1 = Shift[2] ? {17'd1, MminP[22:16]} : {1'b1, MminP};
	assign Stage1 = {Lvl1, Lvl1};
	
	always @(*) begin
        case (Shift[1:0])
            // Rotate by 0	
            2'b00:  Lvl2 <= Stage1[23:0];       			
            // Rotate by 4	
            2'b01:  begin for (i=0; i<=23; i=i+1) begin Lvl2[i] <= Stage1[i+4]; end Lvl2[23:19] <= 0; end
            // Rotate by 8
            2'b10:  begin for (i=0; i<=23; i=i+1) begin Lvl2[i] <= Stage1[i+8]; end Lvl2[23:15] <= 0; end
            // Rotate by 12	
            2'b11:  begin for (i=0; i<=23; i=i+1) begin Lvl2[i] <= Stage1[i+12]; end Lvl2[23:11] <= 0; end
        endcase
	end
	
	// Assign output to next shift stage
	assign Mmin = Lvl2;
	
endmodule
