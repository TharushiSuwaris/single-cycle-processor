`timescale 1ns/100ps

module control_unit(Instruction,readdata,busywait,CLK,RESET,mux_3,read,write,writedata,address);
	
	 
	input [31:0]Instruction;				//declaring the inputs of the module		
	input CLK,RESET,busywait;
	input [7:0]readdata;
	output [7:0]writedata,address;
	output reg mux_3,read,write;
	

	reg Branch;								//branch identicate the instruction is whether a branch instruction 
	reg [2:0]Select;						//declaring the wires and the registers comming from other modules
	reg [7:0]data2,writtendata;
	reg write_enable,mux_1,mux_2,mux_4;		//mux1 is to select between the 2's complement value and the original register valu
											//mux2 is for choose between immediate value and the register value
											//mux4 is for choose between the alu result or the data memory value
	

	wire [2:0]readreg1,readreg2,writereg;
	wire [7:0]out1,out2,aluout,opcode;		
	wire CLK,zero;


	reg_file my_reg(writtendata,out1,out2,writereg,readreg1,readreg2,write_enable,CLK,RESET);	//connect with register file
	alu my_alu(out1,data2,Select,aluout,zero);								//connect with alu module
	Decode my_decode(Instruction,opcode,readreg1,readreg2,writereg);		//connect with decoding module

	assign writedata = out1;
	assign address = aluout;	

	always @ (Instruction or mux_1 or mux_2 or out2 or Branch) //make the block sensitive to either Instruction,mux1 ,mux2 or out2(from the register file)
	begin
		if(mux_2 == 1'b1)begin						//if mux 2 is high take the output as the immediate value of the instruction
			data2 = Instruction[7:0];
		end else if(mux_1 == 1'b1)begin				//if mux1 is high then take the ouput as the output directly from the register file
			data2 = out2;
		end else begin								//if not
			#1 data2 = ~out2 + 1;					//do the 2's compliment to the value and take it as teh output(input to the alu)
		end

	end

	always @ (Branch or zero)begin					//make the block sensitive to Branch and zero signals
		if (Branch == 1'b1 & zero == 1'b1)begin		//if they are both 1 then output 1 as mux3 to select the jumped pc
			mux_3 = 1'b1;					
		end else begin
			mux_3 = 1'b0;					// else select the pc value with usual incrementation
		end
	end


	always @ (*) begin
		if(mux_4 == 1 )begin				//to select either from the memory or the alu result as write register
			writtendata = readdata;
		end else begin
			writtendata = aluout;
		end
	end

	always @(posedge CLK)begin			//to work with adjacent same instructions of store,
		if(busywait==0)begin
			read =0;
			write =0;
		end
	end

	always @ (opcode,Instruction) begin

		if(opcode == 8'b00000010 )begin	     //opcode for add instruction
			Select = 3'b001;	// select signal to do the addition
			mux_1 = 1'b1;		// original reg value taken as data2
			mux_2 = 1'b0;		//when mux2 is high then select the immediate value
			write_enable = 1'b1;
			Branch= 1'b0;		//if branch is 0 then the instruction is not j or beq	
			mux_4 = 1'b0;
			read = 0;
			write =0;

		end else if(opcode == 8'b00000100)begin				//opcode for and instruction
			Select = 3'b010;	// select signal to do the and operation
			mux_1 = 1'b1;		// take teh original reg value
			mux_2 = 1'b0;		// high to take the immediate value
			write_enable = 1'b1;
			Branch= 1'b0;
			mux_4 = 1'b0;
			read = 0;
			write =0;

		end else if(opcode == 8'b00000101)begin				//opcode for or instruction
			Select = 3'b011;	// select signal to do the or operation
			mux_1 = 1'b1;		//select the reg value (original)
			mux_2 = 1'b0;		//register val as data2(drop immediate value)
			write_enable = 1'b1;
			Branch = 1'b0;
			mux_4 = 1'b0;
			read = 0;
			write =0;

		end else if(opcode == 8'b00000011)begin		//opcode for sub instruction
			
			Select = 3'b001;	//select signal to do the addition 
			mux_2 = 1'b0;		//register value as the operand
			mux_1 = 1'b0;			//when this is 0, it will choose the negative value of the given value
			write_enable = 1'b1;
			Branch = 1'b0;
			mux_4 = 1'b0;
			read = 0;
			write =0;
		
		end else if(opcode ==8'b00000001 )begin		//for mov instruction
			Select = 3'b000;
			mux_1 = 1'b1;			//select the register value as the data
			mux_2= 1'b0;
			write_enable = 1'b1;
			Branch= 1'b0;
			mux_4 = 1'b0;
			read = 0;
			write =0;

		end else if(opcode == 8'b00000000 )begin			//for loadi instruction
			Select = 3'b000;								//aluop for forwarding
			mux_1 = 1'bx;									//dont care the mux1 value
			mux_2 = 1'b1;									// take the immediate value as the data2
			write_enable = 1'b1;
			Branch = 1'b0;
			mux_4 = 1'b0;
			read = 0;
			write =0;

		end else if(opcode == 8'b00000111)begin      //for beq instructions
			Select = 3'b001;		//select signal for sub instruction
			mux_1 = 1'b0;			//get the original value'snegative value in the register as data2
			mux_2= 1'b0;			//reg value as the data 2 not the immediate 
			write_enable = 1'b0;
			Branch= 1'b1;			//when branch is high this will take the updated pc for branch instruction
			mux_4 = 1'b0;
			read = 0;
			write =0;

		end else if(opcode == 8'b00000110 )begin			//for j instruction
			Select = 3'b100;		//for the signals which are not declared in the alu
			mux_1 = 1'bx;			//dont care the values of mux1 and mux2
			mux_2= 1'bx;
			write_enable = 1'b0;
			Branch= 1'b1;
			mux_4 = 1'b0;
			read = 0;
			write =0;

		end else if(opcode == 8'b00001000)begin			//for lwd instruction
			Select = 3'b000;		//for the signals which are not declared in the alu
			mux_1 = 1'b1;			//get the register value as the data2(drop 2's complement val)
			mux_2= 1'b0;			//drop immediate value and take the register value as data2
			write_enable = 1'b1;
			Branch= 1'b0;
			mux_4 = 1'b1;			// to take the value read from the data memory dropping the alu result
			read = 1'b1;			//request read access from memory
			write =0;

		end else if(opcode == 8'b00001001)begin			//for lwi instruction
			Select = 3'b000;		//for the signals which are not declared in the alu
			mux_1 = 1'bx;			//dont care
			mux_2= 1'b1;			//take the immediate value as the data
			write_enable = 1'b1;
			Branch= 1'b0;
			mux_4 = 1'b1;			// to take the value read from the data memory dropping the alu result
			read = 1'b1;			//request read access from memory
			write =0;


		end else if(opcode == 8'b00001010)begin			//for swd instruction
			Select = 3'b000;		//for the signals which are not declared in the alu
			mux_1 = 1'b1;			//get the register value as the data2(drop 2's complement val)
			mux_2= 1'b0;			//drop immediate value and take the register value as data2
			write_enable = 1'b0;
			Branch= 1'b0;
			write = 1'b1;			//request write from memory
			mux_4 = 1'b1;
			read = 0;

		end else if(opcode == 8'b00001011)begin			//for swi instruction
			Select = 3'b000;		//for the signals which are not declared in the alu
			mux_1 = 1'bx;			//dont care
			mux_2= 1'b1;			//take the immediate value as the data
			write_enable = 1'b0;
			Branch= 1'b0;
			write = 1'b1;			//request write from memory
			mux_4 = 1'b1;
			read = 0;

		end else begin				// for the instructions which are not implemented
			Select = 3'b1xx;		//for the signals which are not declared in the alu
			mux_1 = 1'bx;			//dont care the values of mux1 and mux2
			mux_2= 1'bx;
			write_enable = 1'b0;
			Branch = 1'b0;
		end
	end
endmodule