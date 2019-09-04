//////////////////////////////////
// v0.2 string parser
// 2019-08-31 by Zhengfan Xia
// 
// Two layers of buffer
// 1st layer store raw data
// 2st layer receive arranged data by parsing SMARK
// At last, be able to parse data in 64-bit length
// 
// Require input string terminated by SMARK
// Or add protection in the last write in
// e.g. after eog, write an extra SMARK
//////////////////////////////////


module parser_op #(
	parameter MSIZE = 8,
	parameter SMARK = 8'h01
)(
  input wire clk,
  input wire rst,

  input wire avl_st_rx_valid,
  input wire [63:0] avl_st_rx_data,
  input wire avl_st_rx_sop,
  input wire avl_st_rx_eop,
  input wire [2:0] avl_st_rx_empty,
  
  output reg   out1_valid,
  output wire [ 31:0]  out1_tag,
  output wire [127:0]  out1_value,

  output reg   out2_valid,
  output reg [ 31:0]  out2_tag,
  output reg [127:0]  out2_value

);


// fifo signal 
wire [MSIZE:0] fifo_cnt;
reg [7:0] m[0:(1<<MSIZE)-1];
reg [MSIZE:0] wr_cnt;
reg [MSIZE:0] rd_cnt;
wire [63:0] fifo_wdata;
reg [63:0] eog_wdata;
wire fifo_wr;
wire fifo_rd;
wire equal;  
wire full;  
wire empty;  

assign equal= wr_cnt[MSIZE-1:0] == rd_cnt[MSIZE-1:0]; 
assign fifo_cnt= wr_cnt - rd_cnt;
assign full = (wr_cnt[MSIZE]^rd_cnt[MSIZE]) & equal;
assign empty =~(wr_cnt[MSIZE]^rd_cnt[MSIZE]) & equal;
assign fifo_wr =avl_st_rx_valid &(~full);

//masked data for eop
always @(*) begin
  case(avl_st_rx_empty)
  3'b000: eog_wdata = avl_st_rx_data & 64'hffffffffffffffff;
  3'b001: eog_wdata = avl_st_rx_data & 64'h00ffffffffffffff;
  3'b010: eog_wdata = avl_st_rx_data & 64'h0000ffffffffffff;
  3'b011: eog_wdata = avl_st_rx_data & 64'h000000ffffffffff;
  3'b100: eog_wdata = avl_st_rx_data & 64'h00000000ffffffff;
  3'b101: eog_wdata = avl_st_rx_data & 64'h0000000000ffffff;
  3'b110: eog_wdata = avl_st_rx_data & 64'h000000000000ffff;
  3'b111: eog_wdata = avl_st_rx_data & 64'h00000000000000ff;
  endcase
end

always @(*) begin
  case(avl_st_rx_empty)
  3'b000: eog_wdata = avl_st_rx_data & 64'hffffffffffffffff;
  3'b001: eog_wdata = avl_st_rx_data & 64'h00ffffffffffffff;
  3'b010: eog_wdata = avl_st_rx_data & 64'h0000ffffffffffff;
  3'b011: eog_wdata = avl_st_rx_data & 64'h000000ffffffffff;
  3'b100: eog_wdata = avl_st_rx_data & 64'h00000000ffffffff;
  3'b101: eog_wdata = avl_st_rx_data & 64'h0000000000ffffff;
  3'b110: eog_wdata = avl_st_rx_data & 64'h000000000000ffff;
  3'b111: eog_wdata = avl_st_rx_data & 64'h00000000000000ff;
  endcase
end

assign fifo_wdata = (avl_st_rx_eop)? eog_wdata:avl_st_rx_data;


