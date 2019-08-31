
module parser_tb;

reg clk;
reg rst;
reg avl_st_rx_valid;
reg [63:0] avl_st_rx_data;
reg avl_st_rx_sop;
reg avl_st_rx_eop;
reg [2:0] avl_st_rx_empty;

wire out1_valid;
wire [31:0] out1_tag;
wire [127:0] out1_value;

wire out2_valid;
wire [31:0] out2_tag;
wire [127:0] out2_value;

reg [31:0] my_mem[0:255];

parser i_inst(
 .clk(clk),
 .rst(rst),
 .avl_st_rx_valid(avl_st_rx_valid),
 .avl_st_rx_data(avl_st_rx_data),
 .avl_st_rx_sop(avl_st_rx_sop),
 .avl_st_rx_eop(avl_st_rx_eop),
 .avl_st_rx_empty(avl_st_rx_empty),

 .out1_valid(out1_valid),
 .out1_tag(out1_tag),
 .out1_value(out1_value),

 .out2_valid(out2_valid),
 .out2_tag(out2_tag),
 .out2_value(out2_value)
);


initial begin
clk = 0;
rst = 0;
avl_st_rx_valid = 0;
avl_st_rx_data = 0;
avl_st_rx_sop = 0;
avl_st_rx_eop = 0;
avl_st_rx_empty = 0;
end

always #10 clk=~clk;

integer i;

initial begin
$readmemh("file.dat",my_mem);
for(i=0;i<10;i=i+1) begin
 $display("%x",my_mem[i]);
end
#10 rst=1;
#50 rst=0;
// test value < 128 bit
 @(negedge clk) 
 avl_st_rx_valid = 1; avl_st_rx_sop = 1; avl_st_rx_eop = 0;
 avl_st_rx_data = {my_mem[0],my_mem[1]};
 @(negedge clk) 
 avl_st_rx_valid = 1; avl_st_rx_sop = 0; avl_st_rx_eop = 1; avl_st_rx_empty =3;
 avl_st_rx_data = {my_mem[2],my_mem[3]};
 @(negedge clk) 
 avl_st_rx_valid = 0; avl_st_rx_sop = 0; avl_st_rx_eop = 0;

// test value > 128 bit
 @(negedge clk) 
 avl_st_rx_valid = 1; avl_st_rx_sop = 1; avl_st_rx_eop = 0;
 avl_st_rx_data = {my_mem[4],my_mem[5]};
 @(negedge clk) 
 avl_st_rx_valid = 1; avl_st_rx_sop = 0; avl_st_rx_eop = 0;
 avl_st_rx_data = {my_mem[5],my_mem[5]};
 @(negedge clk) 
 avl_st_rx_valid = 1; avl_st_rx_sop = 0; avl_st_rx_eop = 0;
 avl_st_rx_data = {my_mem[8],my_mem[7]};
 @(negedge clk) 
 avl_st_rx_valid = 1; avl_st_rx_sop = 0; avl_st_rx_eop = 0;
 avl_st_rx_data = {my_mem[9],my_mem[8]};
 @(negedge clk) 
 avl_st_rx_valid = 1; avl_st_rx_sop = 0; avl_st_rx_eop = 1; avl_st_rx_empty =3;
 avl_st_rx_data = {my_mem[10],my_mem[11]};
 @(negedge clk) 
 avl_st_rx_valid = 0; avl_st_rx_sop = 0; avl_st_rx_eop = 0;

// test flag > 32 bit
//for(i=1;i<4;i=i+1) begin
// @(negedge clk) 
// avl_st_rx_valid = 1; avl_st_rx_sop = 0;
// avl_st_rx_data = {my_mem[2*i],my_mem[2*i+1]};
//end
#2000;
$finish;
end

initial begin
//$monitor("%d",clk);
$dumpfile("dump.vcd");
$dumpvars(0,parser_tb);
end
endmodule





//initial begin
//    $display("hello");
//    $finish();
//end




