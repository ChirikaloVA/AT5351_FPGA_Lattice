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
	
	
	
	

//Модуль счета длительности импульсов
module counter(
		input clk_12mhz,
		input clk_4mhz,
		input cnt,
		input en,
		//input cnt_choise,
		output [23:0] count_p,
		output [23:0] count_m,
		
		input reset
		);
		
		
	
		
	//Определение напраление изменения уровня сигнала (фронт или спад)
	reg [2:0] cnt_sync = 3'd0;  
	always @(posedge clk_12mhz) cnt_sync <= {cnt_sync[1:0], cnt};
	wire cnt_risingedge = (cnt_sync[2:1]==2'b01);  // now we can detect count rising edges
	wire cnt_fallingedge = (cnt_sync[2:1]==2'b10);  // and falling edges
	
	//Регистры счетчика
	reg [23:0] p = 24'd0;
	reg [23:0] m = 24'd0;			
	reg [23:0] cnt_p = 24'b0;
	reg [23:0] cnt_m = 24'b0;
	assign count_p = cnt_p;
	assign count_m = cnt_m;
	
	initial begin
		cnt_p <= 24'b0;
		cnt_m <= 24'b0;
		end
	

	always @(posedge clk_4mhz or posedge reset) begin
		if (reset) begin
			p <= 24'd0;
			m <= 24'd0;
			end
		else begin
			if (en) begin
				if (cnt) p <= p + 24'b1;
				else m <= m + 24'b1;
					
				//Введена задержка обнуления счетчиков, для уверенного сохранения 
				//содержимого счетчика
				if (cnt_sync == 3'b111) m <=0 ;
				if (cnt_sync == 3'b000) p <=0 ;
					

				end

			end
			
		end

	//Сохранение значение счетчика низкого уровня входного сигнала
	always @(posedge reset or posedge cnt_risingedge) begin
		if (reset) cnt_m <= 24'b0;
		else begin 
			if (cnt_risingedge) cnt_m <= m;
			end
		end
		
	//Сохранение значение счетчика высокого уровня входного сигнала
	always @(posedge reset or posedge cnt_fallingedge) begin
		if (reset) cnt_p <= 24'b0;
		else begin
			if (cnt_fallingedge) cnt_p <= p;
			end
		end
	
endmodule


//Модуль выбора сигнала на вход счетчика
module count_choise(
		input cnt_choise,
		input count1,
		input enable1,
		input count2,
		input enable2,
		output count,
		output enable
		);
		
	reg cnt_in = 1'b0;
	reg cnt_en = 1'b0;
	//assign cnt_choise = cnt_choise_reg;
	assign count = cnt_in;
	assign enable = cnt_en;
	
	initial begin
		cnt_in = 1'b0;
		cnt_en = 1'b0;
		end
		
	
	always @(*) begin
		if (cnt_choise) begin
			cnt_in = count2;
			cnt_en = enable2;
			end
		else begin
			cnt_in = count1;
			cnt_en = enable1;
			end
		end	

endmodule