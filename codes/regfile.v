`timescale 1ns/100ps

module reg_file(IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, WRITE, CLK, RESET);  //creating the module of register file
	input [7:0]IN;											//declaring inputs and outputs IN will take the data to be written
	output [7:0]OUT1,OUT2;									// output registers to write and store the data taken
	input [2:0]INADDRESS;									// register value where the data is 
	input [2:0]OUT1ADDRESS,OUT2ADDRESS;						// register numbers where the data should be retrieved from
	input WRITE, CLK, RESET;									// control signals of register file

	reg [7:0] RegisterFile[0:7]	;					// array of registers 8 registers with 8 bit length

	integer i;					//an incrementor to go on the regidter file to reset

	assign #2 OUT1 = RegisterFile[OUT1ADDRESS];				//assigning the output with their corresponding registers with delay
	assign #2 OUT2 = RegisterFile[OUT2ADDRESS];

	
	always @(posedge CLK or RESET)					//make the code block sensitive to the positive edge of the clock or to the positive edge of the reset
	begin

		if(RESET)begin						//if the reset command is given then assigning 0 to all the registers in the 
			#1								//delaying read and reset
			for(i = 0 ;i< 8 ; i++)begin		// register file
				RegisterFile[i] <= 0;			
			end
		end else begin 
			if(WRITE)begin								// if write is enabled then wite the data in to the file
				#1 RegisterFile[INADDRESS] <=IN;		//assign data to the corresponding register after the delay
			end
		end
	
	end


endmodule