`timescale 1 ns / 1 ps

module testbench();

	//parameter duty = 1540000;			//1.54 ms
	//parameter duty_period = 10000000; 	//10ms
	parameter duty = 1540000;			//1.54 ms
	parameter duty_period = 10000000; 	//10ms
	parameter SPI_SPEED = 2;			//spi clock divider
	parameter SPI_BITS = 8;				//spi clock ticks
//	wire [3:0] count2;
//	wire [7:0] count3;

	reg clk1;
	reg reset = 1'b1;
	
	reg d;

	reg spi_clk, spi_mosi, spi_cs;
	wire spi_miso;
	reg [7:0] spi_divider;
	reg [7:0] spi_clk_counter;
	reg [7:0] buffer;
	
	wire clk_4mhz;
	wire clk_5ms; 
	wire clk_not_5ms; 

	//PUR PUR_INST (.PUR (PURNET));
	//defparam PUR_INST.RST_PULSE = 10;	
	//GSR GSR_INST (.GSR (GSRNET));


	initial begin
		clk1 <= 1'b1;
		reset <= #2000 1'b0;
		d <= 1'b0;
		spi_clk <= 1'b0;
		spi_cs <= 1'b1;
		spi_mosi <= 1'b0;
		//spi_miso <= 1'b1;
		spi_divider <= 8'd0;
		spi_clk_counter <= 8'd0;
		buffer <= 8'h80;
	end

	
	// 12MHz clock generation 
	always begin
		//#() clk = ~clk;
		#41.667 clk1 <= ~clk1;
		end
	always  begin
		#(duty+8316) d <= 1'b0;
		#(duty_period - duty+8316) d <= 1'b1;
		
		/*
		if (counter_pos >= duty_pos &&  counter_pos < (16'd20000 - duty_pos))
			d <= 1'b1;
		else if (counter_pos < duty_pos)
			d <= 1'b0;
		else if (counter_pos == 16'd20000)
			counter_pos <= 16'd0;
		counter_pos <= counter_pos + 1;
		*/
		end
	

	
	top top(
		.clk(clk1),    
		.clk_div_6(clk_4mhz),
		.clk_5ms(clk_5ms), 
		.clk_not_5ms(clk_not_5ms), 		
		.comparator(d), 
		.counter(q), 
		.reference(n_q),
		.spi_clk(spi_clk), 
		.spi_mosi(spi_mosi), 
		.spi_miso(spi_miso), 
		.spi_cs(spi_cs),
		.rst(reset)
		);

	
	
	always  begin
		#(400000) spi_cs <= 1'b0;
		#(100000) spi_cs <= 1'b1;
		end	
	always @(posedge clk1 or negedge spi_cs) begin
		if (!spi_cs) begin
			if (spi_divider >= SPI_SPEED) begin
				if (spi_clk_counter >= 88 && !spi_clk) #5 spi_divider <= 0 ;
				else begin
					#5 spi_divider <= 0;
					#5 spi_clk <= ~spi_clk;
					if (spi_clk) #5 spi_clk_counter <= spi_clk_counter + 1;
					end
				end
			else #5 spi_divider <= spi_divider + 1;
			end
		else begin 
			spi_clk <= 1'b0;
			spi_divider <= 8'd0;
			spi_clk_counter <= 8'd0;
			end
		end
	
	always @(posedge spi_clk) begin
		spi_mosi <= buffer>>spi_clk_counter;
		end
endmodule