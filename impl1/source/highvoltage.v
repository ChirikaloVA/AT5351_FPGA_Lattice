`timescale 1 ns / 1 ps

module highvoltage(
	input wire clk,
	
	input wire vn_l,
	input wire vn_h,
	output reg vn_pol,
	output reg vn_on,
	
	input wire reset
	
	);
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			vn_pol <= 1'b0;
			vn_on <= 1'b0;
		end
		else begin
			if (vn_l) begin
				vn_on <= 1'b0;
			end
			
			if (vn_h) begin
				vn_on <= 1'b0;
			end
			
		end
	end
		
endmodule