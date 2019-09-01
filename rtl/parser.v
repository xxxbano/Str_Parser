
module parser #(
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
wire [7:0] fifo_rdata;
reg [63:0] eog_wdata;
wire fifo_wr;
reg fifo_rd;
wire equal;  
wire full;  
wire empty;  


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

// fifo status signal
assign equal= wr_cnt[MSIZE-1:0] == rd_cnt[MSIZE-1:0]; 
assign full = (wr_cnt[MSIZE]^rd_cnt[MSIZE]) & equal;
assign empty =~(wr_cnt[MSIZE]^rd_cnt[MSIZE]) & equal;
assign fifo_cnt= wr_cnt - rd_cnt;

// fifo wr/rd signal
assign fifo_wr =avl_st_rx_valid &(~full);
assign fifo_wdata = (avl_st_rx_eop)? eog_wdata:avl_st_rx_data;
assign fifo_rdata = m[rd_cnt[MSIZE-1:0]];

// fifo write control
always @(posedge clk) begin
	if(rst) begin
		wr_cnt<=0;
		rd_cnt<=0;
	end else begin
		if(fifo_wr) wr_cnt <= wr_cnt+8;
		if(fifo_rd) rd_cnt <= rd_cnt + 1;
	end
end

// fifo 64-bit write in 8-bit read out
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
 //fifo_rdata <= m[rd_cnt[MSIZE-1:0]];
end
	
// for output alinement
reg [6:0] t_len; 
reg [6:0] v_len; 
reg [31:0] t_tmp;
reg [127:0] v_tmp;
// state machine for parser
reg [6:0] op_cnt; // count operation
reg [3:0] state;
localparam S1= 4'b0001;
localparam S2= 4'b0010;
localparam S3= 4'b0100;
localparam S4= 4'b1000; // go find SMARK

always @(posedge clk) begin
	if(rst) begin
		state<=S1;
		op_cnt<=0;
		t_tmp <= 0;
		v_tmp <= 0;
		t_len <= 0;
		v_len <= 0;
	end else begin
		out1_valid <= 0; // output valid 
		fifo_rd<=0;
		op_cnt <= op_cnt + 1; 
		
		case(state)
		S1: begin  // idle
			if(fifo_cnt) begin
				state<=S2;
				fifo_rd <= 1;
				op_cnt <= 0; // count for flag data
				t_tmp <= 0;
				v_tmp <= 0;
				end
			end
		S2: begin  // readout flag
			fifo_rd <= 1;
			if(fifo_rdata==8'h00) begin // if readout 0x00, do nothing
					op_cnt <= 0;            // clean up 0x00 for previous string package
					if(fifo_cnt==1) begin
						state <= S1; // if no data, go to idle
						fifo_rd <= 0;
					end
				end else begin
					if(fifo_rdata==8'h3d) begin // find '0x3d', go to value parser
						state<=S3; 
						op_cnt <= 0; 
				  	t_len <= op_cnt;
					end else begin
						if(op_cnt>3) begin // tag > 32-bit, ignore it, go to S4  
							state<=S4;       
						end else begin  // store tag value
							//out1_tag <= {out1_tag[23:0],fifo_rdata}; // temp store flag data
							t_tmp <= {fifo_rdata,t_tmp[31:8]}; // temp store flag data
						end
					end
			end
		end
		S3: begin
			fifo_rd <= 1;
			if(fifo_rdata == SMARK) begin // find SMARK, go to idle
				fifo_rd <= 0;
				v_len <= op_cnt;
				state<=S1;  
				out1_valid <= 1; // output valid 
			end else begin
				if(op_cnt > 15) begin  // not find SMARK, but enough value data
					out1_valid <= 1; // output valid 
					v_len <= op_cnt;
					state<=S4;  
				end else begin  // store value
					v_tmp <= {fifo_rdata,v_tmp[127:8]}; 
				end
			end
			end
		S4: begin
			fifo_rd <= 1;
			if(fifo_rdata == SMARK) begin // find space SMARK, go to idle
				state <= S1; 
				fifo_rd <= 0;
			end
			end
		default: state<=S1;
		endcase
	end
end

	assign out1_tag = t_conv(t_tmp,t_len);
	assign out1_value = v_conv(v_tmp,v_len);

// aline tag value function
	function [31:0] t_conv;
		input [31:0] in;
		input [6:0] len;
		case(len)
			7'b0000001: t_conv = in >> 3*8;
			7'b0000010: t_conv = in >> 2*8;
			7'b0000011: t_conv = in >> 1*8;
				 default: t_conv = in >> 0*8;
		endcase
	endfunction

// aline value value function
	function [127:0] v_conv;
		input [127:0] in;
		input [6:0] len;
		case(len)
			7'b0000001: v_conv = in >> 15*8;
			7'b0000010: v_conv = in >> 14*8;
			7'b0000011: v_conv = in >> 13*8;
			7'b0000100: v_conv = in >> 12*8;
			7'b0000101: v_conv = in >> 11*8;
			7'b0000110: v_conv = in >> 10*8;
			7'b0000111: v_conv = in >>  9*8;
			7'b0001000: v_conv = in >>  8*8;
			7'b0001001: v_conv = in >>  7*8;
			7'b0001010: v_conv = in >>  6*8;
			7'b0001011: v_conv = in >>  5*8;
			7'b0001100: v_conv = in >>  4*8;
			7'b0001101: v_conv = in >>  3*8;
			7'b0001110: v_conv = in >>  2*8;
			7'b0001111: v_conv = in >>  1*8;
				 default: v_conv = in >>  0*8;
		endcase
	endfunction

endmodule
