`timescale 1ns/100ps

module cache(CLK,RESET,read,write,writedata,address,memBusy,mem_readdata,busywait,readdata,mem_read,mem_write,mem_writedata,mem_address);
	
	input CLK,RESET;
	input read,write,memBusy;				//inputs to the cache from cpu
	input [7:0] writedata,address;
	input [31:0] mem_readdata;

	output reg busywait,mem_read,mem_write;
	output reg [5:0]mem_address;				//outputs from the cache to data mem and cpu
	output reg [7:0]readdata;
	output reg [31:0]mem_writedata;

	
	reg [2:0] tag[7:0];						//tag holder
	reg valid[7:0],dirty[7:0];				//valid and dirty bit holder
	reg [7:0]datab1[7:0],datab2[7:0],datab3[7:0],datab4[7:0];	// data blocks


	wire valid_bit, dirty_bit ;			//wires to hold the current istruction's data
	wire [2:0] cache_tag ;
	wire [2:0]index,TAG;
	wire [1:0]offset;
	wire hit,tag_comp;
	
	assign index = address[4:2];		//splitting the address into offset,index and TAG
	assign offset = address[1:0];	
	assign TAG = address[7:5];

always @ (address,read,write) begin
	if(read || write ) begin 			//when there is a read or write inform the cpu
		busywait = 1;
	end else begin
		busywait = 0;
	end
end

assign #1 valid_bit = valid[index];
assign #1 dirty_bit = dirty[index];
assign #1 cache_tag = tag[index];
assign #0.9 tag_comp = (cache_tag== TAG)? 1:0;
assign hit = tag_comp && valid_bit;
			
integer i;							
always @ (RESET) begin				//when reset is set initialize valid and dirty bits to 0 
	if (RESET) begin
		busywait =0;
		for(i=0; i<8; i=i+1) begin
			valid[i] <=0;
			dirty[i] <= 0;
			tag[i][2:0] <=0;
			datab1[i][7:0] <=0;
			datab2[i][7:0] <=0;
			datab3[i][7:0] <=0;
			datab4[i][7:0] <=0;
		end
	end
end

always @ (posedge CLK)begin
	if (hit) begin				//when there is a hit assign the busywait to 0 to avoid the stall
		busywait = 0;;
	end 
end



always @ (*)begin		//according to the offset, chose the data block to read
	#1
	if(read)begin
	case(offset)
		0:begin
			readdata = datab1[index];
		end
		1: begin
			readdata = datab2[index];			
		end 
		2: begin
			readdata = datab3[index];
		end
		3: begin
			readdata = datab4[index];
		end
		
		endcase
		end
end


always @ (posedge CLK,hit) begin
	#1	
	if (hit && write) begin
		dirty[index] = 1;				// set the dirty bit in a write access
		case(offset) 					//select the datablock to write according to the offset
			0:	begin
				datab1[index] = writedata;
			end
			1:	begin
				 datab2[index] = writedata;
			end
	
			2:	begin
				 datab3[index]= writedata;
			end
			
			3:	begin
				 datab4[index] = writedata;
			end
						
		endcase
	end
end


//FSM for the cache controller
parameter IDLE = 3'b000, MEM_READ = 3'b001, MEM_WRITE = 3'b010, CACHE_WRITE = 3'b011;
 reg [1:0] state, next_state;

    // combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
                if ((read || write) && !dirty_bit && !hit)  
                    next_state = MEM_READ;
					
                else if ((read || write) && dirty_bit && !hit)
                    next_state = MEM_WRITE ;
					
                else 
                    next_state = IDLE;
            
            MEM_READ:
                if (!memBusy)
                    next_state = CACHE_WRITE;
                else    
                    next_state = MEM_READ;
					
            MEM_WRITE:
				if (!memBusy)
                    next_state = MEM_READ;
                else    
                    next_state = MEM_WRITE;
					
			CACHE_WRITE :
				next_state = IDLE;
			
        endcase
    end

    // combinational output logic
    always @(*)
    begin
        case(state)
            IDLE:
            begin
                mem_read = 0;
                mem_write = 0;
             	
            end
         
            MEM_READ: 					//reading from the mem will be done in this stage
            begin
				mem_read = 1;			//pass the request and the address to be read to the mem
                mem_write = 0;
                mem_address = {TAG,index};
               // busywait = 1;
                            
            end
            
			MEM_WRITE:				//writing to the memory is done in this stage
			begin
                mem_read = 0;		//pass the request, address and the data to be written to the memory
                mem_write = 1;
                mem_address = {TAG,index};
				mem_writedata = {datab1[index],datab2[index],datab3[index],datab4[index]};
               // busywait = 1;       
            end
			
			CACHE_WRITE:			//in this state, the cache is updating 
			begin
                mem_read = 0;
                mem_write = 0;
  				#1
				tag[index][2:0] = TAG;		//update the tag when updating the a=cache
				datab1[index] = mem_readdata[7:0];	//updating the datablocks
				datab2[index] = mem_readdata[15:8];
				datab3[index] = mem_readdata[23:16];
				datab4[index] = mem_readdata[31:24];
				valid[index] = 1;			//updating the valid and the dirty bits
				dirty[index] = 0;
				//busywait = 1;
            end
			
			
        endcase
    end

    // sequential logic for state transitioning 
    always @(posedge CLK,RESET)
    begin
        if(RESET)
            state = IDLE;
        else
            state = next_state;
    end
	
endmodule