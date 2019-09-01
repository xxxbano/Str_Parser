//////////////////////////////////
// v0.1 string parser
// 2019-08-31 by Zhengfan Xia
// 
// The idea is to focuse on saving input
// according to SMARK
// 1.always save new group of data from new 8-byte memory address
// 2.so as be able to parse data by reading out 8-byte data
//
// The benefit is low latency,
// But be careful of the complex combination logic at inputs,
// which would affect clock freq.
// Maybe can add extra pipeline stage to mitigate this issue.
//////////////////////////////////

module parser_op #(
	parameter MSIZE = 9,
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
  output reg [ 31:0]  out1_tag,
  output reg [127:0]  out1_value,

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
wire [63:0] fifo_rdata;
reg [63:0] eog_wdata;
wire fifo_wr;
wire fifo_wr_dummy; // dummy write for eop, to clean up next 8-byte memory
reg fifo_rd;
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

// creat a dummy write after avl_st_rx_eop goes low
reg [1:0] dummy_reg;
initial dummy_reg = 0;
always @(posedge clk) dummy_reg <= {dummy_reg[0],avl_st_rx_eop};
assign fifo_wr_dummy = (dummy_reg[0]^avl_st_rx_eop) & (~avl_st_rx_eop);
// for complement memory space in dummy write
wire [2:0] ext_fill; // complement memory space
assign ext_fill = 7-wr_cnt%8;


wire [3:0] pos;
assign pos = sm_pos(fifo_wdata);
// fifo write control
always @(posedge clk) begin
	if(rst) begin
		wr_cnt<=0;
		rd_cnt<=0;
	end else begin
		if(fifo_wr) wr_cnt <= wr_cnt + 8 + pos;
		if(fifo_wr_dummy) wr_cnt <= wr_cnt + ext_fill+1; // last dummy write
		if(fifo_rd) rd_cnt <= rd_cnt + 8;
	end
end

