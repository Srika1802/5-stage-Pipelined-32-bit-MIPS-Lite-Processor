//PIPELINED WITH FORWARDING//

module pipeline_with_forward (output bit over);

//PARAMETER FOR ALL OPCODES

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

bit clock=0;
int trace;
int count;
int cycle_count;
int total_instructions;
bit branch_taken;
int branch_count ;
int hit;
int stall_raw;
bit  signed  [31:0]reg_file[32];
bit signed  [7:0]memory[4096];
bit signed [31:0]reg_updated[32];

bit signed  [31:0]pc;//program counter

struct {

  bit [31:0]Ir;
  bit [5:0]opcode;
  bit [4:0]src1;
  bit [4:0]src2;
  bit [4:0]dest;
  bit [31:0]load_word ;
  bit [31:0]store_word;  
  bit signed[31:0]rs;
  bit signed[31:0]rt;
  bit signed[31:0]rd;
  bit signed[16:0]imm;
  bit signed[31:0]result;
  bit signed[31:0]load_data;
  bit signed[31:0]pc_value;
  int signed source_reg1;
  int signed source_reg2;
  int signed dest_reg;
  bit signed [31:0]branch_target; 	
		} instruct[5];

bit [3:0] pipeline_stage[5];
int i=0;
int decode_stall;
bit fetch_wait;

//CLOCK//

always 
	begin

		#10 clock=~clock;

	end

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
	
		#60;
		$fclose(trace);

	end 
	
//INSTRUCTION FETCH//

always@(posedge clock)

	begin
		if(over==0)
			begin
				if(fetch_wait==0) 
					begin
						for(int i=0; i<5; i++)

							begin	

								if(pipeline_stage[i]==0 )

									begin		         
										 pipeline_stage[i] <=1;
										 instruct[i].Ir ={memory[pc ], memory[pc +1], memory[pc +2], memory[pc +3] }  ;
										 instruct[i].pc_value = pc ;
										 pc =pc +4;
										 break;
									end
							end
					end
			end
	end	

//INSTRUCTION DECODE//

always@(posedge clock)

 begin
