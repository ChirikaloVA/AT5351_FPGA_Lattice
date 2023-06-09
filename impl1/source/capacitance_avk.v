`timescale 1 us / 1 us

module avk_capacitance(
		input pos_comparator,
		input neg_comparator,
		output reference,
		output antibounce,
		input clock_4mhz, 	
		input clock_12mhz, 	
		input reset
		);

	wire pos;
	wire neg;
	
	
	comp_buffer COMP_BUFFER(
		.pos_comp_in(pos_comparator),
		.neg_comp_in(neg_comparator),
		.pos_comp_out(pos),
		.neg_comp_out(neg),
		.clock(clock_12mhz)
		);
	
	
	avk_antibounce AVK_ANTIBOUNCE(
		.pos_comparator(pos),
		.neg_comparator(neg),
		.reference(reference),
		.out(antibounce),
		.reset(reset)
		
		);
		
	switch_reference SWITCH_REF	(
		.antibounce(antibounce),
		.reference(reference),
		.clock(clock_4mhz), //4MHz	
		.reset(reset)
		);
	
	//wire [23:0] count;
	//counter COUNTER(
		//.antibounce(antibounce),
		//.reference(reference),
		//.count(count),
		//.clock_4mhz(clock_4mhz),
		//.reset(reset)
		//);
	
	
	
endmodule


//������ ������������ � "������������ ���" �������� ������������
module avk_antibounce(
		input pos_comparator,
		input neg_comparator,
		input reference,
		output out,
		input reset
		
		);
	
	reg pos_trigger = 1'b1;
	reg neg_trigger = 1'b0;
	
	wire npos_comparator;
	wire nneg_comparator;
	assign npos_comparator = ~pos_comparator;
	assign nneg_comparator = ~neg_comparator;
	
	initial begin
		pos_trigger = 1'b1;
		neg_trigger = 1'b0;
		end
	

	wire pos_reset;
	wire pos_set;
	assign pos_reset = nneg_comparator;
	assign pos_set = reset;
	always @(posedge npos_comparator or posedge pos_reset or posedge pos_set) begin
		if (pos_set) pos_trigger <= 1'b1;
		else if (pos_reset) pos_trigger <= 1'b0;
		else pos_trigger <= reference;
		end

	wire neg_reset;
	wire neg_set;
	assign neg_reset = reset;
	assign neg_set = pos_comparator;
	always @(posedge neg_comparator or posedge neg_set or posedge neg_reset) begin
		if (neg_reset) neg_trigger = 1'b0;
		else if (neg_set) neg_trigger = 1'b1;
		else neg_trigger = reference;
		end
		
	assign out = pos_trigger ^ neg_trigger;
	//assign out = neg_trigger;
endmodule



//������, ���������� �� ������������ �������� ���������� ��� ��� �������
module switch_reference #(
							parameter COUNTER = 16'd20000		//��� ������� 4MHz ��� �������� 5��
							)
	(
		input antibounce,
		output reference,
		input clock, //4MHz	
		input reset
		);
		
	reg [15:0] cnt = 16'b0;		//������� 
	reg start_cnt = 1'b0;		//���� ������ ������� ���������
	reg reference_reg = 1'b0;
	assign reference = reference_reg;
	
	initial begin
		cnt <= 16'b0;
		reference_reg <= 1'b0;
		start_cnt <= 1'b0;
		end
	
	always @(posedge reset, posedge clock) begin
		if (reset) begin
			cnt <= 16'b0;
			start_cnt <= 1'b0;
			end
		else if (!antibounce) begin
			if (cnt < COUNTER) begin
				cnt <= cnt + 1'b1;
				start_cnt <= 1'b1;
				end
			else begin
				start_cnt <= 1'b0;
				end			
			end
		else if (antibounce) cnt <= 16'b0;
			
		end
		
		
	always @(negedge start_cnt, posedge reset) begin
		if (reset) reference_reg <= 1'b0;
		else reference_reg <= ~reference_reg;
		end		
endmodule


//������ ������������� �������� ������������ � ������� �������� ����
module comp_buffer(
		input pos_comp_in,
		input neg_comp_in,
		output pos_comp_out,
		output neg_comp_out,
		input clock			//12MHz
		);
		
	reg pos_out, pos;
	reg neg_out, neg;
	
	assign 	pos_comp_out = pos_out;
	assign 	neg_comp_out = neg_out;
	
	//always @(posedge clock or posedge pos_comp_in) begin
	always @(posedge clock) begin
		if (pos_comp_in) {pos_out, pos} <= {pos, 1'b1};
		else {pos_out, pos} <= {pos, 1'b0} ;
		end

	//always @(posedge clock or posedge neg_comp_in) begin
	always @(posedge clock) begin
		if (neg_comp_in) {neg_out, neg} <= {neg, 1'b1};
		else {neg_out, neg} <= {neg, 1'b0} ;
		end

endmodule	