wire [63:0] cur_data;
wire [3:0] pos;
wire mem_zero;
assign cur_data[ 7:0 ]=m[rd_cnt[MSIZE-1:0]+0];
assign cur_data[15:8 ]=m[rd_cnt[MSIZE-1:0]+1];
assign cur_data[23:16]=m[rd_cnt[MSIZE-1:0]+2];
assign cur_data[31:24]=m[rd_cnt[MSIZE-1:0]+3];
assign cur_data[39:32]=m[rd_cnt[MSIZE-1:0]+4];
assign cur_data[47:40]=m[rd_cnt[MSIZE-1:0]+5];
assign cur_data[55:48]=m[rd_cnt[MSIZE-1:0]+6];
assign cur_data[63:56]=m[rd_cnt[MSIZE-1:0]+7];
assign pos = sm_pos(cur_data);// check SMARK position 
assign mem_zero = m[rd_cnt[MSIZE-1:0]]===0;// check mem data is zero

// fifo write control
always @(posedge clk) begin
	if(rst) begin
		wr_cnt<=0;
		rd_cnt<=0;
	end else begin
		if(fifo_wr) wr_cnt <= wr_cnt + 8;
		if(mem_zero) begin
			if(fifo_rd) rd_cnt <= rd_cnt + 1;
		end else begin
			if(fifo_rd) rd_cnt <= rd_cnt + pos;
		end
	end
end

// first layer buf to store input data 
always @(posedge clk) begin
	if(fifo_wr) begin
		m[wr_cnt[MSIZE-1:0]+0] <= fifo_wdata[ 7:0 ];
		m[wr_cnt[MSIZE-1:0]+1] <= fifo_wdata[15:8 ];
		m[wr_cnt[MSIZE-1:0]+2] <= fifo_wdata[23:16];
		m[wr_cnt[MSIZE-1:0]+3] <= fifo_wdata[31:24];
		m[wr_cnt[MSIZE-1:0]+4] <= fifo_wdata[39:32];
		m[wr_cnt[MSIZE-1:0]+5] <= fifo_wdata[47:40];
		m[wr_cnt[MSIZE-1:0]+6] <= fifo_wdata[55:48];
		m[wr_cnt[MSIZE-1:0]+7] <= fifo_wdata[63:56];
	end
end

	reg [63:0] buf_wdata;
	wire [63:0] buf_rdata;
	wire [8:0] buf_count;
	wire buf_wr;
	reg buf_rd;
	wire buf_full;
	wire buf_empty;

