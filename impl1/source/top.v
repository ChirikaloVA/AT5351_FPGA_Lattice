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
		output reg relay_reset,
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
		output wire antibounce,
		
		output wire [7:0] rd_data_out
		
		//input wire cnt_choise
		) /* synthesis GSR = 1 */	;


	wire adc_count; 
	wire reset;
	wire rst_sync;
	assign reset = ~rst;
	
		 
	wire [22:0] count_p;
	wire [22:0] count_m;



	wire cnt_in;
	wire cnt_en;
	
	wire [23:0] count;
	wire fifo_wr_en;
	
	


	
	wire [3:0] spi_cmd;
	wire [23:0] fifo_out;
	wire read_meas_data;
	wire [7:0] meas_data;
	wire [3:0] fifo_level;
	wire wr_data_read;
	wire spi_bit_0;
	
	wire fifo_empty; 
	wire fifo_full;
	wire fifo_ae;
	wire fifo_af;
	wire fifo_level_reset;
	
	wire prebuf_rd_en;
	wire fifo_control_rd_en;
	




		
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
    
	//wire rd_data_out;
	//assign wr_data_out = wr_data;
	assign rd_data_out = rd_data;
	assign wb_clk_i = clk_12mhz;
	assign wb_rst_i = rst_sync;
	
	wire spi_clk_out;



	wire PURNET;
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


	always @(posedge clk_12mhz or posedge rst_sync)
		if (rst_sync) relay_reset <= 1'b1;


	wire ref_avk_0;
	wire ref_avk_1;	

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
		.reference	(ref_avk_1),
		.antibounce	(antibounce),
		.clock_4mhz	(clk_4mhz), //4MHz	
		.clock_12mhz(clk_12mhz), //12MHz	
		.reset		(rst_sync)
		
		);





	wire fe_count, re_count;
	
	count_choise COUNT_CHOISE(
		.count_mode	(count_mode),
		.count1		(adc_count),
		.enable1	(1'b1),
		.count2		(ref_avk_1),
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
		.risingedge (re_count),
		.fallingedge(fe_count),
		.reset		(rst_sync)
		) /* synthesis syn_noprune = 1 */;


	
	count_prebufer COUNT_PREBUFFER (
		.clk_12mhz(clk_12mhz),
		.mode(count_mode),
		.count_m(count_m),
		.count_p(count_p),
		.count(count),
		.falling_edge(fe_count),
		.rising_edge(re_count),
		//.wr_en(),
		//.rd_en(prebuf_rd_en),
		//.spi_cmd(spi_cmd),
		//.fifo_full(fifo_full),
		//.fifo_level(fifo_level),
		.fifo_wr_en(fifo_wr_en),
		.reset(rst_sync)
		)/* synthesis syn_noprune = 1 */;
	
	FIFO FIFO(
		.Data(count), 
		.WrClock(clk_12mhz), 
		.RdClock(clk_12mhz), 
		.WrEn(fifo_wr_en), 
		.RdEn(fifo_rd_en), 
		.Reset(rst_sync), 
		.RPReset(fifo_level_reset), 
		.Q(fifo_out), 
		.Empty(fifo_empty), 
		.Full(fifo_full), 
		.AlmostEmpty(fifo_ae), 
		.AlmostFull(fifo_af)
		);

	fifo_control FIFO_CONTROL(
		.clk_12mhz(clk_12mhz),
		.fifo_out(fifo_out),
		//.fifo_control_rd_en(fifo_control_rd_en),
		.fifo_rd_en(fifo_rd_en),
		.fifo_wr_en(fifo_wr_en),
		.fifo_level(fifo_level),
		.fifo_empty(fifo_empty),
		.fifo_full(fifo_full),
		.fifo_level_reset(fifo_level_reset),
		
		.spi_bit_3      (spi_bit_3    ),
		.spi_bit_0      (spi_bit_0    ),		

		.read_meas_data(read_meas_data),
		.meas_data(meas_data),
		.spi_xfer_done(spi_xfer_done),
		.spi_cs(spi_cs),
		
		.rst_sync(rst_sync)		
		);
		

	
	

/*	highvoltage HV_not_ready(
		.clk(clk_12mhz),
		.vn_l(vn_l),
		.vn_h(vn_h),
		.vn_pol(vn_pol),
		.vn_on(vn_on),
		.reset(rst_sync)
		
		);
*/



	
	SPI_slave  SPI (
		.clk	(clk_12mhz), 
		.SCK	(spi_clk), 
		.MOSI	(spi_mosi), 
		.MISO	(spi_miso), 
		.SSEL	(spi_cs), 
		.rx		(rd_data), 
		.tx		(wr_data), 
		.read_tx(wr_data_read),
		.byte_received(wb_xfer_done),
		.reset	(rst_sync)	
		
		)/* synthesis syn_noprune = 1 */;
		
/*	
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
 */                                 
   main_ctrl main_ctrl_inst (
		.clk            (clk_12mhz    ),
		.rst_n          (rst_sync     ),
		.spi_csn        (spi_cs       ),
		.spi_clk        (spi_clk      ),
		.wr_data_read   (wr_data_read ),
		.spi_bit_3      (spi_bit_3    ),
		.spi_bit_0      (spi_bit_0    ),
		//.address        (address      ), 
		//.wr_en          (wr_en        ),
		.wr_data        (wr_data      ),
		//.rd_en          (rd_en        ),    
		.rd_data        (rd_data      ),
		.wb_xfer_done   (wb_xfer_done ),
		.wb_xfer_req    (wb_xfer_req  ),
		.spi_xfer_done	(spi_xfer_done),
		
		.input_sel	(input_sel),
		.mu_sel		(mu_sel),
		.avk_sel	(avk_sel),
		//.ref_sel	(ref_sel),
		.ref_sel	(ref_avk),
		.fil1_sel	(fil1_sel),
		.fil2_sel	(fil2_sel),
		.relay_reset(),
		.cs_out	({relay_cs, comp2_cs, comp1_cs}),
		
		.count_mode(count_mode),
		.ref_avk_1(ref_avk_1),
		.read_meas_data(read_meas_data),
		.meas_data(meas_data),
		.fifo_level(fifo_level),
		.fifo_level_reset(fifo_level_reset),
		.spi_cmd(spi_cmd)
		//);
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








module fifo_control(
		input wire clk_12mhz,
		input wire [23:0] fifo_out,
		//output wire fifo_control_rd_en,
		output wire fifo_rd_en,
		input wire fifo_wr_en,
		output reg [3:0] fifo_level,
		input wire fifo_empty,
		input wire fifo_full,
		input wire fifo_level_reset,
		input wire spi_bit_3,
		input wire spi_bit_0,

		input wire read_meas_data,
		output reg [7:0] meas_data,
		input wire spi_xfer_done,
		input wire spi_cs,
		
		input wire rst_sync
		);
	
	
	
	//reg fifo_rd_en;
	//wire fifo_rd_en_w;

	
	reg [7:0] fifo_buffer_out [0:2];
	wire [7:0] fifo_buffer_out_w2;
	wire [7:0] fifo_buffer_out_w1;
	wire [7:0] fifo_buffer_out_w0;
	
	
	reg [1:0] fifo_buffer_out_count;
	reg reading_fifo;
	reg new_transfer;


	reg fifo_rd_en_buf0;
	reg fifo_rd_en_buf1;
	reg fifo_rd_en_buf2;
	
	assign fifo_control_rd_en = (read_meas_data && !fifo_buffer_out_count && !reading_fifo) ? 1'b1 : 1'b0;	
	 
    reg        spi_csn_buf0_p;    // The postive-egde sampling of spi_csn
    reg        spi_csn_buf1_p;    // The postive-egde sampling of spi_csn_buf0_p 
	
	reg read_meas_data_buf0;

	assign fifo_buffer_out_w2 = (fifo_rd_en_buf1) ? fifo_out[23:16] : fifo_buffer_out[2];
	assign fifo_buffer_out_w1 = (fifo_rd_en_buf1) ? fifo_out[15:8] : fifo_buffer_out[1];
	assign fifo_buffer_out_w0 = (fifo_rd_en_buf1) ? fifo_out[7:0] : fifo_buffer_out[0];
	
			
			reg prebuf_rd_en;
			assign fifo_rd_en = prebuf_rd_en | fifo_control_rd_en;
		
		
			initial begin
				prebuf_rd_en <= 1'b0;
				end
		
			always @(posedge clk_12mhz or posedge rst_sync) begin
				if (rst_sync) prebuf_rd_en <= 1'b0;
				else begin
					/*	Если буфер FIFO наполняется до предела, необходимо прочесть один байт,
						чтобы при обращении мастера в буфере были актуальные данные
					*/
					if (fifo_full && !prebuf_rd_en && fifo_level == 4'd8) prebuf_rd_en <= 1'b1;
					else prebuf_rd_en <= 1'b0;
					end
				end
	
	
	 // Bufferring spi_csn with postive edge                    
    always @(posedge clk_12mhz or posedge rst_sync)
       if (rst_sync)
          spi_csn_buf0_p <= 1'b1;
       else
          spi_csn_buf0_p <= spi_cs;
              
    // Bufferring spi_csn_buf0_p with postive edge                    
    always @(posedge clk_12mhz or posedge rst_sync)
       if (rst_sync)
          spi_csn_buf1_p <= 1'b1;
       else
          spi_csn_buf1_p <= spi_csn_buf0_p;

	 
	 
	always @(posedge clk_12mhz or posedge rst_sync)
		if (rst_sync) new_transfer <= 1'b0;
 		else begin
			if (spi_csn_buf1_p) new_transfer <= 1'b1;
			else if (read_meas_data) new_transfer <= 1'b0;
			end
	
	
	always @(posedge clk_12mhz or posedge rst_sync)
		if (rst_sync) fifo_rd_en_buf0 <= 1'b0;
 		else fifo_rd_en_buf0 <= fifo_control_rd_en;
	
	always @(posedge clk_12mhz or posedge rst_sync)
		if (rst_sync) fifo_rd_en_buf1 <= 1'b0;
 		else fifo_rd_en_buf1 <= fifo_rd_en_buf0;
	
	always @(posedge clk_12mhz or posedge rst_sync)
		if (rst_sync) fifo_rd_en_buf2 <= 1'b0;
 		else fifo_rd_en_buf2 <= fifo_rd_en_buf1;


	always @(posedge clk_12mhz or posedge rst_sync)
		if (rst_sync) read_meas_data_buf0 <= 1'b0;
 		else read_meas_data_buf0 <= read_meas_data;
	

	//assign meas_data = (fifo_buffer_out_count == 2'd0) ? fifo_buffer_out_w0 : (fifo_buffer_out_count == 2'd1) ? fifo_buffer_out_w1 : (fifo_buffer_out_count == 2'd2) ? fifo_buffer_out_w2;
	
	always @(posedge clk_12mhz or posedge rst_sync) begin
		if (rst_sync) begin
			fifo_level <= 4'd0;
			reading_fifo <= 1'b0;
			fifo_buffer_out_count <= 2'd0;
			meas_data <= 8'd0;
			//fifo_rd_en <= 1'b0;
 			//fifo_wr_en <= 1'b0;
 			end
		else begin
			if (fifo_wr_en && fifo_level < 4'd15) fifo_level <= fifo_level + 4'd1;
			if (fifo_rd_en && fifo_level > 4'd0) fifo_level <= fifo_level - 4'd1;
			if (fifo_level_reset || fifo_empty) fifo_level <= 4'd0;
				
			//if (read_meas_data && !fifo_buffer_out_count) begin
				////fifo_rd_en <= 1'b1;
				//reading_fifo <= 1'b1;
				//end
			if (spi_bit_0 && fifo_buffer_out_count == 4'd0 && !new_transfer) reading_fifo <= 1'b0;
				
			//if (read_meas_data_buf0 && fifo_buffer_out_count < 2'd2 && fifo_buffer_out_count) begin
				//meas_data <= fifo_buffer_out[fifo_buffer_out_count];
				//reading_fifo <= 1'b1;
				
				//end
			//else if (read_meas_data_buf0 && fifo_buffer_out_count == 2'd2) begin
				//meas_data <= fifo_buffer_out[fifo_buffer_out_count];
				//reading_fifo <= 1'b1;
				//end
			if (read_meas_data) begin
				meas_data <= fifo_buffer_out[fifo_buffer_out_count];
				reading_fifo <= 1'b1;
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
				
			//if (spi_bit_0 && fifo_buffer_out_count == 2'd1) reading_fifo <= 1'b0;
							
			if (read_meas_data && fifo_buffer_out_count < 2'd2) begin
				fifo_buffer_out_count <= fifo_buffer_out_count + 2'd1;
				end
			//else if (read_meas_data && !fifo_buffer_out_count && !new_transfer) 
				//fifo_buffer_out_count <= fifo_buffer_out_count + 2'd1;
			else if (read_meas_data && fifo_buffer_out_count == 2'd2) begin
				fifo_buffer_out_count <= 2'd0;
				end	
			if (spi_xfer_done) fifo_buffer_out_count <= 2'd0;
			end
		end
		
endmodule


	


