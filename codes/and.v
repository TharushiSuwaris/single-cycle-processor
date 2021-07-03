`timescale 1ns/100ps
module AND(out,in_val); //module to generate the zero signal of alu module
	
	input [7:0]in_val;		//input of this module (will take the negation of the result from the alu)
	output out;			// output of and module and as well as teh putpput Zero of alu module

	assign out = in_val[7] & in_val[6] & in_val[5] & in_val[4] & in_val[3] & in_val[2] & in_val[1] & in_val[0] ;	//every bit of the negated result value is multiplied and taken teh signle bit value to the output

endmodule