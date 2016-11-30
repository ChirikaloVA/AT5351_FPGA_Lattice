`timescale 1 ns / 1 ps


module ADC_trigger(
	input wire clk,
	input wire d,
	output wire q,
	output wire n_q,
	input wire reset
	);
	
	//reg buffer;
	
	//wire q_1;
	//assign q_1 = buffer;
	
	//reg buffer_out;
	//assign n_q = ~q;
	//assign q = buffer_out;
	
	//reg reset_sync;
	
	//always @(posedge clk_12MHz) begin
		//reset_sync <= reset;
		//end
		
	//always @(posedge clk) begin
		//if (reset_sync) begin 
			//buffer <= 1'b0;
			//end
		//else begin
			///*if (d) buffer <= 1'b1;
			//else buffer <= 1'b0; */
			//buffer <= d;
			//end	
		//end
		
	//always @(posedge clk_12MHz) begin
		//if (q_1) buffer_out <= 1'b1;
		//else buffer_out <= 1'b0;
		//end

	reg buffer = 1'b0;

	assign n_q = ~q;
	assign q = buffer;
	

		
	//always @(clk) begin
		//if (reset_sync) clock <= clk_12MHz;
		//else clock <= clk;	
	//end
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			buffer <= 1'b0;
			
		end
		else begin

			buffer <= d;
		end	
	end


endmodule


module Pulse_Counter(
		input wire clk, 
		input wire clk_div_6, 
		input wire trigger,
		input wire reset,
		output reg [23:0] count_p, 
		output reg [23:0] count_m
		);

	reg [23:0] p = 24'd0;
	reg [23:0] m = 24'd0;
	
	//initial begin
		//count_p = 24'b0;
		//count_m = 24'b0;
		//end
		
		
	//reg reset_local = 1'b0;  
	//always @(posedge clk) 
		//if (reset) reset_local<= 1'b1;
		//else reset_local <= 1'b0;
	
	reg [2:0] trigger_sync = 3'd0;  
	always @(posedge clk) trigger_sync <= {trigger_sync[1:0], trigger};
	wire trigger_risingedge = (trigger_sync[2:1]==2'b01);  // now we can detect trigger rising edges
	wire trigger_fallingedge = (trigger_sync[2:1]==2'b10);  // and falling edges
	
	always @(posedge clk_div_6 or posedge reset) begin
		if (reset) begin
			p <= 24'd0;
			m <= 24'd0;
			end
		else begin
			if (trigger) begin
				m <=0 ;
				p <= p + 24'b1;
				end
			else begin
				p <=0 ;
				m <= m + 24'b1;
				end
			//if (clk_div_6)
				//if (trigger) p <= p + 24'b1;
				//else m <= m + 24'b1;
			//if (trigger_risingedge) begin
				//p <= 24'b0;
				//count_m <= m;
				//count_p <= p;
				//end
			//if (trigger_fallingedge) m <= 24'b0;
			end

			
		end
		
		
	always @(posedge clk or posedge reset) begin
		if (reset) count_m <= 24'b0;
		else begin 
			if (trigger_risingedge) count_m <= m;
			end
		end
		
		
	always @(posedge clk or posedge reset) begin
		if (reset) count_p <= 24'b0;
		else begin
			if (trigger_fallingedge) count_p <= p;
			end
		end
endmodule
	