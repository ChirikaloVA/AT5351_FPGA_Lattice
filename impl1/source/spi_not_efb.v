`timescale 1 ns / 1 ns

module SPI_slave(clk, SCK, MOSI, MISO, SSEL, rx, tx, read_tx, byte_received, reset) ;
				
	input clk; 
	input SCK; 
	input MOSI 			/* synthesis syn_keep = 1 */; 
	output tri MISO; 
	input SSEL; 
	input wire [7:0] tx;
	output reg [7:0] rx;
	input wire read_tx;
	output wire byte_received;  // high when a byte has been received
	
	input reset;
	//wire reset = SSEL;

	//reg miso_out;
	//reg MISO;
	reg [7:0] byte_data_received			/* synthesis syn_keep = 1 */;


	
	// sync SCK to the FPGA clock using a 3-bits shift register
	//reg [2:0] SCKr			/* synthesis syn_keep = 1 */;	  
	//always @(posedge clk) SCKr <= {SCKr[1:0], SCK};
	//wire SCK_risingedge = (SCKr[2:1]==2'b01)		/* synthesis syn_keep = 1 */;  // now we can detect SCK rising edges
	//wire SCK_fallingedge = (SCKr[2:1]==2'b10)		/* synthesis syn_keep = 1 */;  // and falling edges

	// sync SCK to the FPGA clock using a 2-bits shift register
	reg [1:0] SCKr			/* synthesis syn_keep = 1 */;	  
	always @(posedge clk) SCKr <= {SCKr[0], SCK};
	wire SCK_risingedge = (SCKr==2'b01)		/* synthesis syn_keep = 1 */;  // now we can detect SCK rising edges
	wire SCK_fallingedge = (SCKr==2'b10)		/* synthesis syn_keep = 1 */;  // and falling edges

	// same thing for SSEL
	reg [2:0] SSELr			/* synthesis syn_keep = 1 */;  
	always @(posedge clk) SSELr <= {SSELr[1:0], SSEL};
	wire SSEL_active = ~SSELr[1]					/* synthesis syn_keep = 1 */;  // SSEL is active low
	wire SSEL_startmessage = (SSELr[2:1]==2'b10)	/* synthesis syn_keep = 1 */	;  // message starts at falling edge
	wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge

	// and for MOSI
	reg [1:0] MOSIr 				/* synthesis syn_keep = 1 */;  
	always @(posedge clk) MOSIr <= {MOSIr[0], MOSI};
	wire MOSI_data = MOSIr[1] 		/* synthesis syn_keep = 1 */;
	// we handle SPI in 8-bits format, so we need a 3 bits counter to count the bits as they come in
	
	reg [2:0] bitcnt 				/* synthesis syn_keep = 1 */;
	//reg [7:0] byte_data_received 	/* synthesis syn_keep = 1 */;
	always @(posedge clk) begin
		if (reset) begin
			bitcnt <= 3'b000;
			//byte_data_received <= 8'd0;	
			byte_data_received <= 8'd0;	
			end			
		else begin
			if (~SSEL_active) begin 
				bitcnt <= 3'b000;
				//byte_data_received <= 8'd0;
				byte_data_received <= 8'd0;
				end
			else  begin
				if(SCK_fallingedge) begin
					bitcnt <= bitcnt + 3'b001;
					// implement a shift-left register (since we receive the data MSB first)
					//byte_data_received <= {byte_data_received[6:0], MOSI_data};
					byte_data_received <= {byte_data_received[6:0], MOSI_data};
					end
				end
			end
	end

	//wire byte_received				/* synthesis syn_keep = 1 */;  // high when a byte has been received
	reg byte_received_buf1;
	reg byte_received_buf2;
	wire byte_received_buf0;
	assign byte_received_buf0 = SSEL_active && SCK_fallingedge && (bitcnt==3'b111);

	always @(posedge clk or posedge reset) begin
		if (reset) 	rx <= 8'd0;
		else begin
			if (byte_received_buf1) rx <= byte_data_received;
			end
		end
	
	always @(posedge clk or posedge reset)
		if (reset) byte_received_buf1 <= 1'b0;
		else byte_received_buf1 <= byte_received_buf0;
	
	always @(posedge clk or posedge reset)
		if (reset) byte_received_buf2 <= 1'b0;
		else byte_received_buf2 <= byte_received_buf1;
	assign byte_received = byte_received_buf2;
	



	wire byte_start;
	assign byte_start = SSEL_active && SCK_risingedge && (bitcnt==3'b000);
	
	// we use the LSB of the data received to control an LED
	reg [4:0] byte_count			/* synthesis syn_keep = 1 */;
	
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			byte_count <= 5'h0;
			end			
		else begin
			if (~SSEL_active) begin
				byte_count <= 5'h0;
				end
			else begin
				if(byte_received) begin

					byte_count <= byte_count + 5'd1;
					end		
				end
			end
		end
	

	reg [7:0] byte_data_sent			/* synthesis syn_keep = 1 */;

	//reg [7:0] cnt = 8'h0;
	//always @(posedge clk) 
		//if(SSEL_startmessage) cnt <= cnt+8'h01;  // count the messages

	//reg [2:0] byte_cnt_answer			/* synthesis syn_keep = 1 */;
	//always @(posedge clk or posedge reset) begin
		//if (reset) byte_cnt_answer <= 8'd0;
		//else byte_cnt_answer <=  tx;
		//end
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			byte_data_sent <= 8'd0;
			end
		else begin	
			if (!SSEL_active) byte_data_sent <= 8'd0; 
			else begin
				if (SCK_risingedge && bitcnt==3'b000) byte_data_sent <= tx;
				else if (SCK_risingedge) byte_data_sent <= {byte_data_sent[6:0], 1'b0};
				end
			
			end
		end

	assign MISO = (SSEL_active) ? byte_data_sent[7] : 1'bz;   //send MSB first 
	
/*	always @(posedge clk)
		if(SSEL_active)
			begin
			  if(SSEL_startmessage)
				byte_data_sent <= cnt;  // first byte sent in a message is the message count
			  else
			  if(SCK_fallingedge)
			  begin
				if(bitcnt==3'b000)
				  byte_data_sent <= 8'h00;  // after that, we send 0s
				else
				  byte_data_sent <= {byte_data_sent[6:0], 1'b0};
			  end
			end

	assign MISO = byte_data_sent[7];  // send MSB first */
	

	// we assume that there is only one slave on the SPI bus
	// so we don't bother with a tri-state buffer for MISO
	// otherwise we would need to tri-state MISO when SSEL is inactive

endmodule