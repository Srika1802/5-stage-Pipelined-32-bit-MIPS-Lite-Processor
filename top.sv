module top();

bit over1;
bit over2;
bit over3;
bit clock=0;

//INSTANTIATING ALL THE THREE MODULES

no_pipeline DUT1(over1);
pipeline_non_forward DUT2(over2);
pipeline_with_forward DUT3(over3);

//CLOCK
always #10 clock=~clock;

always@(posedge clock)

	begin
		if(over1 && over2 && over3)
		$finish();
	end

final

	begin
	//DUT 1 NO PIPELINE STATS
	
	$display( "-------------- NO PIPELINE STATS --------------\n\n\n"  );
	
	$display( "The number of clock cycles             : %d" , DUT1.cycle_count );
	$display ( "The value of PC                       : %d" , DUT1.pc );
	$display( "The number of instrcutions             : %d" , DUT1.total_instructions );
	$display( "The number of Arithmetic instructions  : %d" , DUT1.arith_instructions );
	$display( "The number of Logical instructions     : %d" , DUT1.logic_instructions );
	$display( "The number of memory Accessess      : %d" , DUT1.memory_count );
	$display( "The number of Branch instructions      : %d" , DUT1.branches + 1); 
	$display( "The number of Branches taken           : %d" , DUT1.branch_taken );

	$display( "\n\n-------------- REGISTERS AND memoryORY ACCESSED --------------\n\n\n"  );

	foreach(DUT1.reg_array[i])
	begin
	if(DUT1.reg_array[i]==1)
	$display( "The contents of Register[%d] are       : %d" ,i, DUT1.reg_file[i]);
	end
	foreach(DUT1.memory_array[i])
	begin
	if(DUT1.memory_array[i]==1)
	$display( "The contents of memoryory Accessed[%d] are: %d" ,i, {DUT1.memory[i], DUT1.memory[i+1],DUT1.memory[i+2],DUT1.memory[i+3] });
	end

	//DUT 2 PIPELINE WITHOUT FORWARDING
	$display( "-------------- PIPELINE WITHOUT FORWARDING --------------\n\n\n"  );
	$display( "The number of clock cycles in non forwarding : %d" , DUT2.count_cycles );
	$display( "The number of stall cycles  : %d" , DUT2.total_stall );
	$display( "The number of Data Hazards : %d" , DUT2.stall_raw );

	//DUT 3 PIPELINE WITH FORWARDING
	$display( "-------------- PIPELINE FORWADING -------------- \n\n\n " );
	$display( "The number of clock cycles during forwarding : %d" , DUT3.cycle_count );
	$display( "The number of stall in forwarding : %d" , DUT3.stall_raw );
	$display( "The number of Data Hazards : %d" , DUT3.stall_raw );
	end



endmodule