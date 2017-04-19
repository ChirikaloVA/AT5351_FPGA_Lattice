`timescale 1 ns / 1 ps

module top(
		input wire clk_12mhz, 
		output wire clk_4mhz, 
		output wire clk_5ms, 
		output wire clk_not_5ms, 
		input wire adc_comp, 
		output wire adc_countn, 
		input wire spi_clk, 
		input wire spi_mosi, 
		output tri spi_miso, 
		input wire spi_cs, 
		input wire rst,
		output wire comp1_cs,
		output wire comp2_cs,
		output wire relay_cs,
		output wire relay_reset,
		//output wire vn_cs,
		//input wire 	vn_l,
		//input wire 	vn_h,
		//output wire vn_pol,
		//output wire vn_on,
		
		
		output wire	[3:0]	input_sel,
		output wire [2:0]	mu_sel,
		output wire [3:0]	avk_sel,
		output wire			fil1_sel,
		output wire			fil2_sel,


		// AVK of capacitance
		input wire pos_comparator,
		input wire neg_comparator,
		output wire ref_avk,
		output wire antibounce
		
		//input wire cnt_choise
		) /* synthesis GSR = "ENABLED" */	;


	wire adc_count; 
	wire reset;
	wire rst_sync;
	assign reset = ~rst;
	

	
	PUR PUR_INST (.PUR (PURNET));
	defparam PUR_INST.RST_PULSE = 100;	
	GSR GSR_INST (.GSR (reset));
		
	reset RESET_SYNC(
		.async_reset(reset),
		.sync_reset(rst_sync),
		.clk(clk_12mhz)
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
	
		
			
	clock_4mhz CLK_4MHZ(
		.clk_12mhz		(clk_12mhz),
		.clk_4mhz		(clk_4mhz),
		.reset			(rst_sync)
		) /* synthesis syn_noprune = 1 */;
	clock_5ms CLK_5MS(
		.clk_4mhz		(clk_4mhz), 
		.reset			(rst_sync), 
		.clk_5ms		(clk_5ms), 
		.clk_not_5ms	(clk_not_5ms)
		) /* synthesis syn_noprune = 1 */;						


	wire [23:0] count_p;
	wire [23:0] count_m;

	ADC_trigger ADC_trigger(
		.clk	(clk_4mhz), 
		.d		(adc_comp), 
		.q		(adc_count), 
		.n_q	(adc_countn),
		.reset	(rst_sync)
		);

	avk_capacitance AVK_CAPACITANCE(
		.pos_comparator(pos_comparator),
		.neg_comparator(neg_comparator),
		.reference	(ref_avk),
		.antibounce	(antibounce),
		.clock_4mhz	(clk_4mhz), //4MHz	
		.clock_12mhz(clk_12mhz), //12MHz	
		.reset		(rst_sync)
		
		);


	wire cnt_in;
	wire cnt_en;
	count_choise COUNT_CHOISE(
		.count_mode	(count_mode),
		.count1		(adc_count),
		.enable1	(1'b1),
		.count2		(ref_avk),
		.enable2	(antibounce),
		.count		(cnt_in),
		.enable		(cnt_en)
		);
	
	counter COUNTER(
		.clk_12mhz	(clk_12mhz),
		.clk_4mhz	(clk_4mhz),
		.cnt		(cnt_in),
		.en			(cnt_en),
		.count_p	(count_p),
		.count_m	(count_m),
		.reset		(rst_sync)
		);


	wire [23:0] count;
	wire fifo_wr_en;
	reg fifo_rd_en;
	wire fifo_rd_en_w;

	
	
	wire [23:0] fifo_out;
	
	wire spi_xfer_done;
	reg [3:0] fifo_level;
	reg [7:0] fifo_buffer_out [0:2];
	wire [7:0] fifo_buffer_out_w2;
	wire [7:0] fifo_buffer_out_w1;
	wire [7:0] fifo_buffer_out_w0;
	
	
	reg [1:0] fifo_buffer_out_count;
	reg reading_fifo;
	
	wire read_meas_data;
	reg [7:0] meas_data;
	
	wire [3:0] spi_cmd;
	
	
	count_prebufer COUNT_PREBUFFER (
		.clk_12mhz(clk_12mhz),
		.mode(count_mode),
		.count_m(count_m),
		.count_p(count_p),
		.count(count),
		.wr_en(fifo_wr_en),
		.spi_cmd(spi_cmd),
		.fifo_level(fifo_level),
		.reset(rst_sync)
		);
	
	FIFO FIFO(
		.Data(count), 
		.WrClock(clk_12mhz), 
		.RdClock(clk_12mhz), 
		.WrEn(fifo_wr_en), 
		.RdEn(fifo_rd_en_w), 
		.Reset(rst_sync), 
		.RPReset(rst_sync), 
		.Q(fifo_out), 
		.Empty(), 
		.Full(), 
		.AlmostEmpty(), 
		.AlmostFull()
		);


	wire spi_bit_3;
	reg fifo_rd_en_buf0;
	reg fifo_rd_en_buf1;
	reg fifo_rd_en_buf2;
	
	assign fifo_rd_en_w = (read_meas_data && !fifo_buffer_out_count) ? 1 : 0;	
	
	
	always @(posedge clk_12mhz or posedge rst_sync)
		if (rst_sync) fifo_rd_en_buf0 <= 1'b0;
 		else fifo_rd_en_buf0 <= fifo_rd_en_w;
	
	always @(posedge clk_12mhz or posedge rst_sync)
		if (rst_sync) fifo_rd_en_buf1 <= 1'b0;
 		else fifo_rd_en_buf1 <= fifo_rd_en_buf0;
	
	always @(posedge clk_12mhz or posedge rst_sync)
		if (rst_sync) fifo_rd_en_buf2 <= 1'b0;
 		else fifo_rd_en_buf2 <= fifo_rd_en_buf1;

	reg read_meas_data_buf0;
	always @(posedge clk_12mhz or posedge rst_sync)
		if (rst_sync) read_meas_data_buf0 <= 1'b0;
 		else read_meas_data_buf0 <= read_meas_data;
	
	assign fifo_buffer_out_w2 = (fifo_rd_en_buf1) ? fifo_out[23:16] : fifo_buffer_out[2];
	assign fifo_buffer_out_w1 = (fifo_rd_en_buf1) ? fifo_out[15:8] : fifo_buffer_out[1];
	assign fifo_buffer_out_w0 = (fifo_rd_en_buf1) ? fifo_out[7:0] : fifo_buffer_out[0];
	
	//assign meas_data = (fifo_buffer_out_count == 2'd0) ? fifo_buffer_out_w0 : (fifo_buffer_out_count == 2'd1) ? fifo_buffer_out_w1 : (fifo_buffer_out_count == 2'd2) ? fifo_buffer_out_w2;
	
	always @(posedge clk_12mhz or posedge rst_sync) begin
		if (rst_sync) begin
			fifo_level <= 4'd0;
			reading_fifo <= 1'b0;
			fifo_buffer_out_count <= 2'd0;
			fifo_rd_en <= 1'b0;
 			//fifo_wr_en <= 1'b0;
 			end
		else begin
			if (fifo_wr_en && fifo_level < 4'd15) fifo_level <= fifo_level + 4'd1;
			if (fifo_rd_en_w && fifo_level > 4'd0) fifo_level <= fifo_level - 4'd1;
			
			if (read_meas_data && !fifo_buffer_out_count) begin
				//fifo_rd_en <= 1'b1;
				reading_fifo <= 1'b1;
				end

			else if (read_meas_data_buf0 && fifo_buffer_out_count < 2'd2 && fifo_buffer_out_count) begin
				meas_data <= fifo_buffer_out[fifo_buffer_out_count];
				reading_fifo <= 1'b1;
				
				end
			else if (read_meas_data_buf0 && fifo_buffer_out_count == 2'd2) begin
				meas_data <= fifo_buffer_out[fifo_buffer_out_count];
				reading_fifo <= 1'b1;
				
				
				//fifo_rd_en <= 1'b1;
				//fifo_buffer_out[2] <= fifo_out[23:16];
				//fifo_buffer_out[1] <= fifo_out[15:8];
				//fifo_buffer_out[0] <= fifo_out[7:0];
				end
			//else if (!read_meas_data) fifo_rd_en <= 1'b0;
				
			//else if (fifo_rd_en) begin
				//fifo_rd_en <= 1'b0;
				//end
			else if (fifo_rd_en_buf1) begin
				fifo_buffer_out[2] <= fifo_out[23:16];
				fifo_buffer_out[1] <= fifo_out[15:8];
				fifo_buffer_out[0] <= fifo_out[7:0];
				//meas_data <= fifo_out[7:0];
				//fifo_buffer_out_count <= fifo_buffer_out_count + 2'd1;
				end
			else if (fifo_rd_en_buf2) begin
				meas_data <= fifo_buffer_out[0];
				//fifo_buffer_out_count <= fifo_buffer_out_count + 2'd1;
				end	
				
			if (read_meas_data && fifo_buffer_out_count < 2'd2) begin
				fifo_buffer_out_count <= fifo_buffer_out_count + 2'd1;
				end
			else if (read_meas_data && fifo_buffer_out_count == 2'd2) begin
				fifo_buffer_out_count <= 2'd0;
				end	
			if (spi_xfer_done) fifo_buffer_out_count <= 2'd0;
			end
		end

/*	highvoltage HV_not_ready(
		.clk(clk_12mhz),
		.vn_l(vn_l),
		.vn_h(vn_h),
		.vn_pol(vn_pol),
		.vn_on(vn_on),
		.reset(rst_sync)
		
		);
*/

/*	SPI_slave SPI(
		.clk(clk), 
		.SCK(spi_clk), 
		.MOSI(spi_mosi), 
		.MISO(spi_miso), 
		.SSEL(spi_cs), 
		.count({count_p[23:0], count_m[23:0]}),
		.reset(reset)

		);	*/
		
		
	wire       wb_clk_i;
	wire       wb_rst_i;
	wire       wb_cyc_i;
	wire       wb_stb_i;
	wire       wb_we_i;
	wire [7:0] wb_adr_i;
	wire [7:0] wb_dat_i;
	wire [7:0] wb_dat_o;
	wire       wb_ack_o; 
									  
	wire [7:0] address;                       
	wire       wr_en;                               
	wire [7:0] wr_data;                       
	wire       rd_en;                               
	wire [7:0] rd_data;                       
	wire       wb_xfer_done;                           
	wire       wb_xfer_req;
	
	wire 	   spi_irq;
    
	
	assign wb_clk_i = clk_12mhz;
	assign wb_rst_i = rst_sync;
	
	SPI  SPI (
		.wb_clk_i	(wb_clk_i), 
		.wb_rst_i	(wb_rst_i), 
		.wb_cyc_i	(wb_cyc_i), 
		.wb_stb_i	(wb_stb_i), 
		.wb_we_i	(wb_we_i), 
		.wb_adr_i	(wb_adr_i), 
		.wb_dat_i	(wb_dat_i), 
		.wb_dat_o	(wb_dat_o), 
		.wb_ack_o	(wb_ack_o), 
		.spi_clk	(spi_clk), 
		.spi_miso	(spi_miso), 
		.spi_mosi	(spi_mosi), 
		.spi_scsn	(spi_cs), 
		.spi_irq	(spi_irq)

		)/* synthesis syn_noprune = 1 */;
		
	
	wb_ctrl Wisbone_Control(
		.wb_clk_i	(wb_clk_i), // WISHBONE clock 
		.wb_rst_i	(wb_rst_i), // WISHBONE reset
		.wb_cyc_i	(wb_cyc_i), // WISHBONE bus cycle
		.wb_stb_i	(wb_stb_i), // WISHBONE strobe
		.wb_we_i	(wb_we_i),  // WISHBONE write/read control
		.wb_adr_i	(wb_adr_i), // WISHBONE address
		.wb_dat_i	(wb_dat_i), // WISHBONE input data
		.wb_dat_o	(wb_dat_o), // WISHBONE output data
		.wb_ack_o	(wb_ack_o), // WISHBONE transfer acknowledge
		.address	(address),  // Local address
		.wr_en		(wr_en),    // Local write enable
		.wr_data	(wr_data),  // Local write data
		.rd_en		(rd_en),    // Local read enable
		.rd_data	(rd_data),  // Local read data
		.xfer_done	(wb_xfer_done),// WISHBONE transfer done
		.xfer_req	(wb_xfer_req)  // WISHBONE transfer request
		);	
                                  
   main_ctrl main_ctrl_inst (
		.clk            (clk_12mhz    ),
		.rst_n          (rst_sync     ),
		.spi_csn        (spi_cs       ),
		.spi_clk        (spi_clk      ),
		.spi_bit_3      (spi_bit_3    ),
		.address        (address      ), 
		.wr_en          (wr_en        ),
		.wr_data        (wr_data      ),
		.rd_en          (rd_en        ),    
		.rd_data        (rd_data      ),
		.wb_xfer_done   (wb_xfer_done ),
		.wb_xfer_req    (wb_xfer_req  ),
		.spi_xfer_done	(spi_xfer_done),
		
		.input_sel	(input_sel),
		.mu_sel		(mu_sel),
		.avk_sel	(avk_sel),
		//.ref_sel	(ref_sel),
		.ref_sel	(),
		.fil1_sel	(fil1_sel),
		.fil2_sel	(fil2_sel),
		.relay_reset(relay_reset),
		.cs_out	({relay_cs, comp2_cs, comp1_cs}),
		.fifo_data(fifo_out),//		.fifo_rd_en(fifo_rd_en),
		.count_mode(count_mode),
		.read_meas_data(read_meas_data),
		.meas_data(meas_data),
		.fifo_level(fifo_level),
		.spi_cmd(spi_cmd)
		)/* synthesis syn_noprune = 1 */;
	
endmodule



module reset(
		input wire async_reset,
		output wire sync_reset,
		input wire clk
		);
	
	reg reset_out, rff1;
	assign 	sync_reset = ~reset_out;
	
	always @(posedge clk or posedge async_reset) begin
		if (async_reset) {reset_out, rff1} <= 2'b0;
		else {reset_out, rff1} <= {rff1, 1'b1} ;
		end
		
endmodule





	


