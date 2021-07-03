`timescale 1ns/100ps
module cpu(pc,read,write,busywait,c_busywait,writedata,readdata,address, Instruction,CLK,RESET);			//the cpu module
	input [31:0]Instruction;
	input CLK,RESET,busywait,c_busywait;
	output reg [31:0]pc;				//32 bit size program counter
	output read,write;		

	input [7:0]readdata;
	output[7:0]writedata,address;
	wire mux3;

	wire [31:0]Extended ;			//32 bit size variable to store the extended offset
	wire [31:0]shifted_val;			//

	
	assign Extended = {{23{Instruction[23]}},Instruction[22:16],2'd0};	//extending the 8 bit offset into 32 bit value
	assign shifted_val = Extended >> 2; 				//shift the extended value
	

	control_unit cu(Instruction,readdata,busywait,CLK,RESET,mux3,read,write,writedata,address);		//calling the control unit


	always @ (posedge RESET) begin				//make the block sensitive to reset edge
		pc = -4;								//when reset is high assign the pc to -4 so then the next clock cycle the very first instruction to be fetched
	end



	always @ (posedge CLK) begin				// make the block sensitive to clock edge
		#1 
		if(RESET == 0 && busywait == 0 && c_busywait == 0)begin	//update the pc only if the memory is free. if not stall the cpu
			pc = pc + 4;			//update the pc by 4 to fetch the next instruction, with a delay of 1 time unit
		
		if(mux3 == 1'b1)begin				//when mux3 is high them select the pc of jumping instruction
			pc = shifted_val * 4 + pc ;	// update the pc according to the offset given
		end 
		end
	end
	


endmodule