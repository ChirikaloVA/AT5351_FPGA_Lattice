`timescale 1 ns / 1 ps

module testbench_spi();
	reg clk_12mhz;
	reg reset;
	
	wire [23:0] count_p; 
	wire [23:0] count_m;

	wire clk_4mhz;



	parameter SPI_SPEED = 2;			//spi clock divider
	parameter SPI_BITS = 8;				//spi clock ticks


	reg spi_clk, spi_mosi, spi_cs;	   
	wire spi_clk_wire;
	wire spi_mosi_wire;
	wire spi_cs_wire;
	assign 	 spi_clk_wire =   spi_clk;
	assign 	 spi_mosi_wire =   spi_mosi;
	assign 	 spi_cs_wire =   spi_cs;
	
	wire spi_miso;
	reg [7:0] spi_divider;
	reg [7:0] spi_clk_counter;
	reg [7:0] buffer0;
	reg [7:0] buffer1;
	reg ufm_sn;




	initial begin
		clk_12mhz <= 1'b0;
		reset <= 1'b1;
		//trigger <= 1'b0;	

		spi_clk <= 1'b0;
		spi_cs <= 1'b1;
		spi_mosi <= 1'b0;
		ufm_sn <= 1'b1;
		//spi_miso <= 1'b1;
		spi_divider <= 8'd0;
		spi_clk_counter <= 8'd0;
		buffer0 <= 8'h01;	//0x01
		buffer1 <= 8'h01;	//0x05	  	
		
		$display("Running 'spi' testbench");
		//#350 reset <= 1'b1;  
		
		#400 reset <= 1'b0;	   

		//#400000 trigger = 1'b1;
		//#1240000 trigger = 1'b0;


		#200000 $stop;
		$display("'spi' testbench stopped");
		end


	always begin
		#41.6 clk_12mhz <= ~clk_12mhz;
		end			  
		






	
	
	always  begin
		#(4000) spi_cs <= 1'b0;
		#(20000) spi_cs <= 1'b1;  
		buffer1 <= buffer1 + 8'b1;	   
		if (buffer1 == 8'hF) begin 
			buffer0 <= buffer0 + 8'b1;
			buffer1 <= 8'b0; 
		end
	end	
		
	reg [4:0] i = 0;
	
	always @(posedge clk_12mhz or negedge spi_cs) begin
		if (!spi_cs) begin
			if (spi_divider >= SPI_SPEED) begin	 
				if (i==0) begin
					if (spi_clk_counter == 8 && !spi_clk) begin
						#5 spi_divider <= 0 ;
						#1000 	  spi_clk_counter <= 0;	 
						i <= 1;
					end	
					else begin
						#5 spi_divider <= 0;
						#105 spi_clk <= ~spi_clk;
						if (spi_clk) #5 spi_clk_counter <= spi_clk_counter + 8'd1;
					end
				end
				else if (i==1) begin  
					if (spi_clk_counter == 8 && !spi_clk) begin
						#5 spi_divider <= 0 ;
						#1000 	  spi_clk_counter <= 0;	 
						i <= 2;
					end	
					else begin
						#5 spi_divider <= 0;
						#105 spi_clk <= ~spi_clk;
						if (spi_clk) #5 spi_clk_counter <= spi_clk_counter + 8'd1;
					end
				end
				else if (i==2) begin  
					if (spi_clk_counter == 8 && !spi_clk) begin
						#5 spi_divider <= 0 ;
						i <= 0;
					end	
					else begin
						#5 spi_divider <= 0;
						#105 spi_clk <= ~spi_clk;
						if (spi_clk) #5 spi_clk_counter <= spi_clk_counter + 8'd1;
					end
				end				
		
			end					   
					
					
			else #5 spi_divider <= spi_divider + 1;
			end
		else begin 
			spi_clk <= 1'b0;
			spi_divider <= 8'd0;
			spi_clk_counter <= 8'd0;  
			i <= 5'd0;  
			
		end	 
		
	end	 
		
		
	always @(posedge spi_clk) begin	 
		if (i==0) spi_mosi <= buffer0>>(8'd7 - spi_clk_counter);
		else if (i==1)	spi_mosi <= buffer1>>(8'd7 - spi_clk_counter);
		end



	top top(
		.clk(clk_12mhz), 
		.clk_div_6(), 
		.clk_5ms(), 
		.clk_not_5ms(), 
		.comparator(), 
		.counter(), 
		.reference(), 
		.spi_clk(spi_clk_wire), 
		.spi_mosi(spi_mosi_wire), 
		.spi_miso(spi_miso), 
		.spi_cs(spi_cs_wire),
		//.ufm_sn(ufm_sn),
		.rst(~reset),
		.clk_12mhz(),
		.count(),
		
		
		.input_sel	(),
		.mu_sel		(),
		.avk_sel	(),
		.ref_sel	(),
		.fil_sel	(),
		// AVK of capacitance
		.pos_comparator(),
		.neg_comparator(),
		.ref_avk(),
		.antibounce(),
		.pos_comparator1(),
		.neg_comparator1(),
		
		.cnt_choise()
		);


endmodule