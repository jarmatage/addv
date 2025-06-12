module FPAddSub_AlignShift2(
	input  logic [23:0] MminP,
	input  logic [1:0]  Shift,
	output logic [23:0] Mmin
);
	
	// Internal Signal
	logic [23:0] Lvl3;
	logic [47:0] Stage2;	
	integer j; // Loop variable
	
	assign Stage2 = {MminP, MminP};

	always @(*) begin
        case (Shift[1:0])
            // Rotate by 0
            2'b00:  Lvl3 <= Stage2[23:0];   
            // Rotate by 1
            2'b01:  begin for (j=0; j<=23; j=j+1)  begin Lvl3[j] <= Stage2[j+1]; end Lvl3[23] <= 0; end
            // Rotate by 2
            2'b10:  begin for (j=0; j<=23; j=j+1)  begin Lvl3[j] <= Stage2[j+2]; end Lvl3[23:22] <= 0; end
            // Rotate by 3
            2'b11:  begin for (j=0; j<=23; j=j+1)  begin Lvl3[j] <= Stage2[j+3]; end Lvl3[23:21] <= 0; end
        endcase
	end
	
	// Assign output
	assign Mmin = Lvl3; // Take out smaller mantissa				

endmodule
