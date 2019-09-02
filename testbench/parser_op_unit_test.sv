`include "svunit_defines.svh"
`include "clk_and_reset.svh"
`include "fifo.v"
`include "parser_op.v"

module parser_op_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "parser_op_ut";
  svunit_testcase svunit_ut;

	parameter CLK_HPERIOD = 5; // pulse width
	parameter RST_PERIOD = 2;  // 4 clock
	`CLK_RESET_FIXTURE(CLK_HPERIOD,RST_PERIOD);
	logic rst;
	assign rst = !rst_n;

	parameter MDF=8; // STACK_MEM_DEPTH=2**MDF
  logic avl_st_rx_valid;
  logic [63:0] avl_st_rx_data;
  logic avl_st_rx_sop;
  logic avl_st_rx_eop;
  logic [2:0] avl_st_rx_empty;
  //logic   rdy;
  
  logic   out1_valid;
  logic [ 31:0]  out1_tag;
  logic [127:0]  out1_value;
  logic   out2_valid;
  logic [ 31:0]  out2_tag;
	logic [127:0]  out2_value;

	logic [7:0] tmp_mem[0:2**MDF-1];
	logic [127:0] res_value;
	logic [31:0] res_tag_tmp;
	logic [31:0] res_tag;
	logic [127:0] res_v;
	logic [127:0] res_v0;
	logic [127:0] res_v1;
	logic [31:0] res_t;
	logic [31:0] res_t0;
	logic [31:0] res_t1;
	logic [32*16-1:0] wdata;

	parameter CH_SIZE = 1000;  
	logic [7:0] str[CH_SIZE];
	logic [7:0] tmp8;
	string line;


	integer i;
	integer j;
	integer eq_pos;
	integer sp_pos;
	integer rd_cnt;

	initial avl_st_rx_valid = 0;
	initial avl_st_rx_data = 0;
	initial avl_st_rx_sop = 0;
	initial avl_st_rx_eop = 0;
	initial avl_st_rx_empty = 0;
	initial rd_cnt = 0;
	initial eq_pos = 0;
	initial sp_pos = 0;


  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  parser_op my_parser_op(.*);


  //===================================
  // Build
  //===================================
  function void build();
    svunit_ut = new(name);
  endfunction


  //===================================
  // Setup for running the Unit Tests
  //===================================
  task setup();
    svunit_ut.setup();
    /* Place Setup Code Here */

  endtask


  //===================================
  // Here we deconstruct anything we 
  // need after running the Unit Tests
  //===================================
  task teardown();
    svunit_ut.teardown();
    /* Place Teardown Code Here */

  endtask


  //===================================
  // All tests are defined between the
  // SVUNIT_TESTS_BEGIN/END macros
  //
  // Each individual test must be
  // defined between `SVTEST(_NAME_)
  // `SVTEST_END
  //
  // i.e.
  //   `SVTEST(mytest)
  //     <test code>
  //   `SVTEST_END
  //===================================
  `SVUNIT_TESTS_BEGIN

  `SVTEST(test_rst)
	step(1);   // 1 clock step
	reset();
	`FAIL_UNLESS_EQUAL(my_parser_op.full,0);
	`FAIL_UNLESS_EQUAL(my_parser_op.empty,1);
  `SVTEST_END


  `SVTEST(test_2_continus_case_empty_0)
	// initial test data
	res_t0 = 32'h12345678; 
	res_v0 = 128'h1123456789abcdef1123456789abcdef;
	res_t1 = 32'h00001234; 
	res_v1 = 128'h0001456789abcdef1123456789abcdef; 
	wdata = 512'h01456789abcdef1123456789abcdef3d1234011123456789abcdef1123456789abcdef3d12345678;
	avl_st_rx_empty = 0;

	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
	avl_st_rx_data = wdata[63:0]; 
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	while(out1_valid!=1) step(1);
	`FAIL_UNLESS_EQUAL(out1_valid,1);
	`FAIL_UNLESS_EQUAL(out1_tag,res_t0);
	`FAIL_UNLESS_EQUAL(out1_value,res_v0);
	step(2);
	while(out1_valid!=1) step(1);
	`FAIL_UNLESS_EQUAL(out1_valid,1);
	`FAIL_UNLESS_EQUAL(out1_tag,res_t1);
	`FAIL_UNLESS_EQUAL(out1_value,res_v1);
  `SVTEST_END

  `SVTEST(test_2_continus_case_empty_1)
  // initial test data
  res_t0 = 32'h12345678; 
  res_v0 = 128'h0123456789abcdef1123456789abcdef;
  res_t1 = 32'h00001234;
  res_v1 = 128'h0001456789abcdef1123456789abcdef; 
  wdata = 512'h0001456789abcdef1123456789abcdef3d12340123456789abcdef1123456789abcdef3d12345678;
  avl_st_rx_empty = 1;

  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
  avl_st_rx_data = wdata[63:0]; 
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  while(out1_valid!=1) step(1);
  `FAIL_UNLESS_EQUAL(out1_valid,1);
  `FAIL_UNLESS_EQUAL(out1_tag,res_t0);
  `FAIL_UNLESS_EQUAL(out1_value,res_v0);
  step(2);
  while(out1_valid!=1) step(1);
  `FAIL_UNLESS_EQUAL(out1_valid,1);
  `FAIL_UNLESS_EQUAL(out1_tag,res_t1);
  `FAIL_UNLESS_EQUAL(out1_value,res_v1);
  `SVTEST_END

  `SVTEST(test_2_continus_case_empty_3)
  // initial test data
  res_t0 = 32'h12345678; 
  res_v0 = 128'h0123456789abcdef1123456789abcdef; 
  res_t1 = 32'h00001234; 
  res_v1 = 128'h0000000189abcdef1123456789abcdef; 
  wdata = 512'h0000000189abcdef1123456789abcdef3d12340123456789abcdef1123456789abcdef3d12345678;
  avl_st_rx_empty = 3;

  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
  avl_st_rx_data = wdata[63:0]; 
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  while(out1_valid!=1) step(1);
  `FAIL_UNLESS_EQUAL(out1_valid,1);
  `FAIL_UNLESS_EQUAL(out1_tag,res_t0);
  `FAIL_UNLESS_EQUAL(out1_value,res_v0);
  step(2);
  while(out1_valid!=1) step(1);
  `FAIL_UNLESS_EQUAL(out1_valid,1);
  `FAIL_UNLESS_EQUAL(out1_tag,res_t1);
  `FAIL_UNLESS_EQUAL(out1_value,res_v1);
  `SVTEST_END

  `SVTEST(test_2_continus_case_igonore_1st_for_5B_tag)
  // initial test data
  res_t0 = 32'h12345678; 
  res_v0 = 128'h0123456789abcdef1123456789abcdef; 
  res_t1 = 32'h00001234; 
  res_v1 = 128'h0001456789abcdef2123456789abcdef; 
  wdata = 512'h0001456789abcdef2123456789abcdef3d12340123456789abcdef2123456789abcd3def12345678;
  avl_st_rx_empty = 1;

  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
  avl_st_rx_data = wdata[63:0]; 
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 

  while(out1_valid!=1) step(1);
  `FAIL_UNLESS_EQUAL(out1_valid,1);
  `FAIL_UNLESS_EQUAL(out1_tag,res_t1);
  `FAIL_UNLESS_EQUAL(out1_value,res_v1);
  `SVTEST_END

  `SVTEST(test_2_continus_case_igonore_2nd_for_5B_tag)
  // initial test data
  res_t0 = 32'h00001234; 
  res_v0 = 128'h0123456789abcdef1123456789abcdef; 
  res_t1 = 32'h12345678; 
  res_v1 = 128'h0001456789abcdef1123456789abcdef; 
  wdata = 512'h0001456789abcdef1123456789abcd3def123456780123456789abcdef1123456789abcdef3d1234;
  avl_st_rx_empty = 1;

  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
  avl_st_rx_data = wdata[63:0]; 
  step(1); nextSamplePoint(); 
  avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 

  while(out1_valid!=1) step(1);
  `FAIL_UNLESS_EQUAL(out1_valid,1);
  `FAIL_UNLESS_EQUAL(out1_tag,res_t0);
  `FAIL_UNLESS_EQUAL(out1_value,res_v0);
  step(4);
  `SVTEST_END

  `SVTEST(test_2_continus_case_1st_ignore_17B_value)
	// initial test data
	res_t0 = 32'h12345678; 
	res_v0 = 128'h1123456789abcdef1123456789abcdef; 
	res_t1 = 32'h00001234; 
	res_v1 = 128'h0123456789abcdef1123456789abcdef; 
	wdata = 512'h0123456789abcdef1123456789abcdef3d123401ff1123456789abcdef1123456789abcdef3d12345678;
	avl_st_rx_empty = 6;

	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
	avl_st_rx_data = wdata[63:0]; 
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	while(out1_valid!=1) step(1);
	`FAIL_UNLESS_EQUAL(out1_valid,1);
	`FAIL_UNLESS_EQUAL(out1_tag,res_t0);
	`FAIL_UNLESS_EQUAL(out1_value,res_v0);
	step(2);
	while(out1_valid!=1) step(1);
	`FAIL_UNLESS_EQUAL(out1_valid,1);
	`FAIL_UNLESS_EQUAL(out1_tag,res_t1);
	`FAIL_UNLESS_EQUAL(out1_value,res_v1);
  `SVTEST_END

  `SVTEST(test_2_continus_case_2nd_ignore_17B_value)
	// initial test data
	//while(rdy!=1) step(1);
	res_t0 = 32'h12345678; 
	res_v0 = 128'h0123456789abcdef1123456789abcdef;
	res_t1 = 32'h00001234; 
	res_v1 = 128'h1123456789abcdef1123456789abcdef; 
	wdata = 512'h01ff1123456789abcdef1123456789abcdef3d12340123456789abcdef1123456789abcdef3d12345678;
	avl_st_rx_empty = 6;

	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
	avl_st_rx_data = wdata[63:0]; 
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	while(out1_valid!=1) step(1);
	`FAIL_UNLESS_EQUAL(out1_valid,1);
	`FAIL_UNLESS_EQUAL(out1_tag,res_t0);
	`FAIL_UNLESS_EQUAL(out1_value,res_v0);
	step(2);
	while(out1_valid!=1) step(1);
	`FAIL_UNLESS_EQUAL(out1_valid,1);
	`FAIL_UNLESS_EQUAL(out1_tag,res_t1);
	`FAIL_UNLESS_EQUAL(out1_value,res_v1);
  `SVTEST_END

  `SVUNIT_TESTS_END

