`timescale 1 ns / 1 ps

/* Модуль деления частоты 12 МГц в частоту 2МГц*/
module clock_div_6(
						input wire clk_in,
						//input wire reset,
						output reg clk_div_6
						);
	
	reg [2:0] count;

	initial begin
		count = 3'b0;		
		clk_div_6 = 1'b0;
		end
	
		
		
	
	//always @(posedge clk_in or posedge reset) begin
	always @(posedge clk_in) begin
		//if (reset) begin
			//count <= 3'b0;
			//clk_div_6 <= 1'b0;
			//end
		//else 
			//begin
			if (count == 3'b010) begin
				clk_div_6 <= ~clk_div_6;
				count <=  3'b0;
				end
			 else count <= count + 3'b01;	
			//end
	end
	

endmodule

/* Модуль деления частоты 2 МГц в частоту 20Гц*/
module clock_5ms(clk_div_6, reset, clk_5ms, clk_not_5ms);
	input wire clk_div_6;
	input wire reset;
	output reg clk_5ms;
	output wire clk_not_5ms;
	
	reg [15:0] count_5ms;

	initial begin
		count_5ms = 16'b0;
		clk_5ms = 1'b0;
		end

	
		
	//always @(posedge clk_div_6 or posedge reset) begin
	always @(posedge clk_div_6) begin
		//if (reset) begin
			//count_5ms <= 16'b0;
			//clk_5ms <= 1'b0;
			//end
		//else begin
			if (count_5ms == 16'd9999) begin
				clk_5ms <= ~clk_5ms;
				count_5ms <= 16'b0;
				end 
			else count_5ms <= count_5ms + 16'd1;	
			//end

	end	

	assign clk_not_5ms = ~clk_5ms;
endmodule