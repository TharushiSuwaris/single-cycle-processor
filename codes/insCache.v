`timescale 1ns/100ps
module insCache(CLK,RESET,c_address, c_readdata,c_busywait, memread,mem_address, mem_readdata,mem_busywait);
	
	input [9:0]c_address;
	input [127:0]mem_readdata;
	input mem_busywait,CLK,RESET;

	output reg [5:0]mem_address;
	output reg [31:0]c_readdata;
	output reg c_busywait,memread;

	reg [2:0] tag[7:0];						//tag holder
	reg valid[7:0];							//valid bit holder
	reg [31:0]datab1[7:0],datab2[7:0],datab3[7:0],datab4[7:0];	// data blocks
	
		//wires to hold the current istruction's data
	wire [2:0] cache_tag ;
	wire [2:0]index,TAG;
	wire [1:0]offset; 
	wire hit ,tag_comp,valid_bit;
	

	assign index = c_address[6:4];		//splitting the address into offset,index and TAG
	assign offset = c_address[3:2];	
	assign TAG = c_address[9:7];


assign #1 cache_tag = tag[index];					//	assign the tag according to the index		
assign #0.9 tag_comp = (cache_tag == TAG)? 1:0;		//tag comparison
assign #1 valid_bit = valid[index];					// assign the valid bit according to the index
assign hit = tag_comp && valid_bit;					//decide hit

integer i;							
always @ (RESET) begin				//when reset is set initialize valid bits to 0 
	if (RESET) begin
		c_busywait =0;
		for(i=0; i<8; i=i+1) begin
			valid[i] <= 0;
		end
	end
end




always @ (*)begin		//according to the offset, chose the data block to read
	#1
	case(offset)
		0:begin
			c_readdata = datab1[index];
		end
		1: begin
			c_readdata = datab2[index];			
		end 
		2: begin
			c_readdata = datab3[index];
		end
		3: begin
			c_readdata = datab4[index];
		end
		
		endcase
end



//FSM for the cache controller
parameter IDLE = 3'b000, MEM_READ = 3'b001, MINUS_PC = 3'b010, CACHE_WRITE = 3'b011;
 reg [2:0] state, next_state;

    // combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
                if (!hit)  
                    next_state = MEM_READ;
                
                else 
                    next_state = IDLE;
            
            MEM_READ:
                if (!mem_busywait)
                    next_state = CACHE_WRITE;
                else    
                    next_state = MEM_READ;
							
			CACHE_WRITE :
				next_state = IDLE;

			MINUS_PC : 					//handle when pc is -4
				next_state = IDLE;
			
        endcase
    end

    // combinational output logic
    always @(*)
    begin
        case(state)
            IDLE:
            begin
                memread = 0;
                c_busywait =0;            	
            end
         
            MEM_READ: 					//reading from the mem will be done in this stage
            begin
				memread = 1;			//pass the request and the address to be read to the mem
                mem_address = {TAG,index};
               	c_busywait = 1;
                            
            end
            
						
			CACHE_WRITE:			//in this state, the cache is updating 
			begin
                memread = 0;
                c_busywait =1;
  				#1
				tag[index] = TAG;				//update the tag when updating the cache
				datab1[index] = mem_readdata[31:0];	//updating the datablocks
				datab2[index] = mem_readdata[63:32];
				datab3[index] = mem_readdata[95:64];
				datab4[index] = mem_readdata[127:96];
				valid[index] = 1;
            end
			
			MINUS_PC :
			begin
				memread=0;
				c_busywait =0;
			end
        endcase
    end

    // sequential logic for state transitioning 
    always @(posedge CLK,posedge RESET)
    begin
        if(RESET)
            state = MINUS_PC;			//when reset is set handle the pc = -4 state
        else
            state = next_state;
    end
	
endmodule