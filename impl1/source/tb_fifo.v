`timescale 1 ns / 1 ps

module tb_fifo();
	reg clk_12mhz;
	reg reset;
	
	wire [23:0] count_p; 
	wire [23:0] count_m;

	//FIFO variables declaration
	reg fifo_wren, fifo_rden;
	wire fifo_clk;
	assign fifo_clk = clk_12mhz;
	wire fifo_reset;
	assign fifo_reset = reset;
	wire [23:0] fifo_out;
	wire [23:0] fifo_in;
	assign fifo_in = number;
	
	
	

	PUR PUR_INST (.PUR (PURNET));
	defparam PUR_INST.RST_PULSE = 100;	
	GSR GSR_INST (.GSR (reset));
	
	reg [23:0] 	number;
	reg [4:0]	counter;


	initial begin
		clk_12mhz <= 1'b0;
		reset <= 1'b1;
		//trigger <= 1'b0;	
		number <= 24'b0;
		counter <= 5'b0;
		
		fifo_wren <= 1'b0;
		fifo_rden <= 1'b0;
		
		
		$display("Running 'fifo' testbench");
		//#350 reset <= 1'b1;  
		
		#400 reset <= 1'b0;	   

		//#400000 trigger = 1'b1;
		//#1240000 trigger = 1'b0;


		#200000 $display("'fifo' testbench stopped");
		#1 $stop;
		end


	always begin
		#41.6 clk_12mhz <= ~clk_12mhz;
		end			  
		

	always @(posedge clk_12mhz) begin
		counter <= counter + 5'b1;
		number <= number + 24'b1;
		if (counter >= 5'd0 && counter <= 5'd15) begin
			fifo_wren <= 1'b1;
			end
		else fifo_wren <= 1'b0;
		
		if (counter >= 5'd5 && counter <= 5'd20) begin
			fifo_rden <= 1'b1;
			end
		else fifo_rden <= 1'b0;

		end
		
	
		

	FIFO FIFO(
		.Data(fifo_in), 
		.WrClock(fifo_clk), 
		.RdClock(fifo_clk), 
		.WrEn(fifo_wren), 
		.RdEn(fifo_rden), 
		.Reset(fifo_reset), 
		.RPReset(fifo_reset), 
		.Q(fifo_out), 
		.Empty(), 
		.Full(), 
		.AlmostEmpty(), 
		.AlmostFull()
		);


endmodule