// generate data for sencond layer buf
	always @(*) begin
		case(pos)
			4'b0001: begin
				buf_wdata[ 7:0 ] = m[rd_cnt[MSIZE-1:0]+0];
				buf_wdata[63:8 ] = 0;
			end
			4'b0010: begin
				buf_wdata[ 7:0 ] = m[rd_cnt[MSIZE-1:0]+0];
				buf_wdata[15:8 ] = m[rd_cnt[MSIZE-1:0]+1];
				buf_wdata[63:16] = 0;
			end
			4'b0011: begin
				buf_wdata[ 7:0 ] = m[rd_cnt[MSIZE-1:0]+0];
				buf_wdata[15:8 ] = m[rd_cnt[MSIZE-1:0]+1];
				buf_wdata[23:16] = m[rd_cnt[MSIZE-1:0]+2];
				buf_wdata[63:24] = 0;
			end
			4'b0100: begin
				buf_wdata[ 7:0 ] = m[rd_cnt[MSIZE-1:0]+0];
				buf_wdata[15:8 ] = m[rd_cnt[MSIZE-1:0]+1];
				buf_wdata[23:16] = m[rd_cnt[MSIZE-1:0]+2];
				buf_wdata[31:24] = m[rd_cnt[MSIZE-1:0]+3];
				buf_wdata[63:32] = 0;
			end
			4'b0101: begin
				buf_wdata[ 7:0 ] = m[rd_cnt[MSIZE-1:0]+0];
				buf_wdata[15:8 ] = m[rd_cnt[MSIZE-1:0]+1];
				buf_wdata[23:16] = m[rd_cnt[MSIZE-1:0]+2];
				buf_wdata[31:24] = m[rd_cnt[MSIZE-1:0]+3];
				buf_wdata[39:32] = m[rd_cnt[MSIZE-1:0]+4];
				buf_wdata[63:40] = 0;
			end
			4'b0110: begin
				buf_wdata[ 7:0 ] = m[rd_cnt[MSIZE-1:0]+0];
				buf_wdata[15:8 ] = m[rd_cnt[MSIZE-1:0]+1];
				buf_wdata[23:16] = m[rd_cnt[MSIZE-1:0]+2];
				buf_wdata[31:24] = m[rd_cnt[MSIZE-1:0]+3];
				buf_wdata[39:32] = m[rd_cnt[MSIZE-1:0]+4];
				buf_wdata[47:40] = m[rd_cnt[MSIZE-1:0]+5];
				buf_wdata[63:48] = 0;
			end
			4'b0111: begin
				buf_wdata[ 7:0 ] = m[rd_cnt[MSIZE-1:0]+0];
				buf_wdata[15:8 ] = m[rd_cnt[MSIZE-1:0]+1];
				buf_wdata[23:16] = m[rd_cnt[MSIZE-1:0]+2];
				buf_wdata[31:24] = m[rd_cnt[MSIZE-1:0]+3];
				buf_wdata[39:32] = m[rd_cnt[MSIZE-1:0]+4];
				buf_wdata[47:40] = m[rd_cnt[MSIZE-1:0]+5];
				buf_wdata[55:48] = m[rd_cnt[MSIZE-1:0]+6];
				buf_wdata[63:56] = 0;
			end
			4'b1000: begin
				buf_wdata[ 7:0 ] = m[rd_cnt[MSIZE-1:0]+0];
				buf_wdata[15:8 ] = m[rd_cnt[MSIZE-1:0]+1];
				buf_wdata[23:16] = m[rd_cnt[MSIZE-1:0]+2];
				buf_wdata[31:24] = m[rd_cnt[MSIZE-1:0]+3];
				buf_wdata[39:32] = m[rd_cnt[MSIZE-1:0]+4];
				buf_wdata[47:40] = m[rd_cnt[MSIZE-1:0]+5];
				buf_wdata[55:48] = m[rd_cnt[MSIZE-1:0]+6];
				buf_wdata[63:56] = m[rd_cnt[MSIZE-1:0]+7];
			end
			default: buf_wdata[63:0] = 0;
		endcase
	end

	assign fifo_rd = ~empty && (~buf_full || ~mem_zero);
	assign buf_wr = ~empty && ~buf_full && ~mem_zero;

// second layer buffer
fifo #(.DSIZE(64), .MSIZE(3)) i_buf(
	.rst(rst),
	.clk(clk),
	.wr(buf_wr),
	.rd(buf_rd),
	.wdata(buf_wdata),
	.rdata(buf_rdata),
	.count(buf_count),
	.full(buf_full),
	.empty(buf_empty),
	.overflow(),
	.underflow()
);


reg [5:0] op_cnt;
reg [63:0] tag_data;
reg [191:0] tmp_data;
reg [3:0] state;
localparam S1= 4'b0001;
localparam S2= 4'b0010;
localparam S3= 4'b0100;
localparam S4= 4'b1000;

