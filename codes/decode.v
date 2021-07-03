
`timescale 1ns/100ps

module Decode(Instruction,opcode,ReadReg1,ReadReg2,WriteReg);	//a module to do the decoding of the instruction
	input [31:0]Instruction;									//32 bit size instruction
	output [2:0]ReadReg1,ReadReg2,WriteReg;						//this will output the inputs to the regfile
	output [7:0]opcode;											

	assign #1 opcode = Instruction[31:24];		//opcode is the most significat 8 bits of the instruction
	assign ReadReg1 = Instruction[10:8];		//source1 address
	assign ReadReg2 = Instruction[2:0];		//source2 address
	assign WriteReg = Instruction[18:16];	//destination address
	

	

endmodule