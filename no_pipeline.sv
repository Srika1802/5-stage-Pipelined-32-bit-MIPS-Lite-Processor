//SIMULATING WITHOUT ANY PIPELINES (NO PIPELINE MODULE)

module no_pipeline (output bit over);

//PARAMETERS FOR ALL OPCODES

parameter  ADD = 6'd0;
parameter  ADDI = 6'd1;
parameter  SUB = 6'd2;
parameter  SUBI = 6'd3;
parameter  MUL = 6'd4;
parameter  MULI = 6'd5;
parameter  ORR = 6'd6;
parameter  ORRI = 6'd7;
parameter  ANDR = 6'd8;
parameter  ANDI = 6'd9;
parameter  XORR = 6'd10;
parameter  XORI = 6'd11;
parameter  LWR = 6'd12;
parameter  SWR = 6'd13;
parameter  BZ = 6'd14;
parameter  BEQ = 6'd15;
parameter  JUMP = 6'd16;
parameter  HALT = 6'd17;


int trace;
int count;
int cycle_count;
int total_instructions;
int arith_instructions;
int logic_instructions;
int branches;
int branch_taken;
int memory_count;
int i;
int reg_array[32];
int memory_array[4096];
bit clock=0;
bit  signed  [31:0]reg_file[32];
bit signed  [7:0]memory[4096];
bit signed  [31:0]pc;//program counter

bit  signed [31:0]Ir;

//no.of bits in the instruction
bit  [5:0]opcode;
bit  [4:0]src1;
bit  [4:0]src2;
bit  [4:0]dest;
  
  //different registers
bit  [31:0]load_word;
bit  [31:0]store_word;
bit signed  [31:0]rs;
bit signed  [31:0]rt;
bit signed  [31:0]rd;
bit signed  [16:0]imm;
bit signed  [31:0]result;
bit signed  [31:0]load_data;
bit signed  [31:0]pc_value;
bit signed  [31:0]branch_target; 

//MEMORY FILLING WITH INSTRUCTIONS IN TRACE FILE//

 initial
	begin

		trace = $fopen ("./final_proj_trace.txt", "r");  
     
		if (trace == 0) begin
			$display("Error: Could not open file.");
			$finish;
		end
		
		while (!($feof(trace)))
		
		begin
			$fscanf(trace, "%32h",{memory[i], memory[i+1], memory[i+2], memory[i+3]});
			i=i+4;
	    end
	
		$fclose(trace);

	end 
	
//CLOCK//

always 
	begin

		#10 clock=~clock;

	end
always@(posedge clock)

	begin
		if(over==0)
		
		begin
			fetch();
			decode();
			execute();
			memory_stage();
			write_back();
		end
	end
	
//INSTRUCTION FETCH//

function void fetch();

          begin	         
             Ir ={memory[pc], memory[pc+1], memory[pc+2], memory[pc+3] }  ;
             pc=pc+4;
          end

endfunction


//INSTRUCTION DECODE//

function void decode( );

     opcode = Ir[31:26];                      
                         if ( (opcode==ADD) || (opcode==SUB) || (opcode==MUL) || (opcode==ORR) || (opcode==ANDR) || (opcode==XORR))
                         
                                    begin       
                                      src1     = Ir[25:21];
                                      src2     = Ir[20:16];
                                      dest     = Ir[15:11];
                                      rs       = $signed(reg_file[Ir[25:21]]);
                                      rt       = $signed(reg_file[Ir[20:16]]);
                                      rd       = $signed(reg_file[Ir[15:11]]);                               
                         	   
									end
                         
                         else if ((opcode==ADDI) || (opcode==SUBI) || (opcode==MULI) || (opcode==ORRI) || (opcode==ANDI) || ( opcode==XORI) || (opcode==LWR) || (opcode==SWR))                       
                                    begin                                     
                                      imm      = $signed(Ir[15:0]);
                                      src1     = Ir[25:21];
                                      src2     = Ir[20:16];
                                      rs       = $signed(reg_file[Ir[25:21]]);
                                      rt       = $signed(reg_file[Ir[20:16]]);
									end
                         
						 else if (opcode== BEQ)                          
                                    begin
                                      src1     			= Ir[25:21];
                                      src2     			= Ir[20:16];
                                      branch_target   	= $signed(Ir[15:0]);	                                        	                                  
                                      rs       			= $signed(reg_file[Ir[25:21]]);
                                      rt       			= $signed(reg_file[Ir[20:16]]);
                                    end
									
                         else if ((opcode== BZ))
									begin
									  src1     			= Ir[25:21];
                                      branch_target     = $signed(Ir[15:0]);
                                      rs         		= $signed(reg_file[Ir[25:21]]);
                                    end
                        
                         else if (opcode== JUMP)                          
                                    begin
                                      src1       = Ir[25:21];                          
                                      rs         = $signed(reg_file[Ir[25:21]]);
                                     end
                          else
                                    begin
                                      rd         = 0;
                                      rs         = 0;
                                      rt         = 0;
                                      dest       = 0;
                                      src1       = 0;
                                      src2       = 0;
				   end

                        reg_array[src1]=1;
                        reg_array[src2]=1;
                        reg_array[dest]=1;
endfunction

//INSTRUCTION EXECUTE

