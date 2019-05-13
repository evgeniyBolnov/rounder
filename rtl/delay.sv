module delay #(
	parameter DATA_WIDTH = 16,
	parameter LENGTH     = 3
) (
	input                   clk   ,
	input                   rst   ,
	input  [DATA_WIDTH-1:0] data_i,
	output [DATA_WIDTH-1:0] data_o
);

	reg [LENGTH-1:0][DATA_WIDTH-1:0] delay_rg ;

	assign data_o = delay_rg[LENGTH-1];

	always @(posedge clk or posedge rst) begin
		if (rst)
			delay_rg <= '0;
		else
			delay_rg <= (LENGTH == 1) ? data_i : {delay_rg[LENGTH-2:0], data_i	};
	end

endmodule 