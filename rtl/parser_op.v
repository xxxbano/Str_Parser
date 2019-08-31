//////////////////////////////////
// v0.1 string parser
// 2019-08-31 by Zhengfan Xia
//////////////////////////////////

module parser_op(
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


// fifo signal 
wire [MSIZE:0] fifo_cnt;
reg [63:0] m[0:(1<<MSIZE)-1];
reg [MSIZE:0] wr_cnt;
reg [MSIZE:0] rd_cnt;
wire [63:0] fifo_wdata;
wire [63:0] fifo_rdata;
reg [63:0] eog_wdata;
wire fifo_wr;
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

// fifo write control
always @(posedge clk) begin
	if(rst) begin
		wr_cnt<=0;
		rd_cnt<=0;
	end else begin
		if(fifo_wr) wr_cnt <= wr_cnt + 1;
		if(fifo_rd) rd_cnt <= rd_cnt + 1;
	end
end

assign fifo_wdata = (avl_st_rx_eop)? eog_wdata:avl_st_rx_data;

// fifo 
always @(posedge clk) begin
 if(fifo_wr) begin
 	 m[wr_cnt[MSIZE-1:0]] <= fifo_wdata;
 end
end

assign fifo_rdata = m[rd_cnt[MSIZE-1:0]];


wire go_idle;
wire go_s4;
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
			flg_data <= fifo_rdata; // store 1st 64-bit for tag parser 
			tmp_data[63:0] <= fifo_rdata; // store 1st 64-bit for value parser 
			state <= S3;
			if(space_check(fifo_rdata)) begin
				state<=S1;
				out1_valid <= 1;
				fifo_rd <= 0;
			end
			op_cnt <= 0; 
			end
		S3: begin
			fifo_rd <= 1;
			if(op_cnt==0)
				tmp_data[127:64] <= fifo_rdata; // store 2nd 64-bit for value parser
			if(op_cnt==1)
				tmp_data[191:128] <= fifo_rdata; // store 3rd 64-bit for value parser
			if(space_check(fifo_rdata)) begin // find 0x20 Spacer, go to idle 
				state<=S1;
				out1_valid <= 1;
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
//assign flag = space_check(fifo_rdata); 

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