always @(posedge clk) begin
	if(rst) begin
		state<=S1;
		op_cnt<=0;
		buf_rd<=0;
		tag_data<=0;
		tmp_data<=0;
	end else begin
		out1_valid <= 0; // output valid 
		buf_rd<=0;
		op_cnt <= op_cnt + 1; 
		
		case(state)
		S1: begin  // idle
			if(buf_count) begin
				state<=S2;
				buf_rd <= 1;
				tmp_data <= 0;
				end
			end
		S2: begin  // readout flag
			buf_rd <= 1;
			op_cnt <= 0; 
			tag_data <= buf_rdata; // store 1st 64-bit for tag parser 
			tmp_data[63:0] <= buf_rdata; // store 1st 64-bit for value parser 

			if(eq_pos(buf_rdata)>5) begin // invalid tag length
				if(sm_check(buf_rdata)) begin // if has SMARK, go to idle
					state<=S1;
					buf_rd <= 0;
				end else begin
					state <= S4; // no SMARK, go to S4 clean up
				end
			end else begin  // valid tag length
				state <= S3;
				if(sm_check(buf_rdata)) begin // if has SMARK, go to idle
					state<=S1;
					out1_valid <= 1;
					buf_rd <= 0;
				end
			end
			end
		S3: begin
			buf_rd <= 1;
			if(op_cnt==0)
				tmp_data[127:64] <= buf_rdata; // store 2nd 64-bit for value parser
			if(op_cnt==1) begin
				tmp_data[191:128] <= buf_rdata; // store 3rd 64-bit for value parser
				out1_valid <= 1;
				state<=S4;                       // go to S4 clean up
			end
			if(sm_check(buf_rdata)) begin // find SMARK, go to idle 
				state<=S1;
				out1_valid <= 1;
				buf_rd <= 0;
			end
		end
		S4: begin
			buf_rd <= 1;
			if(sm_check(buf_rdata)) begin // find SMARK, go to idle 
				state<=S1;
				buf_rd <= 0;
			end
		end
		default: state<=S1;
		endcase
	end
end

assign out1_tag = tag_parser(tag_data);
assign out1_value = value_parser(tmp_data);
	
// return position of SMARK
function [3:0] sm_pos;
	input [63:0] wdata;
	begin
		case(SMARK)
			wdata[ 7:0 ]: sm_pos = 1; 
			wdata[15:8 ]: sm_pos = 2; 
			wdata[23:16]: sm_pos = 3;
			wdata[31:24]: sm_pos = 4;
			wdata[39:32]: sm_pos = 5;
			wdata[47:40]: sm_pos = 6;
			wdata[55:48]: sm_pos = 7;
			wdata[63:56]: sm_pos = 8;
					 default: sm_pos = 8;
		endcase
	end
endfunction

// return position of = 
function [3:0] eq_pos;
	input [63:0] wdata;
	begin
		case(8'h3d)
			wdata[ 7:0 ]: eq_pos = 9; 
			wdata[15:8 ]: eq_pos = 2; // valid pos
			wdata[23:16]: eq_pos = 3; // valid pos
			wdata[31:24]: eq_pos = 4; // valid pos
			wdata[39:32]: eq_pos = 5; // valid pos
			wdata[47:40]: eq_pos = 6;
			wdata[55:48]: eq_pos = 7;
			wdata[63:56]: eq_pos = 8;
					 default: eq_pos = 9;
		endcase
	end
endfunction

// return 32-bit tag_value from 64-bit data
function [31:0] tag_parser;
	input [63:0] wdata;
	begin
		case(8'h3d)
			wdata[15:8 ]: tag_parser = wdata & 32'h000000ff; 
			wdata[23:16]: tag_parser = wdata & 32'h0000ffff;
			wdata[31:24]: tag_parser = wdata & 32'h00ffffff;
			wdata[39:32]: tag_parser = wdata & 32'hffffffff;
			default: tag_parser = 0;
		endcase
	end
endfunction

// return 127-bit out_value  from 192-bit data
function [127:0] value_parser;
	input [191:0] wdata;
	begin
		case(8'h3d)
			wdata[15:8 ]: value_parser = wdata>>16; 
			wdata[23:16]: value_parser = wdata>>24;
			wdata[31:24]: value_parser = wdata>>32;
			wdata[39:32]: value_parser = wdata>>40;
			default: value_parser = 0;
		endcase
	end
endfunction

// check SMARK symbol
function sm_check;
	input [64:0] wdata;
	begin
		casez(SMARK)
			wdata[ 7:0 ]: sm_check = 1; 
			wdata[15:8 ]: sm_check = 1; 
			wdata[23:16]: sm_check = 1;
			wdata[31:24]: sm_check = 1;
			wdata[39:32]: sm_check = 1;
			wdata[47:40]: sm_check = 1;
			wdata[55:48]: sm_check = 1;
			wdata[63:56]: sm_check = 1;
					 default: sm_check = 0;
		endcase
	end
endfunction

endmodule