//	initial begin
//		//$monitor("%d, %b, %x, %x, %x, %x,%d,%d",$stime,clk, res_tag, res_value, wdata,tmp8,eq_pos,sp_pos);
//		$monitor("%d, %b, %b, %b, %x, %b, %b, %d, %b, %x, %x, %b,%x,%x,%d,%d,%d,%d,%x,%x,%d,%x,%x,%d,%d,%d,%d,%d,%d,%d,%dd",$stime,my_parser_op.clk, my_parser_op.rst, my_parser_op.avl_st_rx_valid,my_parser_op.avl_st_rx_data,my_parser_op.avl_st_rx_sop,my_parser_op.avl_st_rx_eop,my_parser_op.avl_st_rx_empty,my_parser_op.out1_valid,my_parser_op.out1_tag,my_parser_op.out1_value,my_parser_op.out2_valid,my_parser_op.out2_tag,my_parser_op.out2_value, rd_cnt,my_parser_op.state,my_parser_op.op_cnt,my_parser_op.rd_cnt,my_parser_op.buf_rdata,my_parser_op.buf_wdata,my_parser_op.tmp_data,res_tag,res_value,my_parser_op.buf_wr,my_parser_op.buf_rd,my_parser_op.pos,my_parser_op.fifo_wdata,my_parser_op.wr_cnt,my_parser_op.fifo_cnt,my_parser_op.buf_count,my_parser_op.mem_zero);
//		//$monitor("%d, %b, %b, %b, %b",$stime,clk, rst, en,wr);
//		$dumpfile("parser.vcd");
//		$dumpvars(0,parser_op_unit_test.my_parser_op);
//		$dumpvars;
//	end

endmodule
