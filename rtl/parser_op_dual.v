//////////////////////////////////
// v0.2 string parser
// 2019-08-31 by Zhengfan Xia
//////////////////////////////////

module parser_op_dual(
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

parameter MSIZE = 8;


reg [63:0] eog_wdata;

// fifo1 signal 
wire [MSIZE:0] fifo1_cnt;
wire [63:0] fifo_wdata;
wire [63:0] fifo1_rdata;
wire fifo1_wr;
reg fifo1_rd;
wire fifo1_full;  
wire fifo1_empty;  

// fifo2 signal 
wire [MSIZE:0] fifo2_cnt;
wire [63:0] fifo2_rdata;
wire fifo2_wr;
reg fifo2_rd;
wire fifo2_full;  
wire fifo2_empty;  

////////////////////////////
// enable 2 channels
// each package data steer to different fifos
// for 2-channel operation
////////////////////////////
//reg steer;
//always @(posedge clk) begin
//	if(rst) begin
//		steer <= 0;
//	end else begin
//		if(avl_st_rx_eop) steer <= ~steer;
//	end
//end
//assign fifo1_wr = (steer)? 0:avl_st_rx_valid;
//assign fifo2_wr = (steer)? avl_st_rx_valid:0;

// for testing
assign fifo1_wr = avl_st_rx_valid;
assign fifo2_wr = avl_st_rx_valid;

assign fifo_wdata = (avl_st_rx_eop)? eog_wdata:avl_st_rx_data;

fifo #(.DSIZE(64), .MSIZE(8)) i_f1(
	.rst(rst),
	.clk(clk),
	.wr(fifo1_wr),
	.rd(fifo1_rd),
	.wdata(fifo_wdata),
	.rdata(fifo1_rdata),
	.count(fifo1_cnt),
	.full(fifo1_full),
	.empty(fifo1_empty),
	.overflow(),
	.underflow()
);

fifo #(.DSIZE(64), .MSIZE(8)) i_f2(
	.rst(rst),
	.clk(clk),
	.wr(fifo2_wr),
	.rd(fifo2_rd),
	.wdata(fifo_wdata),
	.rdata(fifo2_rdata),
	.count(fifo2_cnt),
	.full(fifo2_full),
	.empty(fifo2_empty),
	.overflow(),
	.underflow()
);

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

//////////////////////////////////////
// for out 1
//////////////////////////////////////

reg [5:0] op1_cnt;
reg [63:0] flg1_data;
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
		flg1_data<=0;
		tmp1_data<=0;
	end else begin
		out1_valid <= 0; // output valid 
		fifo1_rd<=0;
		op1_cnt <= op1_cnt + 1; 
		
		case(state1)
		S11: begin  // idle, if fifo not empty, run
			if(fifo1_cnt) begin
				state1<=S12;
				fifo1_rd <= 1;
				tmp1_data <= 0;
				end
			end
		S12: begin  // readout tag data
			fifo1_rd <= 1;
			flg1_data <= fifo1_rdata; // temp store flag data
			tmp1_data[63:0] <= fifo1_rdata; // temp store flag data
			state1 <= S13;
			if(space_check(fifo1_rdata)) begin
				state1<=S11;
				out1_valid <= 1;
				fifo1_rd <= 0;
			end
			op1_cnt <= 0; 
			end
		S13: begin // readout value data
			fifo1_rd <= 1;
			if(op1_cnt==0)
				tmp1_data[127:64] <= fifo1_rdata; // temp store flag data
			if(op1_cnt==1)
				tmp1_data[191:128] <= fifo1_rdata; // temp store flag data
			if(space_check(fifo1_rdata)) begin
				state1<=S11;
				out1_valid <= 1;
				fifo1_rd <= 0;
			end
		end
		default: state1<=S11;
		endcase
	end
end

assign out1_tag = tag_parser(flg1_data);
assign out1_value = value_parser(tmp1_data);

//////////////////////////////////////
// for out 2
//////////////////////////////////////

reg [5:0] op2_cnt;
reg [63:0] flg2_data;
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
		flg2_data<=0;
		tmp2_data<=0;
	end else begin
		out2_valid <= 0; // output valid 
		fifo2_rd<=0;
		op2_cnt <= op2_cnt + 1; 
		
		case(state2)
		S21: begin  // idle
			if(fifo2_cnt) begin
				state2<=S22;
				fifo2_rd <= 1;
				tmp2_data <= 0;
				end
			end
		S22: begin  // readout flag
			fifo2_rd <= 1;
			flg2_data <= fifo2_rdata; // temp store flag data
			tmp2_data[63:0] <= fifo2_rdata; // temp store flag data
			state2 <= S23;
			if(space_check(fifo2_rdata)) begin
				state2<=S21;
				out2_valid <= 1;
				fifo2_rd <= 0;
			end
			op2_cnt <= 0; 
			end
		S23: begin
			fifo2_rd <= 1;
			if(op2_cnt==0)
				tmp2_data[127:64] <= fifo2_rdata; // temp store flag data
			if(op2_cnt==1)
				tmp2_data[191:128] <= fifo2_rdata; // temp store flag data
			if(space_check(fifo2_rdata)) begin
				state2<=S21;
				out2_valid <= 1;
				fifo2_rd <= 0;
			end
		end
		default: state2<=S21;
		endcase
	end
end

assign out2_tag = tag_parser(flg2_data);
assign out2_value = value_parser(tmp2_data);

wire flag;
assign flag = space_check(fifo1_rdata); 

// return tag_value 
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

// return out_value 
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

// check space '0x20' symbol
function space_check;
	input [64:0] wdata;
	integer i;
	begin
		for(i=0;i<8;i=i+1) begin
			if(wdata[7:0]==8'h20) begin
				space_check = 1;
				break;
			end else begin
				wdata = wdata >> 8;
				space_check = 0;
			end
		end
	end
endfunction

endmodule
