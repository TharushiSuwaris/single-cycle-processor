`timescale 1ns/100ps
module cpu_tb;								//module testbench
	reg CLK,RESET;
	wire [31:0]PC;
	wire [31:0]INSTRUCTION;

	wire[7:0]writedata, address;		//wire to data cache & memory
	wire[7:0]readdata;
	wire busywait;
	wire read,write;

	wire[31:0]mem_writedata;		
	wire [5:0] mem_address;
	wire[31:0]mem_readdata;
	wire memBusy;
	wire mem_read,mem_write;

	wire [9:0]c_address;		//wires to instruction cache & memory
	wire [31:0]c_readdata;
	wire ins_memraed;
	wire [5:0]ins_mem_address;
	wire [127:0]ins_mem_readdata;
	wire ins_mem_busywait,c_busywait;
	
	cpu mycpu(PC,read,write,busywait,c_busywait,writedata,readdata,address,c_readdata,CLK,RESET);

	cache mycache(CLK,RESET, read,write,writedata, address,memBusy,mem_readdata, busywait,readdata,mem_read,mem_write ,mem_writedata ,mem_address);
	data_memory dataMem(CLK,RESET,mem_read,mem_write,mem_address,mem_writedata,mem_readdata,memBusy);			

	insCache myinsc(CLK,RESET,c_address, c_readdata,c_busywait, ins_memread,ins_mem_address, ins_mem_readdata,ins_mem_busywait);
	ins_memory myinsm(CLK,ins_memread,ins_mem_address,ins_mem_readdata,ins_mem_busywait);

	initial
	begin
		$dumpfile("cpu_wavedata.vcd");			//generate wave file
		$dumpvars(0,cpu_tb);

		
		CLK = 1'b1;						//initial value to the clk

        RESET = 1'b0;					

        #3
        RESET = 1'b1;

        #4
        RESET = 1'b0;


		#1800
		$finish;

	end

			
	assign c_address = PC[9:0];				// assigning the instruction cache address
	

	always
		#4 CLK = ~CLK;					//generate clock

endmodule