`timescale 1 ns / 100 ps

module testbench_pulse_counter();
	reg clk_12mhz;
	reg reset;
	reg trigger;
	
	wire clk_4mhz;
	wire [23:0] count_p; 
	wire [23:0] count_m;
	
	initial begin
		clk_12mhz <= 1'b0;
		reset <= 1'b0;
		trigger <= 1'b0;
		$display("Running 'pulse_counter' testbench");
		#74350 reset = 1'b1;
		#166740 reset = 1'b0;
		#400000 trigger = 1'b1;
		#1240000 trigger = 1'b0;
		
		#400000 $stop;
		$display("'pulse_counter' testbench stopped");
		end


	always begin
		#41.6 clk_12mhz <= ~clk_12mhz;
		end
	
	
	clock_4mhz CLOCK_4MHZ(
		.clk_in(clk_12mhz),
		.clk_4mhz(clk_4mhz),
		.reset(reset)
		);
		
	Pulse_Counter PULSE_COUNTER(
		.clk(clk_12mhz), 
		.clk_div_6(clk_4mhz), 
		.trigger(trigger),
		.reset(reset),
		.count_p(count_p), 
		.count_m(count_m)
		);

endmodule