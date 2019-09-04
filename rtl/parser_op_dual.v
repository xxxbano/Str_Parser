//////////////////////////////////
// v0.1 string parser
// 2019-08-31 by Zhengfan Xia
// 
// Two layers of buffer
// 1st layer store raw data
// 2nd layer receive arranged data by parsing SMARK
// At last, be able to parse data in 64-bit length
// 2nd has 2 fifo for dual channel mode
//////////////////////////////////


module parser_op_dual #(
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
  output wire [ 31:0]  out2_tag,
  output wire [127:0]  out2_value

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
assign pos = sm_pos(cur_data);// check SMARK exist
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

// first layer buffer signal
	reg [63:0] buf_wdata;
	wire buf_wr;
// second layer buffer 1 signal
	wire buf1_wr;
	reg buf1_rd;
	wire buf1_full;
	wire buf1_empty;
	wire [63:0] buf1_rdata;
	wire [8:0] buf1_count;
// second layer buffer 2 signal
	wire buf2_wr;
	reg buf2_rd;
	wire buf2_full;
	wire buf2_empty;
	wire [63:0] buf2_rdata;
	wire [8:0] buf2_count;

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

// when find SMARK, next group of data go to second buffer
reg channel_sel;
always @(posedge clk) begin
	if(rst) channel_sel<=0;
	else if(sm_check(cur_data)) channel_sel <= ~channel_sel;
end

assign fifo_rd = ~empty && (~buf1_full || ~buf2_full || ~mem_zero);
assign buf_wr = ~empty && ~mem_zero;
// 1.when sel1, buf1 is not full, write buf1
// 2.when sel2, buf1 is not full, but buf2 full, write buf1
assign buf1_wr =  (channel_sel)?	buf_wr&&~buf1_full&& buf2_full : buf_wr&&~buf1_full;
assign buf2_wr = (~channel_sel)?	buf_wr&& buf1_full&&~buf2_full : buf_wr&&~buf2_full;



/////////////////////////////////////////////////
// channel 1
/////////////////////////////////////////////////
// second layer buffer
fifo #(.DSIZE(64), .MSIZE(4)) i_buf1(
	.rst(rst),
	.clk(clk),
	.wr(buf1_wr),
	.rd(buf1_rd),
	.wdata(buf_wdata),
	.rdata(buf1_rdata),
	.count(buf1_count),
	.full(buf1_full),
	.empty(buf1_empty),
	.overflow(),
	.underflow()
);


reg [5:0] op1_cnt;
reg [63:0] tag1_data;
reg [191:0] tmp1_data;
reg [3:0] state1;
localparam S11= 4'b0001;
localparam S12= 4'b0010;
localparam S13= 4'b0100;
localparam S14= 4'b1000;

always @(posedge clk) begin
	if(rst) begin
		state1<=S11;
		op1_cnt<=0;
		buf1_rd<=0;
		tag1_data<=0;
		tmp1_data<=0;
	end else begin
		out1_valid <= 0; // output valid 
		buf1_rd<=0;
		op1_cnt <= op1_cnt + 1; 
		
		case(state1)
		S11: begin  // idle
			if(buf1_count) begin
				state1<=S12;
				buf1_rd <= 1;
				tmp1_data <= 0;
				end
			end
		S12: begin  // readout flag
			buf1_rd <= 1;
			op1_cnt <= 0; 
			tag1_data <= buf1_rdata; // store 1st 64-bit for tag parser 
			tmp1_data[63:0] <= buf1_rdata; // store 1st 64-bit for value parser 

			if(eq_pos(buf1_rdata)>5) begin // invalid tag length
				if(sm_check(buf1_rdata)) begin // if has SMARK, go to idle
					state1<=S11;
					buf1_rd <= 0;
				end else begin
					state1 <= S14; // no SMARK, go to S14 clean up
				end
			end else begin  // valid tag length
				state1 <= S13;
				if(sm_check(buf1_rdata)) begin // if has SMARK, go to idle
					state1<=S11;
					out1_valid <= 1;
					buf1_rd <= 0;
				end
			end
			end
		S13: begin
			buf1_rd <= 1;
			if(op1_cnt==0)
				tmp1_data[127:64] <= buf1_rdata; // store 2nd 64-bit for value parser
			if(op1_cnt==1) begin
				tmp1_data[191:128] <= buf1_rdata; // store 3rd 64-bit for value parser
				out1_valid <= 1;
				state1<=S14;                       // go to S14 clean up
			end
			if(sm_check(buf1_rdata)) begin // find SMARK, go to idle 
				state1<=S11;
				out1_valid <= 1;
				buf1_rd <= 0;
			end
		end
		S14: begin
			buf1_rd <= 1;
			if(sm_check(buf1_rdata)) begin // find SMARK, go to idle 
				state1<=S11;
				buf1_rd <= 0;
			end
		end
		default: state1<=S11;
		endcase
	end