function void execute();
 
                         case(opcode)
                           
                           ADD    :	 add(rs, rt, result );
						   
                           ADDI   :  addi(rs, imm , result );                           
                           
						   SUB    :  sub (rs, rt,   result );                           	     
                           
						   SUBI   :  subi(rs, imm , result );                           
                           
						   MUL    :  mul (rs, rt,   result );                           
                           
						   MULI   :  muli(rs, imm , result );                           
                           
						   ORR    :  orr  (rs, rt,   result );                           
                           
						   ORRI   :  ori (rs, imm , result );                           
                           
						   ANDR   :  andr (rs, rt,   result );                           
                           
						   ANDI   :  andi(rs, imm , result );                          
                           
						   XORR   :  xorr (rs, rt,   result );                           
                           
						   XORI   :  xori(rs, imm , result );                           
                           
						   LWR    :  begin
										load_word=rs+imm;
										memory_count=memory_count+1;
									 end                           
                           
						   SWR    :  begin
										store_word=rs+imm;
										memory_count=memory_count+1;
										memory_array[ store_word]=1;
                                     end
									 
                           BZ     :  begin
										branches=branches+1;                     
										if(rs==0)
											begin
												branch_taken=branch_taken+1;                                  
												pc<= (branch_target*4 )+ pc-4;
											end
                           	         end
									 
                           BEQ	  :  begin
										branches=branches+1;                                  
										if( rs == rt)
											begin                                       
												pc<= (branch_target*4) + pc-4 ;
												branch_taken=branch_taken+1;
											end                           
                                	 end
									 
                           JUMP   :  begin
                                         pc<= rs;
										 branches=branches+1;
										 branch_taken=branch_taken+1;
									 end                                                  
                          endcase



 endfunction
 
//ARITHMETIC-OPERATIONS

  function void add (input bit signed [31:0]a , input bit signed [31:0]b , output bit signed [31:0]c ) ; c=a+b ;  endfunction

  function void addi (input bit signed [31:0]a , input  bit signed  [15:0]b , output  bit signed  [31:0]c ) ; c=a+b;  endfunction

  function void sub (input bit signed [31:0]a , input bit signed [31:0]b , output bit signed  [31:0]c ) ;   c=a-b;  endfunction

  function void subi (input bit signed [31:0]a , input bit signed [15:0]b , output bit signed [31:0]c ) ;  c=a-b;  endfunction

  function void mul (input bit signed [31:0]a , input bit signed [31:0]b , output bit signed [31:0]c ) ;  c=a*b;   endfunction

  function void muli (input bit signed [31:0]a , input bit signed [15:0]b , output bit signed [31:0]c ) ; c=a*b;  endfunction

  function void orr (input bit [31:0]a , input bit [31:0]b , output bit [31:0]c ) ;   c=a|b; endfunction

  function void ori (input bit [31:0]a , input bit [31:0]b , output bit [31:0]c ) ;  c=a|b; endfunction

  function void andr (input bit [31:0]a , input bit [31:0]b , output bit [31:0]c ) ; c=a&b; endfunction

  function void andi (input bit [31:0]a , input bit [31:0]b , output bit [31:0]c ) ; c=a&b; endfunction

  function void xorr (input bit [31:0]a , input bit [31:0]b , output bit [31:0]c ) ; c=a^b;  endfunction

  function void xori (input bit [31:0]a , input bit [31:0]b , output bit [31:0]c ) ; c=a^b; endfunction


//MEMORY ACCESS

function void memory_stage();
           
             case(opcode)                           
					LWR  : load_data= $signed({memory[load_word],memory[load_word+1], memory[load_word+2], memory[load_word+3]});                           
					SWR  : {memory[store_word],memory[store_word+1], memory[store_word+2], memory[store_word+3]}=$signed(rt);                           
             endcase

endfunction

//WRITE BACK
function void write_back();

                         total_instructions =total_instructions+1;                                
                         case(opcode)                            
                           ADD  :	begin                           
										reg_file[dest] = result;
										arith_instructions=arith_instructions+1;                              
                                    end
                           
                           ADDI :   begin                           
										reg_file[src2] = result;
										arith_instructions=arith_instructions+1;                              
                                    end
                           
                           SUB  : 	begin                           
										reg_file[dest] = result;                           	     
										arith_instructions=arith_instructions+1;                              
									end
                           
                           SUBI : 	begin                           
										reg_file[src2] = result;                           	      
										arith_instructions=arith_instructions+1;                              
                                    end
                           
                           MUL	:	begin                           
										reg_file[dest] = result;                           
										arith_instructions=arith_instructions+1;                              
									end
                           
                           MULI : 	begin                           
										reg_file[src2] = result;                           
										arith_instructions=arith_instructions+1;                              
                                    end
                           
                           ORR	:	begin                           
										reg_file[dest] = result; 
										logic_instructions=logic_instructions+1;                          	       
									end                           
                           
                           ORRI : 	begin                           
										reg_file[src2] = result;                           
										logic_instructions=logic_instructions+1;                          	       
									end
                           
                           ANDR : 	begin                           
										reg_file[dest] = result;                           	   
										logic_instructions=logic_instructions+1;                          	       
									end
                           
                           ANDI	: 	begin                                 
										reg_file[src2] = result;
										logic_instructions=logic_instructions+1;                          	       
									end
                           
                           XORR	: 	begin                           
										reg_file[dest] = result;                           
										logic_instructions=logic_instructions+1;                          	       
									end
                           
                           XORI	: 	begin                           
										reg_file[src2] =result;                           	   
										logic_instructions=logic_instructions+1;                          	       
									end
                           
                           LWR  : 	begin                           
										reg_file[src2] = load_data;                           
									end                     
                           
                            HALT: 	over<=1;
                                                                                
                         endcase                       
 endfunction

//END OF 5 STAGES//

always@(posedge clock)
	begin
		if(over==0)
			cycle_count=cycle_count+1;
	end



endmodule