// when avl_st_rx_eop=0, and pos!=0, write in according to SMARK
always @(posedge clk) begin
	if(fifo_wr_dummy) begin  // clean up next 8-byte memory
		case(ext_fill)
			3'b000: begin
				// do nothing
			end
			3'b001: begin
	 			m[wr_cnt[MSIZE-1:0]+0] <= 8'h00;
			end
			3'b010: begin
	 			m[wr_cnt[MSIZE-1:0]+0] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+1] <= 8'h00;
			end
			3'b011: begin
	 			m[wr_cnt[MSIZE-1:0]+0] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+1] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+2] <= 8'h00;
			end
			3'b100: begin
	 			m[wr_cnt[MSIZE-1:0]+0] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+1] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+2] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+3] <= 8'h00;
			end
			3'b101: begin
	 			m[wr_cnt[MSIZE-1:0]+0] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+1] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+2] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+3] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+4] <= 8'h00;
			end
			3'b110: begin
	 			m[wr_cnt[MSIZE-1:0]+0] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+1] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+2] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+3] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+4] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+5] <= 8'h00;
			end
			3'b111: begin
	 			m[wr_cnt[MSIZE-1:0]+0] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+1] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+2] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+3] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+4] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+5] <= 8'h00;
	 			m[wr_cnt[MSIZE-1:0]+6] <= 8'h00;
			end
		endcase
	end else begin
	 if(fifo_wr) begin
		 case({avl_st_rx_eop,pos})
			 5'b00001: begin
	 	 						m[wr_cnt[MSIZE-1:0]+0] <= fifo_wdata[ 7:0 ];
	 	 						m[wr_cnt[MSIZE-1:0]+1] <= fifo_wdata[15:8 ];
	 	 						m[wr_cnt[MSIZE-1:0]+2] <= fifo_wdata[23:16];
	 	 						m[wr_cnt[MSIZE-1:0]+3] <= fifo_wdata[31:24];
	 	 						m[wr_cnt[MSIZE-1:0]+4] <= fifo_wdata[39:32];
	 	 						m[wr_cnt[MSIZE-1:0]+5] <= fifo_wdata[47:40];
	 	 						m[wr_cnt[MSIZE-1:0]+6] <= fifo_wdata[55:48];
	 	 						m[wr_cnt[MSIZE-1:0]+7] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+8] <= fifo_wdata[63:56];
			 end
			 5'b00010: begin
	 	 						m[wr_cnt[MSIZE-1:0]+0] <= fifo_wdata[ 7:0 ];
	 	 						m[wr_cnt[MSIZE-1:0]+1] <= fifo_wdata[15:8 ];
	 	 						m[wr_cnt[MSIZE-1:0]+2] <= fifo_wdata[23:16];
	 	 						m[wr_cnt[MSIZE-1:0]+3] <= fifo_wdata[31:24];
	 	 						m[wr_cnt[MSIZE-1:0]+4] <= fifo_wdata[39:32];
	 	 						m[wr_cnt[MSIZE-1:0]+5] <= fifo_wdata[47:40];
	 	 						m[wr_cnt[MSIZE-1:0]+6] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+7] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+8] <= fifo_wdata[55:48];
	 	 						m[wr_cnt[MSIZE-1:0]+9] <= fifo_wdata[63:56];
			 end
			 5'b00011: begin
	 	 						m[wr_cnt[MSIZE-1:0]+0] <= fifo_wdata[ 7:0 ];
	 	 						m[wr_cnt[MSIZE-1:0]+1] <= fifo_wdata[15:8 ];
	 	 						m[wr_cnt[MSIZE-1:0]+2] <= fifo_wdata[23:16];
	 	 						m[wr_cnt[MSIZE-1:0]+3] <= fifo_wdata[31:24];
	 	 						m[wr_cnt[MSIZE-1:0]+4] <= fifo_wdata[39:32];
	 	 						m[wr_cnt[MSIZE-1:0]+5] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+6] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+7] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+8] <= fifo_wdata[47:40];
	 	 						m[wr_cnt[MSIZE-1:0]+9] <= fifo_wdata[55:48];
	 	 						m[wr_cnt[MSIZE-1:0]+10] <= fifo_wdata[63:56];
			 end
			 5'b00100: begin
	 	 						m[wr_cnt[MSIZE-1:0]+0] <= fifo_wdata[ 7:0 ];
	 	 						m[wr_cnt[MSIZE-1:0]+1] <= fifo_wdata[15:8 ];
	 	 						m[wr_cnt[MSIZE-1:0]+2] <= fifo_wdata[23:16];
	 	 						m[wr_cnt[MSIZE-1:0]+3] <= fifo_wdata[31:24];
	 	 						m[wr_cnt[MSIZE-1:0]+4] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+5] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+6] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+7] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+8] <= fifo_wdata[39:32];
	 	 						m[wr_cnt[MSIZE-1:0]+9] <= fifo_wdata[47:40];
	 	 						m[wr_cnt[MSIZE-1:0]+10] <= fifo_wdata[55:48];
	 	 						m[wr_cnt[MSIZE-1:0]+11] <= fifo_wdata[63:56];
			 end
			 5'b00101: begin
	 	 						m[wr_cnt[MSIZE-1:0]+0] <= fifo_wdata[ 7:0 ];
	 	 						m[wr_cnt[MSIZE-1:0]+1] <= fifo_wdata[15:8 ];
	 	 						m[wr_cnt[MSIZE-1:0]+2] <= fifo_wdata[23:16];
	 	 						m[wr_cnt[MSIZE-1:0]+3] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+4] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+5] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+6] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+7] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+8] <= fifo_wdata[31:24];
	 	 						m[wr_cnt[MSIZE-1:0]+9] <= fifo_wdata[39:32];
	 	 						m[wr_cnt[MSIZE-1:0]+10] <= fifo_wdata[47:40];
	 	 						m[wr_cnt[MSIZE-1:0]+11] <= fifo_wdata[55:48];
	 	 						m[wr_cnt[MSIZE-1:0]+12] <= fifo_wdata[63:56];
			 end
			 5'b00110: begin
	 	 						m[wr_cnt[MSIZE-1:0]+0] <= fifo_wdata[ 7:0 ];
	 	 						m[wr_cnt[MSIZE-1:0]+1] <= fifo_wdata[15:8 ];
	 	 						m[wr_cnt[MSIZE-1:0]+2] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+3] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+4] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+5] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+6] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+7] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+8] <= fifo_wdata[23:16];
	 	 						m[wr_cnt[MSIZE-1:0]+9] <= fifo_wdata[31:24];
	 	 						m[wr_cnt[MSIZE-1:0]+10] <= fifo_wdata[39:32];
	 	 						m[wr_cnt[MSIZE-1:0]+11] <= fifo_wdata[47:40];
	 	 						m[wr_cnt[MSIZE-1:0]+12] <= fifo_wdata[55:48];
	 	 						m[wr_cnt[MSIZE-1:0]+13] <= fifo_wdata[63:56];
			 end
			 5'b00111: begin
	 	 						m[wr_cnt[MSIZE-1:0]+0] <= fifo_wdata[ 7:0 ];
	 	 						m[wr_cnt[MSIZE-1:0]+1] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+2] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+3] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+4] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+5] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+6] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+7] <= 8'h00;
	 	 						m[wr_cnt[MSIZE-1:0]+8] <= fifo_wdata[15:8 ];
	 	 						m[wr_cnt[MSIZE-1:0]+9] <= fifo_wdata[23:16];
	 	 						m[wr_cnt[MSIZE-1:0]+10] <= fifo_wdata[31:24];
	 	 						m[wr_cnt[MSIZE-1:0]+11] <= fifo_wdata[39:32];
	 	 						m[wr_cnt[MSIZE-1:0]+12] <= fifo_wdata[47:40];
	 	 						m[wr_cnt[MSIZE-1:0]+13] <= fifo_wdata[55:48];
	 	 						m[wr_cnt[MSIZE-1:0]+14] <= fifo_wdata[63:56];
			 end
			 default: begin
	 	 						m[wr_cnt[MSIZE-1:0]+0] <= fifo_wdata[ 7:0 ];
	 	 						m[wr_cnt[MSIZE-1:0]+1] <= fifo_wdata[15:8 ];
	 	 						m[wr_cnt[MSIZE-1:0]+2] <= fifo_wdata[23:16];
	 	 						m[wr_cnt[MSIZE-1:0]+3] <= fifo_wdata[31:24];
	 	 						m[wr_cnt[MSIZE-1:0]+4] <= fifo_wdata[39:32];
	 	 						m[wr_cnt[MSIZE-1:0]+5] <= fifo_wdata[47:40];
	 	 						m[wr_cnt[MSIZE-1:0]+6] <= fifo_wdata[55:48];
	 	 						m[wr_cnt[MSIZE-1:0]+7] <= fifo_wdata[63:56];
			 end
		 endcase
	 end
	end
