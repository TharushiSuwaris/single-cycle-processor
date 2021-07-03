`timescale 1ns/100ps

module alu(DATA1, DATA2, SELECT, RESULT,ZERO);		//verifying the ports in the module ALU
	input [7:0]DATA1;						//declating the inputs with their bit lengths
	input [7:0]DATA2;
	input[2:0]SELECT;						//select signal with 3 bits length
	output reg [7:0]RESULT;					// result is a register type output of 8 bit length
	output ZERO;						//to decide with branching 

	wire [7:0]in_val;

	reg [7:0]forward,addition,band,bor;

	assign in_val = ~RESULT;
	
	AND my_and(ZERO,in_val);

always@(DATA1,DATA2) begin
	#1 forward = DATA2;
	#2 addition = DATA1 + DATA2;
	#1 band = DATA1 & DATA2 ;
	#1 bor = DATA1 | DATA2;
end

	always @ (SELECT,forward,addition,band,bor)begin		// make the sensitivity list, to do the operations accordig to the given SELECT signal
	case (SELECT)							//use case structure to operate on corresponing operations
											// make the selecetor as 'select'
		3'b000:									// 1st case when select = 000
			RESULT = forward;							// forward the data2 value to result

		3'b001:									// case 2: select = 001	(sub instruction and beq)
			RESULT = addition;			// addition of data operands 

		3'b010:									// case 3: select = 010
			RESULT = band;				// bitwise and operation

		3'b011:									// case 4: select =011
			RESULT = bor;					// bit wise or operation

		3'b100 :						//select signal for j instruction
			RESULT = 8'd0;

		default:
			#1 RESULT = 8'b00000000;					// set the result to 0 for any other select signals...if the result is not assigned to a number it will take the value of previous result  which is wrong to oupput the result to a any other reserved signal

	endcase

	end
endmodule