end

assign out1_tag = tag_parser(tag1_data);
assign out1_value = value_parser(tmp1_data);

/////////////////////////////////////////////////
// channel 2
/////////////////////////////////////////////////
// second layer buffer
fifo #(.DSIZE(64), .MSIZE(4)) i_buf2(
	.rst(rst),
	.clk(clk),
	.wr(buf2_wr),
	.rd(buf2_rd),
	.wdata(buf_wdata),
	.rdata(buf2_rdata),
	.count(buf2_count),
	.full(buf2_full),
	.empty(buf2_empty),
	.overflow(),
	.underflow()
);


reg [5:0] op2_cnt;
reg [63:0] tag2_data;
reg [191:0] tmp2_data;
reg [3:0] state2;
localparam S21= 4'b0001;
localparam S22= 4'b0010;
localparam S23= 4'b0100;
localparam S24= 4'b1000;

always @(posedge clk) begin
	if(rst) begin
		state2<=S21;
		op2_cnt<=0;
		buf2_rd<=0;
		tag2_data<=0;
		tmp2_data<=0;
	end else begin
		out2_valid <= 0; // output valid 
		buf2_rd<=0;
		op2_cnt <= op2_cnt + 1; 
		
		case(state2)
		S21: begin  // idle
			if(buf2_count) begin
				state2<=S22;
				buf2_rd <= 1;
				tmp2_data <= 0;
				end
			end
		S22: begin  // readout flag
			buf2_rd <= 1;
			op2_cnt <= 0; 
			tag2_data <= buf2_rdata; // store 1st 64-bit for tag parser 
			tmp2_data[63:0] <= buf2_rdata; // store 1st 64-bit for value parser 

			if(eq_pos(buf2_rdata)>5) begin // invalid tag length
				if(sm_check(buf2_rdata)) begin // if has SMARK, go to idle
					state2<=S21;
					buf2_rd <= 0;
				end else begin
					state2 <= S24; // no SMARK, go to S24 clean up
				end
			end else begin  // valid tag length
				state2 <= S23;
				if(sm_check(buf2_rdata)) begin // if has SMARK, go to idle
					state2<=S21;
					out2_valid <= 1;
					buf2_rd <= 0;
				end
			end
			end
		S23: begin
			buf2_rd <= 1;
			if(op2_cnt==0)
				tmp2_data[127:64] <= buf2_rdata; // store 2nd 64-bit for value parser
			if(op2_cnt==1) begin
				tmp2_data[191:128] <= buf2_rdata; // store 3rd 64-bit for value parser
				out2_valid <= 1;
				state2<=S24;                       // go to S24 clean up
			end
			if(sm_check(buf2_rdata)) begin // find SMARK, go to idle 
				state2<=S21;
				out2_valid <= 1;
				buf2_rd <= 0;
			end
		end
		S24: begin
			buf2_rd <= 1;
			if(sm_check(buf2_rdata)) begin // find SMARK, go to idle 
				state2<=S21;
				buf2_rd <= 0;
			end
		end
		default: state2<=S21;
		endcase
	end
end

assign out2_tag = tag_parser(tag2_data);
assign out2_value = value_parser(tmp2_data);
	
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
