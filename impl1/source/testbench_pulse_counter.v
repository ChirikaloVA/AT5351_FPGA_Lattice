`timescale 1 ns / 100 ps

//module testbench_pulse_counter();
	//reg clk_12mhz;
	//reg reset;
	//reg trigger;
	
	//wire clk_4mhz;
	//wire [23:0] count_p; 
	//wire [23:0] count_m;
	
	//initial begin
		//clk_12mhz <= 1'b0;
		//reset <= 1'b0;
		//trigger <= 1'b0;
		//$display("Running 'pulse_counter' testbench");
		//#74350 reset = 1'b1;
		//#166740 reset = 1'b0;
		//#400000 trigger = 1'b1;
		//#1240000 trigger = 1'b0;
		
		//#400000 $stop;
		//$display("'pulse_counter' testbench stopped");
		//end


	//always begin
		//#41.6 clk_12mhz <= ~clk_12mhz;
		//end
	
	
	//clock_4mhz CLOCK_4MHZ(
		//.clk_in(clk_12mhz),
		//.clk_4mhz(clk_4mhz),
		//.reset(reset)
		//);
		
	//Pulse_Counter PULSE_COUNTER(
		//.clk(clk_12mhz), 
		//.clk_div_6(clk_4mhz), 
		//.trigger(trigger),
		//.reset(reset),
		//.count_p(count_p), 
		//.count_m(count_m)
		//);

//endmodule



module testbench_pulse_counter();
	reg clk_12mhz;
	reg reset;
	//reg trigger;

	reg antibounce;
	reg ref_avk;	
	reg counter;
	
	
	wire [23:0] count_p; 
	wire [23:0] count_m;

	wire clk_4mhz;
	wire cnt_in;
	wire cnt_en;  
	
	reg 	cnt_choise;
	
	initial begin
		clk_12mhz <= 1'b0;
		reset <= 1'b0;
		//trigger <= 1'b0;	
		antibounce <= 1'b1;
		ref_avk <= 1'b0;	
		counter <= 1'b1;
		cnt_choise <= 1'b0;
		$display("Running 'pulse_counter' testbench");
		#74350 reset <= 1'b1;
		#166740 reset <= 1'b0;
		//#400000 trigger = 1'b1;
		//#1240000 trigger = 1'b0;
		#200000000	 cnt_choise <= 1'b0;
		#200000000	 cnt_choise <= 1'b1;
		#200000000	 cnt_choise <= 1'b1;
		#200000000	 cnt_choise <= 1'b1;
		#200000000	 cnt_choise <= 1'b1;
		#200000000	 cnt_choise <= 1'b1;
		#200000000	 cnt_choise <= 1'b1;
		#200000000	 cnt_choise <= 1'b1;
		#8000 $stop;
		$display("'pulse_counter' testbench stopped");
		end


	always begin
		#41.6 clk_12mhz <= ~clk_12mhz;
		end			  
		

	clock_4mhz CLK_4MHZ(
		.clk_12mhz(clk_12mhz),
		.clk_4mhz(clk_4mhz),
		.reset(reset)
		);



	always begin
		#200000000 antibounce <= ~antibounce;
		#500000	ref_avk <= ~ref_avk;
		#500000	antibounce <= ~antibounce;
		end
	
	

	always begin
		#3333000 counter <= ~counter;
		#6667000 counter <= ~counter;
		end
		
	

	count_choise COUNT_CHOISE(
		.count_mode(cnt_choise),
		.count1(counter),
		.enable1(1'b1),
		.count2(ref_avk),
		.enable2(antibounce),
		.count(cnt_in),
		.enable(cnt_en)
		);
	
	counter COUNTER(
		.clk_12mhz(clk_12mhz),
		.clk_4mhz(clk_4mhz),
		.cnt(cnt_in),
		.en(cnt_en),
		//.cnt_choise(cnt_choise),
		.count_p(count_p),
		.count_m(count_m),
		.risingedge(),
		.fallingedge(),		
		.reset(reset)
		);	  
		
	count_prebufer COUNT_PREBUFFER(
		.clk_12mhz(clk_12mhz),
		.mode(cnt_choise),
		.count_m(count_m),
		.count_p(count_p),
		.count(),
		.falling_edge(),
		.rising_edge(),

		.fifo_wr_en(),
		.reset(reset)		
	);	

endmodule