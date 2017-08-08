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
		output wire risingedge,
		output wire fallingedge,
		input wire reset
		);
		
	//����������� ���������� ��������� ������ ������� (����� ��� ����)
	reg [2:0] cnt_sync = 3'd0;  
	always @(posedge clk_12mhz) cnt_sync <= {cnt_sync[1:0], cnt};
	wire cnt_risingedge = (cnt_sync[2:1]==2'b01);  // ������ �� ����� ������������� ������
	wire cnt_fallingedge = (cnt_sync[2:1]==2'b10);  // � �����
	
	assign risingedge = cnt_risingedge;
	assign fallingedge = cnt_fallingedge;
	
	//�������� ��������
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
					
				//������� �������� ��������� ���������, ��� ���������� ���������� 
				//����������� ��������
				if (cnt_sync == 3'b111) m <= 24'b0 ;
				if (cnt_sync == 3'b000) p <= 24'b0 ;
				end
			end
		end

	//���������� �������� �������� ������� ������ �������� �������
	always @(posedge clk_12mhz or posedge reset) begin
		if (reset) cnt_m <= 24'b0;
		else begin 
			if (cnt_risingedge) cnt_m <= m;
			end
		end
		
	//���������� �������� �������� �������� ������ �������� �������
	always @(posedge clk_12mhz or posedge reset) begin
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