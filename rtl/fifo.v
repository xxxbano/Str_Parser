////////////////////////
// v0.1 2019-08-24 by Zhengfan Xia
////////////////////////
module fifo #(
	parameter DSIZE = 8,
	parameter MSIZE = 3
) (
	input wire rst,
	input wire clk,
	input wire wr,
	input wire rd,
	input wire [DSIZE-1:0] wdata,
	//output reg [DSIZE-1:0] rdata,
	output wire [DSIZE-1:0] rdata,
	output reg [MSIZE:0] count,
	output wire full,
	output wire empty,
	output wire overflow,
	output wire underflow
);


	reg [DSIZE-1:0] m[0:(1<<MSIZE)-1];
	reg [MSIZE:0] wr_cnt;
	reg [MSIZE:0] rd_cnt;
	wire equal;

	assign equal = wr_cnt[MSIZE-1:0] == rd_cnt[MSIZE-1:0];
	assign empty = ~(wr_cnt[MSIZE]^rd_cnt[MSIZE]) & equal;
	assign full = (wr_cnt[MSIZE]^rd_cnt[MSIZE]) & equal;
	assign overflow = full & wr;
	assign underflow = empty & rd;
	assign count = wr_cnt - rd_cnt;

	always @(posedge clk) begin
		if(rst) begin
			wr_cnt <= 0;
			rd_cnt <= 0;
		end else begin
			if(wr&~overflow) wr_cnt <= wr_cnt + 1;
			if(rd&~underflow) rd_cnt <= rd_cnt + 1;
		end
	end

	// stand
	always @(posedge clk) begin
		if(wr) m[wr_cnt[MSIZE-1:0]] <= wdata; 
		//rdata <= m[rd_cnt[MSIZE-1:0]];
	end
	// first word fall through 
	//always @(posedge clk) begin
	//	if(wr) m[wr_cnt[MSIZE-1:0]] <= wdata; 
	//end
	assign rdata = m[rd_cnt[MSIZE-1:0]];


endmodule
