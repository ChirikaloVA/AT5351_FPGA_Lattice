`timescale 1 ns / 1 ns

module testbench_clock_5ms();
	reg clk_4mhz;
	reg reset;

	wire clk_5ms;
	wire clk_not_5ms;
	
	initial begin
		clk_4mhz <= 1'b0;
		reset <= 1'b0;
		$display("Running 'clock_5ms' testbench");
		#7435000 reset = 1'b1;
		#16674000 reset = 1'b0;
		#40000000 $stop;
		$display("'clock_5ms' testbench stopped");
		end


	always begin
		#125 clk_4mhz <= ~clk_4mhz;
		end
	
	
	clock_5ms CLOCK_5MS(
		.clk_4mhz(clk_4mhz), 
		.reset(reset), 
		.clk_5ms(clk_5ms), 
		.clk_not_5ms(clk_not_5ms)
		);

endmodule