`timescale 1 ns / 100 ps

module testbench_clock_4mhz();
	reg clk_12mhz;
	reg reset;

	wire clk_4mhz;
	
	initial begin
		clk_12mhz <= 1'b0;
		reset <= 1'b0;
		$display("Running 'clock_4mhz' testbench");
		#74350 reset = 1'b1;
		#166740 reset = 1'b0;
		#400000 $stop;
		$display("'clock_4mhz' testbench stopped");
		end


	always begin
		#41.6 clk_12mhz <= ~clk_12mhz;
		end
	
	
	clock_4mhz CLOCK_4MHZ(
		.clk_in(clk_12mhz),
		.clk_4mhz(clk_4mhz),
		.reset(reset)
		);

endmodule