/**
 * В данном файле находятся модули 
 * -ADC_trigger(..)
 * -counter(..)
 * -count_choise(..)
 * 
 */
`timescale 1 ns / 1 ps


/**
 * @brief Триггер АЦП		 
 * @details Модуль представляет собой обычный триггер, который
 *          синхронизирует входной сигнал после компаратора АЦП с тактовой
 *          частотой и на выходе выдает сигнал управления опорой, а также 
 * 	        сигнал для счета импульсов
 * 
 * @param clk 	тактовая частота (4МГц)
 * @param d 	вход триггера, подключается к выходу компаратора АЦП
 * @param q 	выход триггера, который заводится на вход 
 *              счетчика counter(..)
 * @param n_q 	инвертированный выход триггера, является сигналом 
 *              для переключения направления опорного тока на обратный
 * @param reset	вход асинхронного сброса
 */
module ADC_trigger(
		input wire clk,
		input wire d,
		output wire q,
		output wire n_q,
		input wire reset
		);
	
	reg buffer = 1'b0;
	assign n_q = ~q;
	assign q = buffer;

	always @(posedge clk or posedge reset) begin
		if (reset) buffer <= 1'b0;
		else buffer <= d;
	end

endmodule


/**
 * @brief Счетчик импульсов		 
 * @details Счетчик считает длительность высокого и низкого уровня сигнала cnt
 *          при разрешающем сигнале en. Тактовая частота, с которой считается длительность -
 *          4МГц, рабочая частота логики - 12МГц. Результат подсчета сохнаняется в два
 *          24-х разрядных регистра count_p и count_m.
 * 
 * @param  clk_12mhz 		входная тактовая частота 12 МГц для работы логики
 * @param  clk_4mhz  		входная тактовая частота 12 МГц для счета импульсов
 * @param  cnt       		сигнал, длительность которого необходимо считать
 * @param  en        		вход разрешения счета
 * @param  [23:0]count_p 	счет+
 * @param  [23:0]count_m	счет-
 * @param  reset     		асинхронный сброс
 */
module counter(
		input wire clk_12mhz,
		input wire clk_4mhz,
		input wire cnt,
		input wire en,
		output wire [23:0] count_p,
		output wire [23:0] count_m,
		output wire risingedge,
		output wire fallingedge,
		input wire reset
		);
		
	//Определение напраление изменения уровня сигнала (фронт или спад)
	reg [2:0] cnt_sync = 3'd0;  
	always @(posedge clk_12mhz) cnt_sync <= {cnt_sync[1:0], cnt};
	wire cnt_risingedge = (cnt_sync[2:1]==2'b01);  // сейчас мы можем детектировать фронты
	wire cnt_fallingedge = (cnt_sync[2:1]==2'b10);  // и спады
	
	assign risingedge = cnt_risingedge;
	assign fallingedge = cnt_fallingedge;
	
	//Регистры счетчика
	reg [23:0] p /* synthesis syn_keep*/;
	reg [23:0] m /* synthesis syn_keep*/;	
	//output reg [22:0] count_p;
	//output reg [22:0] count_m;

	reg [23:0] cnt_p /* synthesis syn_keep*/;
	reg [23:0] cnt_m /* synthesis syn_keep*/;
	assign count_p = cnt_p ;
	assign count_m = cnt_m ;
	
	//initial begin
		//cnt_p <= 24'b0;
		//cnt_m <= 24'b0;
		//end
	

	always @(posedge clk_4mhz or posedge reset) begin
		if (reset) begin
			p <= 24'd0;
			m <= 24'd0;
			end
		else begin
			if (en) begin
				if (cnt) p <= p + 24'b1;
				else if (!cnt) m <= m + 24'b1;
					
				//Введена задержка обнуления счетчиков, для уверенного сохранения 
				//содержимого счетчика
				if (cnt_sync == 3'b111) m <= 24'b0 ;
				if (cnt_sync == 3'b000) p <= 24'b0 ;
				end
			end
		end

	//Сохранение значение счетчика низкого уровня входного сигнала
	always @(posedge clk_12mhz or posedge reset) begin
		if (reset) cnt_m <= 24'b0;
		else begin 
			if (cnt_risingedge) cnt_m <= m;
			end
		end
		
	//Сохранение значение счетчика высокого уровня входного сигнала
	always @(posedge clk_12mhz or posedge reset) begin
		if (reset) cnt_p <= 24'b0;
		else begin
			if (cnt_fallingedge) cnt_p <= p;
			end
		end
	
endmodule


/**
 * @brief Модуль выбора сигнала на вход счетчика	 
 * @details Мультиплексор для входа счетчика counter. С помощью сигнала 
 *          cnt_choise выбирается канал 1 или 2 и подключаются к выходу.
 *
 * @param  cnt_choise    Сигнал выбора входа
 * @param  count1        Сигнал для измерения канал 1
 * @param  enable1       Сигнал разрешения измерения канал 1
 * @param  count2        Сигнал для измерения канал 2
 * @param  enable2       Сигнал разрешения измерения канал 1
 * @param  count         Сигнал для измерения выход
 * @param  enable        Сигнал разрешения измерения выход
 */
module count_choise(
		input wire count_mode,
		input wire count1,
		input wire enable1,
		input wire count2,
		input wire enable2,
		output wire count,
		output wire enable
		);
		
		
	assign count = count_mode ? count2 : count1;
	assign enable = count_mode ? enable2 : enable1;
	
	
	//always @(*) begin
		//if (count_mode) begin
			//cnt_in = count2;
			//cnt_en = enable2;
			//end
		//else begin
			//cnt_in = count1;
			//cnt_en = enable1;
			//end
		//end	

endmodule


module count_prebufer(
		input wire clk_12mhz,
		input wire mode,
		input wire [23:0] count_m,
		input wire [23:0] count_p,
		output reg [23:0] count,
		input wire falling_edge,
		input wire rising_edge,
		//output reg wr_en,
		//output reg rd_en,
		//input wire [3:0] spi_cmd,
		//input wire fifo_full,
		//input wire [3:0] fifo_level,
		output reg fifo_wr_en,
		input wire reset
		);
	
	initial begin
		count <= 24'b0;
		fifo_wr_en <= 1'b0;
		end
		
		
		
	always @(posedge clk_12mhz or posedge reset) begin
		if (reset) begin
			count <= 24'b0;
			fifo_wr_en <= 1'b0;
			end
		else begin
			if (!mode) begin 
				count <= count_p[22:0] - count_m[22:0];
				fifo_wr_en <= rising_edge;
				end
			else begin 
				if (falling_edge) count <= count_p;
				else if (rising_edge) count <= count_m;
				
				fifo_wr_en <= rising_edge | falling_edge;
				end
			//if (!mode) count <= {1'b0, count_p};



			end
		end
		

endmodule