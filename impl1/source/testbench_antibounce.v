`timescale 1 us / 10 ns

module testbench_antibounce();
	reg pos_comp = 1'b0;
	reg neg_comp = 1'b1;
	//reg reference = 1'b0;
	reg reset = 1'b0;
	reg clock_4MHZ = 1'b0;
	reg clock_12MHZ = 1'b0;
	
	wire out;
	
	initial begin
		reset <= 1'b0;
		pos_comp <= 1'b0;
		neg_comp <= 1'b1;
		clock_4MHZ <= 1'b0;
		//reference <= 1'b0;
		$display("Running 'antibounce' testbench");
		#74350 reset = 1'b1;
		#166740 reset = 1'b0;
		//#400000 trigger = 1'b1;
		//#1240000 trigger = 1'b0;
		
		//Дребезг
		#250000 neg_comp = 1'b0; 
		#25 neg_comp = 1'b1; 
		#36 neg_comp = 1'b0; 
		#45 neg_comp = 1'b1;
		#65 neg_comp = 1'b0; 
		#43 neg_comp = 1'b1;
		#24 neg_comp = 1'b0; 
		#24 neg_comp = 1'b1;
		#37 neg_comp = 1'b0; 
		
		//#2500 reference = ~reference;
		
		#10000 neg_comp = 1'b1; 
		#65 neg_comp = 1'b0; 
		#25 neg_comp = 1'b1; 
		#36 neg_comp = 1'b0; 
		#45 neg_comp = 1'b1;
		#65 neg_comp = 1'b0; 
		#43 neg_comp = 1'b1;
		#24 neg_comp = 1'b0; 
		#24 neg_comp = 1'b1;
		#37 neg_comp = 1'b0;
		#65 neg_comp = 1'b1; 
		
		#2000000 pos_comp = 1'b1; 
		#65 pos_comp = 1'b0; 
		#25 pos_comp = 1'b1; 
		#36 pos_comp = 1'b0; 
		#45 pos_comp = 1'b1;
		#65 pos_comp = 1'b0; 
		#43 pos_comp = 1'b1;
		#24 pos_comp = 1'b0; 
		#24 pos_comp = 1'b1;
		#37 pos_comp = 1'b0;
		#65 pos_comp = 1'b1; 
		
		//#3000 reference = ~reference;
		
		
		#10000 pos_comp = 1'b0; 
		#25 pos_comp = 1'b1; 
		#36 pos_comp = 1'b0; 
		#45 pos_comp = 1'b1;
		#65 pos_comp = 1'b0; 
		#43 pos_comp = 1'b1;
		#24 pos_comp = 1'b0; 
		#24 pos_comp = 1'b1;
		#37 pos_comp = 1'b0; 
		
		//2
		#2000000 neg_comp = 1'b0; 
		#25 neg_comp = 1'b1; 
		#36 neg_comp = 1'b0; 
		#45 neg_comp = 1'b1;
		#65 neg_comp = 1'b0; 
		#43 neg_comp = 1'b1;
		#24 neg_comp = 1'b0; 
		#24 neg_comp = 1'b1;
		#37 neg_comp = 1'b0; 
		
		//#2500 reference = ~reference;
		
		#10000 neg_comp = 1'b1; 
		#65 neg_comp = 1'b0; 
		#25 neg_comp = 1'b1; 
		#36 neg_comp = 1'b0; 
		#45 neg_comp = 1'b1;
		#65 neg_comp = 1'b0; 
		#43 neg_comp = 1'b1;
		#24 neg_comp = 1'b0; 
		#24 neg_comp = 1'b1;
		#37 neg_comp = 1'b0;
		#65 neg_comp = 1'b1; 
		
		#2000000 pos_comp = 1'b1; 
		#65 pos_comp = 1'b0; 
		#25 pos_comp = 1'b1; 
		#36 pos_comp = 1'b0; 
		#45 pos_comp = 1'b1;
		#65 pos_comp = 1'b0; 
		#43 pos_comp = 1'b1;
		#24 pos_comp = 1'b0; 
		#24 pos_comp = 1'b1;
		#37 pos_comp = 1'b0;
		#65 pos_comp = 1'b1; 
		
		//#3000 reference = ~reference;
		
		
		#10000 pos_comp = 1'b0; 
		#25 pos_comp = 1'b1; 
		#36 pos_comp = 1'b0; 
		#45 pos_comp = 1'b1;
		#65 pos_comp = 1'b0; 
		#43 pos_comp = 1'b1;
		#24 pos_comp = 1'b0; 
		#24 pos_comp = 1'b1;
		#37 pos_comp = 1'b0; 
		
		
		#400000 $stop;
		$display("'antibounce' testbench stopped");
		end


	always begin
		#0.125 clock_4MHZ <= ~clock_4MHZ;
		end
		
	always begin
		#0.041 clock_12MHZ <= ~clock_12MHZ;
		end	
	
	avk_capacitance AVK_CAPACITANCE(
		.pos_comparator(pos_comp),
		.neg_comparator(neg_comp),
		.reference(out),
		.clock_4mhz(clock_4MHZ), //4MHz	
		.clock_12mhz(clock_12MHZ), //4MHz	
		.reset(reset)
		
		);

endmodule