end

assign fifo_rdata[ 7:0 ] = m[rd_cnt[MSIZE-1:0]+0];
assign fifo_rdata[15:8 ] = m[rd_cnt[MSIZE-1:0]+1];
assign fifo_rdata[23:16] = m[rd_cnt[MSIZE-1:0]+2];
assign fifo_rdata[31:24] = m[rd_cnt[MSIZE-1:0]+3];
assign fifo_rdata[39:32] = m[rd_cnt[MSIZE-1:0]+4];
assign fifo_rdata[47:40] = m[rd_cnt[MSIZE-1:0]+5];
assign fifo_rdata[55:48] = m[rd_cnt[MSIZE-1:0]+6];
assign fifo_rdata[63:56] = m[rd_cnt[MSIZE-1:0]+7];

reg [5:0] op_cnt;
reg [63:0] flg_data;
reg [191:0] tmp_data;
reg [3:0] state;
localparam S1= 4'b0001;
localparam S2= 4'b0010;
localparam S3= 4'b0100;
localparam S4= 4'b1000;

always @(posedge clk) begin
	if(rst) begin
		state<=S1;
		rd_cnt<=0;
		op_cnt<=0;
		flg_data<=0;
		tmp_data<=0;
	end else begin
		out1_valid <= 0; // output valid 
		fifo_rd<=0;
		op_cnt <= op_cnt + 1; 
		
		case(state)
		S1: begin  // idle
			if(fifo_cnt) begin
				state<=S2;
				fifo_rd <= 1;
				tmp_data <= 0;
				end
			end
		S2: begin  // readout flag
			fifo_rd <= 1;
			op_cnt <= 0; 
			flg_data <= fifo_rdata; // store 1st 64-bit for tag parser 
			tmp_data[63:0] <= fifo_rdata; // store 1st 64-bit for value parser 

			if(eq_pos(fifo_rdata)>5) begin // invalid tag length
				if(fifo_cnt==8) begin
					state <= S1; // last data, go to idle 
					fifo_rd <= 0;
				end else begin
					state <= S4; // no SMARK, go to S4 clean up
				end

				if(sm_check(fifo_rdata)) begin // if has SMARK, go to idle
					state<=S1;
					fifo_rd <= 0;
				end
			end else begin  // valid tag length
				state <= S3;
				if(sm_check(fifo_rdata)) begin // if has SMARK, go to idle
					state<=S1;
					out1_valid <= 1;
					fifo_rd <= 0;
				end
			end
			end
		S3: begin
			fifo_rd <= 1;
			if(op_cnt==0)
				tmp_data[127:64] <= fifo_rdata; // store 2nd 64-bit for value parser
			if(op_cnt==1) begin
				tmp_data[191:128] <= fifo_rdata; // store 3rd 64-bit for value parser
				out1_valid <= 1;
				state<=S4;                       // go to S4 clean up
			end
			if(sm_check(fifo_rdata)) begin // find SMARK, go to idle 
				state<=S1;
				out1_valid <= 1;
				fifo_rd <= 0;
			end
		end
		S4: begin
			fifo_rd <= 1;
			if(sm_check(fifo_rdata) || fifo_cnt==8) begin // find SMARK, go to idle 
				state<=S1;
				fifo_rd <= 0;
			end
		end
		default: state<=S1;
		endcase
	end
end

assign out1_tag = tag_parser(flg_data);
assign out1_value = value_parser(tmp_data);

//wire flag;
//assign flag = sm_check(fifo_rdata); 
	
// return position of SMARK
function [3:0] sm_pos;
	input [63:0] wdata;
	begin
		case(SMARK)
			wdata[ 7:0 ]: sm_pos = 7; 
			wdata[15:8 ]: sm_pos = 6; 
			wdata[23:16]: sm_pos = 5;
			wdata[31:24]: sm_pos = 4;
			wdata[39:32]: sm_pos = 3;
			wdata[47:40]: sm_pos = 2;
			wdata[55:48]: sm_pos = 1;
			wdata[63:56]: sm_pos = 0;
					 default: sm_pos = 0;
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
	integer i;
	begin
		for(i=0;i<8;i=i+1) begin
			if(wdata[7:0]==SMARK) begin
				sm_check = 1;
				break;
			end else begin
				wdata = wdata >> 8;
				sm_check = 0;
			end
		end
	end
endfunction

endmodule
