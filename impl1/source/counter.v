/**
 * � ������ ����� ��������� ������ 
 * -ADC_trigger(..)
 * -counter(..)
 * -count_choise(..)
 * 
 */
`timescale 1 ns / 1 ps


/**
 * @brief ������� ���		 
 * @details ������ ������������ ����� ������� �������, �������
 *          �������������� ������� ������ ����� ����������� ��� � ��������
 *          �������� � �� ������ ������ ������ ���������� ������, � ����� 
 * 	        ������ ��� ����� ���������
 * 
 * @param clk 	�������� ������� (4���)
 * @param d 	���� ��������, ������������ � ������ ����������� ���
 * @param q 	����� ��������, ������� ��������� �� ���� 
 *              �������� counter(..)
 * @param n_q 	��������������� ����� ��������, �������� �������� 
 *              ��� ������������ ����������� �������� ���� �� ��������
 * @param reset	���� ������������ ������
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
 * @brief ������� ���������		 
 * @details ������� ������� ������������ �������� � ������� ������ ������� cnt
 *          ��� ����������� ������� en. �������� �������, � ������� ��������� ������������ -
 *          4���, ������� ������� ������ - 12���. ��������� �������� ����������� � ���
 *          24-� ��������� �������� count_p � count_m.
 * 
 * @param  clk_12mhz 		������� �������� ������� 12 ��� ��� ������ ������
 * @param  clk_4mhz  		������� �������� ������� 12 ��� ��� ����� ���������
 * @param  cnt       		������, ������������ �������� ���������� �������
 * @param  en        		���� ���������� �����
 * @param  [23:0]count_p 	����+
 * @param  [23:0]count_m	����-
 * @param  reset     		����������� �����
 */
module counter(
		input wire clk_12mhz,
		input wire clk_4mhz,
		input wire cnt,
		input wire en,
		output wire [23:0] count_p,
		output wire [23:0] count_m,
		input wire reset
		);
		
	//����������� ���������� ��������� ������ ������� (����� ��� ����)
	reg [2:0] cnt_sync = 3'd0;  
	always @(posedge clk_12mhz) cnt_sync <= {cnt_sync[1:0], cnt};
	wire cnt_risingedge = (cnt_sync[2:1]==2'b01);  // ������ �� ����� ������������� ������
	wire cnt_fallingedge = (cnt_sync[2:1]==2'b10);  // � �����
	
	//�������� ��������
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
					
				//������� �������� ��������� ���������, ��� ���������� ���������� 
				//����������� ��������
				if (cnt_sync == 3'b111) m <=0 ;
				if (cnt_sync == 3'b000) p <=0 ;
				end
			end
		end

	//���������� �������� �������� ������� ������ �������� �������
	always @(posedge reset or posedge cnt_risingedge) begin
		if (reset) cnt_m <= 24'b0;
		else begin 
			if (cnt_risingedge) cnt_m <= m;
			end
		end
		
	//���������� �������� �������� �������� ������ �������� �������
	always @(posedge reset or posedge cnt_fallingedge) begin
		if (reset) cnt_p <= 24'b0;
		else begin
			if (cnt_fallingedge) cnt_p <= p;
			end
		end
	
endmodule


/**
 * @brief ������ ������ ������� �� ���� ��������	 
 * @details ������������� ��� ����� �������� counter. � ������� ������� 
 *          cnt_choise ���������� ����� 1 ��� 2 � ������������ � ������.
 *
 * @param  cnt_choise    ������ ������ �����
 * @param  count1        ������ ��� ��������� ����� 1
 * @param  enable1       ������ ���������� ��������� ����� 1
 * @param  count2        ������ ��� ��������� ����� 2
 * @param  enable2       ������ ���������� ��������� ����� 1
 * @param  count         ������ ��� ��������� �����
 * @param  enable        ������ ���������� ��������� �����
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
		
	reg cnt_in = 1'b0;
	reg cnt_en = 1'b0;
	assign count = cnt_in;
	assign enable = cnt_en;
	
	initial begin
		cnt_in = 1'b0;
		cnt_en = 1'b0;
		end
		
	always @(*) begin
		if (count_mode) begin
			cnt_in = count2;
			cnt_en = enable2;
			end
		else begin
			cnt_in = count1;
			cnt_en = enable1;
			end
		end	

endmodule


module count_prebufer(
		input wire clk_12mhz,
		input wire mode,
		input wire [23:0] count_m,
		input wire [23:0] count_p,
		output reg [23:0] count,
		output reg wr_en,
		input wire [3:0] spi_cmd,
		input wire [3:0] fifo_level,
		input wire reset
		);
	
	initial begin
		wr_en <= 1'b0;
		count <= 24'b0;
		end
		
	always @(posedge clk_12mhz or posedge reset) begin
		if (reset) begin
			wr_en <= 1'b0;
			count <= 24'b0;
			end
		else begin
			if (spi_cmd == 4'd0 && fifo_level < 4'd7) begin
				count = count + 1'b1;
				wr_en = 1'b1;
				end
			else begin
				wr_en <= 1'b0;
				end
			end
		end
		

endmodule