`timescale 1 ns / 1 ps

/**
 * @brief Модуль деления частоты 12 МГц в частоту 4МГц	 
 * @details 
 *
 * @param  clk_12mhz   	Вход 12МГц
 * @param  clk_4mhz 	Выход 4МГц
 * @param  reset    	Асинхронный сброс
 */
module clock_4mhz(
		input wire clk_12mhz,
		output wire clk_4mhz,
		input wire reset
		);
	
    reg [3:0] counter = 4'b0;
    reg a = 1'b0;
	reg b = 1'b0;
	
	initial begin
		counter = 4'b0;
		a = 1'b0;
		b = 1'b0;
		end
	
    
    always @(posedge clk_12mhz or posedge reset) begin
		if (reset) begin
			a <= 1'b0; 
			counter <= 4'd0;
			//b <= 1'b0;
			end
		else begin
			counter <= (counter == 4'd2) ? 4'd0 : (counter + 4'd1);
			if (counter == 4'd0) a <= ~b;
			end
				
    end

    always @(negedge clk_12mhz or posedge reset) begin
        if (reset) begin
			b <= 1'b0; 
			end
		else begin
			if (counter == 4'd2) b <= a;
			end
    end

    assign clk_4mhz = a^b;
		
	
endmodule

/* Модуль деления частоты 4 МГц в частоту 20Гц*/
/**
 * @brief Модуль деления частоты 4 МГц в частоту 20Гц (5мс)
 * @details Выходы этого модуля подключены к АЦП в схеме.
 *          Сигнал clk_5ms является форсирующим сигналом в АЦП
 *
 * @param  clk_4mhz    Вход 4МГц
 * @param  reset       Асинхронный сброс
 * @param  clk_5ms     Выход сигнала с длительностью импульса 5мс и
 *                     длительностью сигнала 10 мс 
 * @param  clk_not_5ms Сигнал инверсный clk_5ms
 */
module clock_5ms(
		input wire clk_4mhz,
		input wire reset,
		output reg clk_5ms,
		output wire clk_not_5ms
		);

	reg [15:0] count_5ms = 16'b0;

	initial begin
		count_5ms = 16'b0;
		clk_5ms = 1'b0;
		end

	always @(posedge clk_4mhz or posedge reset) begin
		if (reset) begin
			count_5ms <= 16'b0;
			clk_5ms <= 1'b0;
			end
		else begin
			if (count_5ms == 16'd19999) begin
				clk_5ms <= ~clk_5ms;
				count_5ms <= 16'b0;
				end 
			else count_5ms <= count_5ms + 16'd1;	
			end

	end	

	assign clk_not_5ms = ~clk_5ms;
endmodule