if(over==0)
begin
#0;
   for(int i=0; i<5; i++)

          begin
            if(pipeline_stage[i]==4'd1)
           
                       begin
                          decode_stage(i) ;                            
                          decode_stall = check_decode_stall(i);
                          if(decode_stall==1)
                            begin
                          stall_raw=stall_raw+1;
                           fetch_wait <=1;
                            @(posedge clock);
                            fetch_wait<=0;
                           decode_stage(i) ; 
                             end
                          pipeline_stage[i]<=2;                         
                       break;
		       end
           end
 end
end
task decode_stage(int i);

     instruct[i].opcode = instruct[i].Ir[31:26];

                       
                         if ( (instruct[i].opcode==ADD) || (instruct[i].opcode==SUB) ||   (instruct[i].opcode==MUL) || (instruct[i].opcode==ORR) ||(instruct[i].opcode==ANDR) ||(instruct[i].opcode==XORR))
                         
                                    begin       
                                      instruct[i].src1     = instruct[i].Ir[25:21];
                                      instruct[i].src2     = instruct[i].Ir[20:16];
                                      instruct[i].dest     = instruct[i].Ir[15:11];
                                      instruct[i].source_reg1 = instruct[i].Ir[25:21];
                                      instruct[i].source_reg2     = instruct[i].Ir[20:16];
                                      instruct[i].dest_reg     = instruct[i].Ir[15:11];
                                      instruct[i].rs         = $signed(reg_file[instruct[i].Ir[25:21]]);
                                      instruct[i].rt         = $signed(reg_file[instruct[i].Ir[20:16]]);
                                      instruct[i].rd         = $signed(reg_file[instruct[i].Ir[15:11]]);
                                    end
                                                        	                          
                         else if ((instruct[i].opcode==ADDI) ||(instruct[i].opcode==SUBI) ||(instruct[i].opcode==MULI) ||(instruct[i].opcode==ORRI) ||(instruct[i].opcode==ANDI) ||(instruct[i].opcode==XORI) || (instruct[i].opcode==LWR) || (instruct[i].opcode==SWR))
                         
                                    begin                                     
                                      instruct[i].imm        = $signed(instruct[i].Ir[15:0]);
                                      instruct[i].src1     = instruct[i].Ir[25:21];
                                      instruct[i].src2     = instruct[i].Ir[20:16];
                                      instruct[i].source_reg1 = instruct[i].Ir[25:21];
                                      instruct[i].dest_reg     = instruct[i].Ir[20:16];
                                      instruct[i].source_reg2  = 32'hffff;
                                      instruct[i].rs         = $signed(reg_file[instruct[i].Ir[25:21]]);
                                      instruct[i].rt         = $signed(reg_file[instruct[i].Ir[20:16]]);
                                    end
                         
                         else if ((instruct[i].opcode== BZ))
                          
                                     begin
                                       instruct[i].src1     = instruct[i].Ir[25:21];
                                       instruct[i].branch_target     = $signed(instruct[i].Ir[15:0]);
                                       instruct[i].rs         = $signed(reg_file[instruct[i].Ir[25:21]]);
                                       instruct[i].source_reg1 = instruct[i].Ir[25:21];
                                       instruct[i].dest_reg    = 32'hffff;
                                       instruct[i].source_reg2  = 32'hffff;
                                     end
                         
                         else if ((instruct[i].opcode== BEQ))
                          
                                     begin
                                      instruct[i].src1     = instruct[i].Ir[25:21];
                                      instruct[i].src2     = instruct[i].Ir[20:16];
                                      instruct[i].branch_target     = $signed(instruct[i].Ir[15:0]);	                  
                                      instruct[i].source_reg1 = instruct[i].Ir[25:21];
                                      instruct[i].source_reg2= instruct[i].Ir[20:16];
                                      instruct[i].dest_reg  = 32'hffff;           
                                      instruct[i].rs         = $signed(reg_file[instruct[i].Ir[25:21]]);
                                      instruct[i].rt         = $signed(reg_file[instruct[i].Ir[20:16]]);
                                    end
                         
                         else if ((instruct[i].opcode== JUMP))
                          
                                     begin
                                     instruct[i].src1     = instruct[i].Ir[25:21];                          
                                     instruct[i].rs         = $signed(reg_file[instruct[i].Ir[25:21]]);
                                     instruct[i].source_reg1 = instruct[i].Ir[25:21];
                                     instruct[i].dest_reg    = 32'hffff;
                                     instruct[i].source_reg2  = 32'hffff;
                                     end
                           else
                                   begin
                                      instruct[i].rd         = 0;
                                      instruct[i].rs         = 0;
                                      instruct[i].rt         = 0;
                                      instruct[i].dest     = 0;
                                      instruct[i].src1     = 0;
                                      instruct[i].src2     = 0;
                                      instruct[i].source_reg1 =  32'hffff;
                                      instruct[i].dest_reg    = 32'hffff;
                                      instruct[i].source_reg2  = 32'hffff;
				   end
endtask

 function int check_decode_stall(int ADD );

  for(int i=0; i<5; i++)
  
    begin
               if( ( ( instruct[ADD].source_reg1== instruct[i].dest_reg) || ( instruct[ADD].source_reg2== instruct[i].dest_reg) )    &&  ( instruct[i].dest_reg != 32'hffff )  && pipeline_stage[i]==4'd2 && branch_taken==0 &&  instruct[i].opcode == 6'd12  ) 

                           begin    hit=1;  break  ;    end                       
    end
          
  if(hit==1) begin hit=0;  return 1; end else  return 0 ;
            
  endfunction
  
//INSTRUCTION EXECUTE

always@(posedge clock)

  begin
if(over==0)
begin
       for(i=0; i<5; i++)

          begin
            
            if(pipeline_stage[i]==4'd2)

                       begin

                          instruct[i].rs=$signed(reg_updated[instruct[i].src1]);
                          instruct[i].rt=$signed(reg_updated[instruct[i].src2]);
                          instruct[i].rd=$signed(reg_updated[instruct[i].dest]);                                                 
                          pipeline_stage[i]<=3;
                           
                     if(branch_taken ==0 )
                       begin   
                         case(instruct[i].opcode)
                           
                           ADD :  begin  add(instruct[i].rs, instruct[i].rt, instruct[i].result ); 
                                           reg_updated[instruct[i].dest] =  $signed(instruct[i].result) ;               end
                           
                           ADDI:  begin  addi(instruct[i].rs, instruct[i].imm , instruct[i].result );
                                           reg_updated[instruct[i].src2] =  $signed(instruct[i].result) ;               end
                           
                           SUB:    begin  sub(instruct[i].rs, instruct[i].rt, instruct[i].result );
                                           reg_updated[instruct[i].dest] =  $signed(instruct[i].result) ;               end
                                                      
                           SUBI:   begin subi(instruct[i].rs, instruct[i].imm , instruct[i].result );
                                           reg_updated[instruct[i].src2] =  $signed(instruct[i].result) ;               end
                           	                            
                           MUL:    begin  mul(instruct[i].rs, instruct[i].rt, instruct[i].result );
                                           reg_updated[instruct[i].dest] =  $signed(instruct[i].result) ;               end
                           
                           MULI:   begin muli(instruct[i].rs, instruct[i].imm , instruct[i].result );
                                           reg_updated[instruct[i].src2] =  $signed(instruct[i].result) ;               end
                                                     
                           ORR:    begin   orr(instruct[i].rs, instruct[i].rt, instruct[i].result );
                                           reg_updated[instruct[i].dest] =  $signed(instruct[i].result) ;               end
                                   
                           ORRI:    begin ori(instruct[i].rs, instruct[i].imm , instruct[i].result );
                                           reg_updated[instruct[i].src2] =  $signed(instruct[i].result );               end
                                                      
                           ANDR:    begin  andr(instruct[i].rs, instruct[i].rt, instruct[i].result );
                                           reg_updated[instruct[i].dest] =  $signed(instruct[i].result) ;               end
                           	                           
                           ANDI:   begin andi(instruct[i].rs, instruct[i].imm , instruct[i].result );
                                           reg_updated[instruct[i].src2] =  $signed(instruct[i].result );               end
                                                      
                           XORR:    begin  xorr(instruct[i].rs, instruct[i].rt, instruct[i].result );
                                           reg_updated[instruct[i].dest] =  $signed(instruct[i].result) ;               end
                                                     
                           XORI:   begin xori(instruct[i].rs, instruct[i].imm , instruct[i].result );
                                           reg_updated[instruct[i].src2] =  $signed(instruct[i].result) ;               end
                                                      
                           LWR :   instruct[i].load_word=instruct[i].rs+instruct[i].imm;
                                                      
                           SWR :   instruct[i].store_word= instruct[i].rs+instruct[i].imm;
                                                      
                           BZ:      begin
                                       if(instruct[i].rs==0)  begin   
                                       pc<= (instruct[i].branch_target*4 )+instruct[i].pc_value;  branch_taken<=1; branch_count= branch_count +1;  end
                           	     end
                           
                           BEQ:    begin
                                       if(instruct[i].rs==instruct[i].rt)
                                      begin  pc<= (instruct[i].branch_target*4) +instruct[i].pc_value ; branch_taken<=1; branch_count= branch_count +1; end
                           	     end
                           
                           JUMP:     begin
                                       pc<=instruct[i].rs;
                                       branch_taken<=1; branch_count= branch_count +1;
                           	    end                           
                           endcase
                        end

                      else
           
                         begin
                           
                           instruct[i].opcode=6'd22; 
                           count=count+1;
                         
                           if(count>1)
                           begin
                              count=0;
                              branch_taken<=0;              
                            end
                        end
                           
                           break;
               end                                       
        end               
  end
end

//ARITHMETIC OPERATIONS

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


//MEM ACCESS//

always@(posedge clock)

  begin
if(over==0)
begin
      for(i=0; i<5; i++)
          begin

            if(pipeline_stage[i]==4'd3)

                       begin

                         pipeline_stage[i]<=4;

                        case(instruct[i].opcode)
                                                                              
                           LWR : begin
                           
     
								instruct[i].load_data= {memory[instruct[i].load_word],memory[instruct[i].load_word+1], memory[instruct[i].load_word+2], memory[instruct[i].load_word+3]};
								reg_updated[ instruct[i].src2] = $signed(instruct[i].load_data);
                           	   end
                           
                           SWR: begin
                             {memory[instruct[i].store_word],memory[instruct[i].store_word+1], memory[instruct[i].store_word+2], memory[instruct[i].store_word+3]}=instruct[i].rt;
                           
                           	   end
                        
                           endcase
                           
                           break;
                      
                       end
         end
  end
end

//WRITE BACK//


always@(posedge clock)

  begin
if(over==0)
begin
      for(i=0; i<5; i++)

          begin

            if(pipeline_stage[i]==4'd4)

                       begin
                         if(instruct[i].opcode <= 6'd18)
                         total_instructions =total_instructions+1;  
      
                         pipeline_stage[i]<=0;
                         
                         case(instruct[i].opcode) 
                           
                           ADD :    reg_file[instruct[i].dest] = instruct[i].result;
                                                        
                           ADDI:   reg_file[instruct[i].src2] = instruct[i].result;
                                                     
                           SUB:     reg_file[instruct[i].dest] = instruct[i].result;                 
                           
                           SUBI:   reg_file[instruct[i].src2] = instruct[i].result;
                           	                                
                           MUL:     reg_file[instruct[i].dest] = instruct[i].result;                                                
                           
                           MULI:   reg_file[instruct[i].src2] = instruct[i].result;
                                                      
                           ORR:      reg_file[instruct[i].dest] = instruct[i].result;
                           	                            
                           ORRI:    reg_file[instruct[i].src2] = instruct[i].result;
                                                      
                           ANDR:     reg_file[instruct[i].dest] = instruct[i].result;
                           	                            
                           ANDI:   reg_file[instruct[i].src2] = instruct[i].result;
                           	                                
                           XORR:     reg_file[instruct[i].dest] = instruct[i].result;
                                                      
                           XORI:   reg_file[instruct[i].src2] = instruct[i].result;
                           	                              
                           LWR :   reg_file[instruct[i].src2] = instruct[i].load_data;
                                                                               
                           HALT:    over<=1;
                                                     	               
                           endcase
                           
                           break;                       
                       end
         end
  end

end

// END OF 5 STAGES//


always@(posedge clock)
begin  
if(over==0)
 cycle_count=cycle_count+1; 
 end

endmodule
