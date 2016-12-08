`timescale 1 ns / 1 ps

module top(
	clk, 
	clk_div_6, 
	clk_5ms, 
	clk_not_5ms, 
	comparator, 
	counter, 
	reference, 
	spi_clk, 
	spi_mosi, 
	spi_miso, 
	spi_cs, 
	rst,
	clk_12mhz,
	count,
	
	// AVK of capacitance
	pos_comparator,
	neg_comparator,
	ref_avk,
	antibounce,
	pos_comparator1,
	neg_comparator1,
	
	cnt_choise
	) /* synthesis GSR = "ENABLED" */	;

//
	input wire clk;
	output wire clk_12mhz;
	
	input pos_comparator;
	input neg_comparator;
	output antibounce;
	output pos_comparator1;
	output neg_comparator1;
	assign pos_comparator = pos_comparator1;
	assign neg_comparator = neg_comparator1;

	
	output wire [7:0] count;
	
	assign clk_12mhz = clk;
	//wire clk;
	output wire clk_div_6;
	output wire clk_5ms;
	output wire clk_not_5ms;
	input wire comparator;
	output wire counter;
	//wire counter;
	
	output wire reference;
	input wire spi_clk;
	input wire spi_mosi; 
	output tri spi_miso; 
	input wire spi_cs;
	input wire rst			;
	
	wire reset;
	wire rst_sync;
	assign reset = ~rst;
	PUR PUR_INST (.PUR (PURNET));
	defparam PUR_INST.RST_PULSE = 100;	
	GSR GSR_INST (.GSR (reset));
		
	reset RESET_SYNC(
		.async_reset(reset),
		.sync_reset(rst_sync),
		.clk(clk)
		)/* synthesis syn_noprune = 1 */;
		
	//wire osc_clk;  
	//   Internal Oscillator
	//   defparam OSCH_inst.NOM_FREQ = "2.08";	//  This is the default frequency
	//defparam OSCH_inst.NOM_FREQ = "12.09"; 
	
	//OSCH OSCH_inst( .STDBY(1'b0), //  0=Enabled, 1=Disabled 
									  //also Disabled with Bandgap = OFF
					//.OSC(osc_clk),
					//.SEDSTDBY());//  this signal is not required if not//  using SED
	
	//assign clk =  osc_clk & osc_clk; /* synthesis syn_keep = 1 */
	
		
	//clock_div_6 CLK_2MHZ(
		//.clk_in(clk), 
		////.reset(reset),
		//.clk_div_6(clk_div_6)							
		//) /* synthesis syn_noprune = 1 */;
	//clock_5ms CLK_5MS(
		//.clk_div_6(clk_div_6),
		//.reset(reset),		
		//.clk_5ms(clk_5ms),
		//.clk_not_5ms(clk_not_5ms)
		//) /* synthesis syn_noprune = 1 */;		
			
	clock_4mhz CLK_4MHZ(
		.clk_in(clk),
		.clk_4mhz(clk_div_6),
		.reset(rst_sync)
		) /* synthesis syn_noprune = 1 */;
	clock_5ms CLK_5MS(
		.clk_4mhz(clk_div_6), 
		.reset(rst_sync), 
		.clk_5ms(clk_5ms), 
		.clk_not_5ms(clk_not_5ms)
		) /* synthesis syn_noprune = 1 */;						


	wire [23:0] count_p;
	wire [23:0] count_m;
	assign count = ~count_p[7:0];
	
	ADC_trigger ADC_trigger(
		.clk(clk_div_6), 
		.d(comparator), 
		.q(counter), 
		.n_q(reference),
		.reset(rst_sync)
		);
	
	//Pulse_Counter Pulse_Counter(
		//.clk(clk), 
		//.clk_div_6(clk_div_6), 
		//.trigger(counter), 
		//.reset(rst_sync),
		//.count_p(count_p), 
		//.count_m(count_m)
		//) ;





	output ref_avk;
	

	avk_capacitance AVK_CAPACITANCE(
		.pos_comparator(pos_comparator),
		.neg_comparator(neg_comparator),
		.reference(ref_avk),
		.antibounce(antibounce),
		.clock_4mhz(clk_div_6), //4MHz	
		.clock_12mhz(clk), //4MHz	
		.reset(rst_sync)
		
		);


	//reg cnt_choise_reg = 1'b0;
	//reg cnt_in = 1'b0;
	//reg cnt_en = 1'b0;
	////assign cnt_choise = cnt_choise_reg;
	input cnt_choise;
	
	
	//always begin
		//if (cnt_choise) begin
			//cnt_in <= ref_avk;
			//cnt_en <= antibounce;
			//end
		//else begin
			//cnt_in <= counter;
			//cnt_en <= 1'b1;
			//end
		//end
	
	wire cnt_in;
	wire cnt_en;
	count_choise COUNT_CHOISE(
		.cnt_choise(cnt_choise),
		.count1(counter),
		.enable1(1'b1),
		.count2(ref_avk),
		.enable2(antibounce),
		.count(cnt_in),
		.enable(cnt_en)
		);
	
	counter COUNTER(
		.clk_12mhz(clk),
		.clk_4mhz(clk_div_6),
		.cnt(cnt_in),
		.en(cnt_en),
		.count_p(count_p),
		.count_m(count_m),
		
		.reset(rst_sync)
		);


/*	SPI_slave SPI(
		.clk(clk), 
		.SCK(spi_clk), 
		.MOSI(spi_mosi), 
		.MISO(spi_miso), 
		.SSEL(spi_cs), 
		.count({count_p[23:0], count_m[23:0]}),
		.reset(reset)

		);	*/
		
		
	//pwm PWM(
		//.clk(clk_div_6),
		//.reset(reset),
		//.pwm(pwm)
		//) /* synthesis syn_noprune = 1 */;
	//wire       wb_clk_i;
	//wire       wb_rst_i;
	//wire       wb_cyc_i;
	//wire       wb_stb_i;
	//wire       wb_we_i;
	//wire [7:0] wb_adr_i;
	//wire [7:0] wb_dat_i;
	//wire [7:0] wb_dat_o;
	//wire       wb_ack_o; 
									  
	//wire [7:0] address;                       
	//wire       wr_en;                               
	//wire [7:0] wr_data;                       
	//wire       rd_en;                               
	//wire [7:0] rd_data;                       
	//wire       wb_xfer_done;                           
	//wire       wb_xfer_req;
	
	//assign wb_clk_i = clk;
	//assign wb_rst_i = rst_sync;
	
	//SPI  SPI (
		//.wb_clk_i(wb_clk_i), 
		//.wb_rst_i(wb_rst_i), 
		//.wb_cyc_i(wb_cyc_i), 
		//.wb_stb_i(wb_stb_i), 
		//.wb_we_i(wb_we_i), 
		//.wb_adr_i(wb_adr_i), 
		//.wb_dat_i(wb_dat_i), 
		//.wb_dat_o(wb_dat_o), 
		//.wb_ack_o(wb_ack_o), 
		//.spi_clk(spi_clk), 
		//.spi_miso(spi_miso), 
		//.spi_mosi(spi_mosi), 
		//.spi_scsn(spi_cs)
		//);
				
		

	//wb_ctrl Wisbone_Control(
		//.wb_clk_i(wb_clk_i), // WISHBONE clock 
		//.wb_rst_i(wb_rst_i), // WISHBONE reset
		//.wb_cyc_i(wb_cyc_i), // WISHBONE bus cycle
		//.wb_stb_i(wb_stb_i), // WISHBONE strobe
		//.wb_we_i(wb_we_i),  // WISHBONE write/read control
		//.wb_adr_i(wb_adr_i), // WISHBONE address
		//.wb_dat_i(wb_dat_i), // WISHBONE input data
		//.wb_dat_o(wb_dat_o), // WISHBONE output data
		//.wb_ack_o(wb_ack_o), // WISHBONE transfer acknowledge
		//.address(address),  // Local address
		//.wr_en(wr_en),    // Local write enable
		//.wr_data(wr_data),  // Local write data
		//.rd_en(rd_en),    // Local read enable
		//.rd_data(rd_data),  // Local read data
		//.xfer_done(wb_xfer_done),// WISHBONE transfer done
		//.xfer_req(wb_xfer_req)  // WISHBONE transfer request
		//);	
                                  
   //main_ctrl main_ctrl_inst (
                   //.clk            (clk          ),
                   //.rst_n          (rst_sync        ),
                   //.spi_csn        (spi_cs         ),
                   //.address        (address      ), 
                   //.wr_en          (wr_en        ),
                   //.wr_data        (wr_data      ),
                   //.rd_en          (rd_en        ),    
                   //.rd_data        (rd_data      ),
                   //.wb_xfer_done   (wb_xfer_done ),
                   //.wb_xfer_req    (wb_xfer_req  ),

					//.en_port(),      // Genaral purpose enable port
					//.gpi_ld(),       // GPI latch
					//.gpio_wr(),      // GPIO write (high) and read (low)
					//.gpio_addr(),    // GPIO port address                     
					//.gpio_dout(),    // GPIO port output data bus
					//.gpio_din(),     // GPIO port input data bus
					//.mem_wr(),       // Memory write (high) and read (low)
					//.mem_addr(),     // Memory address
					//.mem_wdata(),    // Memory write data bus
					//.mem_rdata(),    // Memory read data bus
					//.irq_status(),   // IRQ status     
					//.irq_en(),       // IRQ enable
					//.irq_clr()       // IRQ clear				   
                   //);
	
	
	

	
endmodule



module reset(
	input wire async_reset,
	output wire sync_reset,
	input wire clk
	);
	
	reg reset_out, rff1;
	assign 	sync_reset = reset_out;
	
	always @(posedge clk or posedge async_reset) begin
		if (async_reset) {reset_out, rff1} <= 2'b0;
		else {reset_out, rff1} <= {rff1, 1'b1} ;
		end
		
endmodule





	


