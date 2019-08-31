
module parser(
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
		if(fifo_wr) wr_cnt <= wr_cnt+8;
		if(fifo_rd) rd_cnt <= rd_cnt + 1;
	end
end

assign fifo_wdata = (avl_st_rx_eop)? eog_wdata:avl_st_rx_data;

// fifo 
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

assign fifo_rdata = m[rd_cnt[MSIZE-1:0]];



wire go_idle;
wire go_s4;
reg space_flag;
reg [6:0] op_cnt;
reg [31:0] flg_data;
reg [127:0] val_data;
reg [2:0] state;
localparam S1= 3'b001;
localparam S2= 3'b010;
localparam S3= 3'b100;

always @(posedge clk) begin
	if(rst) begin
		state<=S1;
		rd_cnt<=0;
		op_cnt<=0;
		flg_data<=0;
		space_flag <= 0; // output valid 
	end else begin
		flg_data<=0;
		val_data<=0;
		out1_valid <= 0; // output valid 
		fifo_rd<=0;
		op_cnt <= op_cnt + 1; 
		
		case(state)
		S1: begin  // idle
			if(fifo_cnt) begin
				state<=S2;
				fifo_rd <= 1;
				op_cnt <= 0; // count for flag data
				out1_value <= 0;
				space_flag=0;
				end
			end
		S2: begin  // readout flag
			fifo_rd <= 1;
			if(fifo_rdata!=8'h3d) begin
				flg_data <= {flg_data[23:0],fifo_rdata}; // temp store flag data
				end else begin
				out1_tag<=flg_data; // store flag data in output
				state<=S3; // check = '0x3d', go to value parser
				out1_value <= 0;
				end
			end
		S3: begin
			fifo_rd <= 1;
			if(fifo_rdata == 8'h20) space_flag <= 1; 
			if(go_idle) begin
				fifo_rd <= 0;
				out1_valid <= 1; // output valid 
				state<=S1;  
			end else begin
				if(~(fifo_rdata == 8'h20 || space_flag))
					out1_value <= {out1_value[119:0],fifo_rdata}; // temp store value data
			end
			end
		default: state<=S1;
		endcase
	end
end

assign go_idle = rd_cnt%8 == 7 && (fifo_rdata == 8'h20 || space_flag);

endmodule
