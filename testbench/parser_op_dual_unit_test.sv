`include "svunit_defines.svh"
`include "clk_and_reset.svh"
`include "fifo.v"
`include "parser_op_dual.v"

module parser_op_dual_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "parser_op_dual_ut";
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
	logic [127:0] res_v2;
	logic [127:0] res_v3;
	logic [31:0] res_t;
	logic [31:0] res_t0;
	logic [31:0] res_t1;
	logic [31:0] res_t2;
	logic [31:0] res_t3;
	logic [32*32-1:0] wdata;

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
  parser_op_dual my_parser_op_dual(.*);


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
	`FAIL_UNLESS_EQUAL(my_parser_op_dual.buf1_full,0);
	`FAIL_UNLESS_EQUAL(my_parser_op_dual.buf1_empty,1);
	`FAIL_UNLESS_EQUAL(my_parser_op_dual.buf2_full,0);
	`FAIL_UNLESS_EQUAL(my_parser_op_dual.buf2_empty,1);
  `SVTEST_END

  `SVTEST(test_3_continus_case_empty_7)
	// initial test data
	res_t0 = 32'h12345678; 
	res_v0 = 128'h1123456789abcdef1123456789abcdef;
	res_t1 = 32'h00001234; 
	res_v1 = 128'h0001456789abcdef1123456789abcdef; 
	res_t2 = 32'h00123456; 
	res_v2 = 128'h0000000189abcdef1123456789abcdef; 
	wdata = 1024'h0189abcdef1123456789abcdef3d12345601456789abcdef1123456789abcdef3d1234011123456789abcdef1123456789abcdef3d12345678;
	avl_st_rx_empty = 7;

	fork
		begin
			step(1); nextSamplePoint(); 
			avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
			avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
			for(i=0;i<6;i=i+1) begin
			step(1); nextSamplePoint(); 
			avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
			avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
			end
			step(1); nextSamplePoint(); 
			avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
			avl_st_rx_data = wdata[63:0]; 
			step(1); nextSamplePoint(); 
			avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
		end
		begin
			while(out1_valid!=1) step(1);
			`FAIL_UNLESS_EQUAL(out1_valid,1);
			`FAIL_UNLESS_EQUAL(out1_tag,res_t0);
			`FAIL_UNLESS_EQUAL(out1_value,res_v0);
			while(out2_valid!=1) step(1);
			`FAIL_UNLESS_EQUAL(out2_valid,1);
			`FAIL_UNLESS_EQUAL(out2_tag,res_t1);
			`FAIL_UNLESS_EQUAL(out2_value,res_v1);
			while(out1_valid!=1) step(1);
			`FAIL_UNLESS_EQUAL(out1_valid,1);
			`FAIL_UNLESS_EQUAL(out1_tag,res_t2);
			`FAIL_UNLESS_EQUAL(out1_value,res_v2);
		end
	join
	step(1);
  `SVTEST_END

  `SVTEST(test_4_continus_case_empty_3)
	// initial test data
	res_t0 = 32'h12345678; 
	res_v0 = 128'h1123456789abcdef1123456789abcdef;
	res_t1 = 32'h00001234; 
	res_v1 = 128'h0001456789abcdef1123456789abcdef; 
	res_t2 = 32'h00123456; 
	res_v2 = 128'h0000000189abcdef1123456789abcdef; 
	res_t3 = 32'h00000056; 
	res_v3 = 128'h000000000000000000000000000001ef; 
	wdata = 1024'h01ef3d560189abcdef1123456789abcdef3d12345601456789abcdef1123456789abcdef3d1234011123456789abcdef1123456789abcdef3d12345678;
	avl_st_rx_empty = 3;

	fork
		begin
			step(1); nextSamplePoint(); 
			avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
			avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
			for(i=0;i<6;i=i+1) begin
			step(1); nextSamplePoint(); 
			avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
			avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
			end
			step(1); nextSamplePoint(); 
			avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
			avl_st_rx_data = wdata[63:0]; 
			step(1); nextSamplePoint(); 
			avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
		end
		begin
			while(out2_valid!=1) step(1);
			`FAIL_UNLESS_EQUAL(out2_valid,1);
			`FAIL_UNLESS_EQUAL(out2_tag,res_t0);
			`FAIL_UNLESS_EQUAL(out2_value,res_v0);
			while(out1_valid!=1) step(1);
			`FAIL_UNLESS_EQUAL(out1_valid,1);
			`FAIL_UNLESS_EQUAL(out1_tag,res_t1);
			`FAIL_UNLESS_EQUAL(out1_value,res_v1);
			while(out2_valid!=1) step(1);
			`FAIL_UNLESS_EQUAL(out2_valid,1);
			`FAIL_UNLESS_EQUAL(out2_tag,res_t2);
			`FAIL_UNLESS_EQUAL(out2_value,res_v2);
			while(out1_valid!=1) step(1);
			`FAIL_UNLESS_EQUAL(out1_valid,1);
			`FAIL_UNLESS_EQUAL(out1_tag,res_t3);
			`FAIL_UNLESS_EQUAL(out1_value,res_v3);
		end
	join
	step(1);
  `SVTEST_END

  //`SVTEST(test_2_continus_case_empty_1)
  //// initial test data
  //res_t0 = 32'h12345678; 
  //res_v0 = 128'h0123456789abcdef1123456789abcdef;
  //res_t1 = 32'h00001234;
  //res_v1 = 128'h0001456789abcdef1123456789abcdef; 
  //wdata = 512'h0001456789abcdef1123456789abcdef3d12340123456789abcdef1123456789abcdef3d12345678;
  //avl_st_rx_empty = 1;

  //step(1); nextSamplePoint(); 
  //avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
  //avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	//for(i=0;i<3;i=i+1) begin
	//step(1); nextSamplePoint(); 
	//avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	//avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	//end
  //step(1); nextSamplePoint(); 
  //avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
  //avl_st_rx_data = wdata[63:0]; 
  //step(1); nextSamplePoint(); 
  //avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  //while(out1_valid!=1) step(1);
  //`FAIL_UNLESS_EQUAL(out1_valid,1);
  //`FAIL_UNLESS_EQUAL(out1_tag,res_t0);
  //`FAIL_UNLESS_EQUAL(out1_value,res_v0);
  //while(out2_valid!=1) step(1);
  //`FAIL_UNLESS_EQUAL(out2_valid,1);
  //`FAIL_UNLESS_EQUAL(out2_tag,res_t1);
  //`FAIL_UNLESS_EQUAL(out2_value,res_v1);
  //`SVTEST_END

  //`SVTEST(test_2_continus_case_empty_3)
  //// initial test data
  //res_t0 = 32'h12345678; 
  //res_v0 = 128'h0123456789abcdef1123456789abcdef; 
  //res_t1 = 32'h00001234; 
  //res_v1 = 128'h0000000189abcdef1123456789abcdef; 
  //wdata = 512'h0000000189abcdef1123456789abcdef3d12340123456789abcdef1123456789abcdef3d12345678;
  //avl_st_rx_empty = 3;

  //step(1); nextSamplePoint(); 
  //avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
  //avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	//for(i=0;i<3;i=i+1) begin
	//step(1); nextSamplePoint(); 
	//avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	//avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	//end
  //step(1); nextSamplePoint(); 
  //avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
  //avl_st_rx_data = wdata[63:0]; 
  //step(1); nextSamplePoint(); 
  //avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
  //while(out1_valid!=1) step(1);
  //`FAIL_UNLESS_EQUAL(out1_valid,1);
  //`FAIL_UNLESS_EQUAL(out1_tag,res_t0);
  //`FAIL_UNLESS_EQUAL(out1_value,res_v0);
  //while(out2_valid!=1) step(1);
  //`FAIL_UNLESS_EQUAL(out2_valid,1);
  //`FAIL_UNLESS_EQUAL(out2_tag,res_t1);
  //`FAIL_UNLESS_EQUAL(out2_value,res_v1);
  //`SVTEST_END

  //`SVTEST(test_2_continus_case_igonore_1st_for_5B_tag)
  //// initial test data
  //res_t0 = 32'h12345678; 
  //res_v0 = 128'h0123456789abcdef1123456789abcdef; 
  //res_t1 = 32'h00001234; 
  //res_v1 = 128'h0001456789abcdef2123456789abcdef; 
  //wdata = 512'h0001456789abcdef2123456789abcdef3d12340123456789abcdef2123456789abcd3def12345678;
  //avl_st_rx_empty = 1;

  //step(1); nextSamplePoint(); 
  //avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
  //avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	//for(i=0;i<3;i=i+1) begin
	//step(1); nextSamplePoint(); 
	//avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	//avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	//end
  //step(1); nextSamplePoint(); 
  //avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
  //avl_st_rx_data = wdata[63:0]; 
  //step(1); nextSamplePoint(); 
  //avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 

  //while(out2_valid!=1) step(1);
  //`FAIL_UNLESS_EQUAL(out2_valid,1);
  //`FAIL_UNLESS_EQUAL(out2_tag,res_t1);
  //`FAIL_UNLESS_EQUAL(out2_value,res_v1);
  //`SVTEST_END

  //`SVTEST(test_2_continus_case_igonore_2nd_for_5B_tag)
  //// initial test data
  //res_t0 = 32'h00001234; 
  //res_v0 = 128'h0123456789abcdef1123456789abcdef; 
  //res_t1 = 32'h12345678; 
  //res_v1 = 128'h0001456789abcdef1123456789abcdef; 
  //wdata = 512'h0001456789abcdef1123456789abcd3def123456780123456789abcdef1123456789abcdef3d1234;
  //avl_st_rx_empty = 1;

  //step(1); nextSamplePoint(); 
  //avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
  //avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	//for(i=0;i<3;i=i+1) begin
	//step(1); nextSamplePoint(); 
	//avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	//avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	//end
  //step(1); nextSamplePoint(); 
  //avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
  //avl_st_rx_data = wdata[63:0]; 
  //step(1); nextSamplePoint(); 
  //avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 

  //while(out1_valid!=1) step(1);
  //`FAIL_UNLESS_EQUAL(out1_valid,1);
  //`FAIL_UNLESS_EQUAL(out1_tag,res_t0);
  //`FAIL_UNLESS_EQUAL(out1_value,res_v0);
  //step(4);
  //`SVTEST_END

  //`SVTEST(test_2_continus_case_1st_ignore_17B_value)
	//// initial test data
	//res_t0 = 32'h12345678; 
	//res_v0 = 128'h1123456789abcdef1123456789abcdef; 
	//res_t1 = 32'h00001234; 
	//res_v1 = 128'h0123456789abcdef1123456789abcdef; 
	//wdata = 512'h0123456789abcdef1123456789abcdef3d123401ff1123456789abcdef1123456789abcdef3d12345678;
	//avl_st_rx_empty = 6;

	//step(1); nextSamplePoint(); 
	//avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
	//avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	//for(i=0;i<4;i=i+1) begin
	//step(1); nextSamplePoint(); 
	//avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	//avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	//end
	//step(1); nextSamplePoint(); 
	//avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
	//avl_st_rx_data = wdata[63:0]; 
	//step(1); nextSamplePoint(); 
	//avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	//while(out1_valid!=1) step(1);
	//`FAIL_UNLESS_EQUAL(out1_valid,1);
	//`FAIL_UNLESS_EQUAL(out1_tag,res_t0);
	//`FAIL_UNLESS_EQUAL(out1_value,res_v0);
	//while(out2_valid!=1) step(1);
	//`FAIL_UNLESS_EQUAL(out2_valid,1);
	//`FAIL_UNLESS_EQUAL(out2_tag,res_t1);
	//`FAIL_UNLESS_EQUAL(out2_value,res_v1);
  //`SVTEST_END

  //`SVTEST(test_2_continus_case_2nd_ignore_17B_value)
	//// initial test data
	////while(rdy!=1) step(1);
	//res_t0 = 32'h12345678; 
	//res_v0 = 128'h0123456789abcdef1123456789abcdef;
	//res_t1 = 32'h00001234; 
	//res_v1 = 128'h1123456789abcdef1123456789abcdef; 
	//wdata = 512'h01ff1123456789abcdef1123456789abcdef3d12340123456789abcdef1123456789abcdef3d12345678;
	//avl_st_rx_empty = 6;

	//step(1); nextSamplePoint(); 
	//avl_st_rx_valid = 1; avl_st_rx_sop = 1;  avl_st_rx_eop = 0; 
	//avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	//for(i=0;i<4;i=i+1) begin
	//step(1); nextSamplePoint(); 
	//avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	//avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	//end
	//step(1); nextSamplePoint(); 
	//avl_st_rx_valid = 1; avl_st_rx_sop = 0;  avl_st_rx_eop = 1; 
	//avl_st_rx_data = wdata[63:0]; 
	//step(1); nextSamplePoint(); 
	//avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	//while(out1_valid!=1) step(1);
	//`FAIL_UNLESS_EQUAL(out1_valid,1);
	//`FAIL_UNLESS_EQUAL(out1_tag,res_t0);
	//`FAIL_UNLESS_EQUAL(out1_value,res_v0);
	//while(out2_valid!=1) step(1);
	//`FAIL_UNLESS_EQUAL(out2_valid,1);
	//`FAIL_UNLESS_EQUAL(out2_tag,res_t1);
	//`FAIL_UNLESS_EQUAL(out2_value,res_v1);
  //`SVTEST_END

  //`SVTEST(test_random_400)
	//// initial test data
	////while(eq_pos<1) eq_pos = $random%4; 
	//for(j=0;j<200;j=j+1) begin
	//	eq_pos = 0; sp_pos = 0; 
	//	while(eq_pos<1) eq_pos = $random%5; 
	//	while(sp_pos<1) sp_pos = $random%16; 
	//	res_tag = 0; res_value = 0; rd_cnt=0;
	//	for(i=0;i<eq_pos;i=i+1) begin
	//		tmp8=$random;
	//		while(tmp8==8'h3d || tmp8==8'h20) tmp8=$random;
	//		res_tag={tmp8,res_tag[31:8]};
	//		wdata={tmp8,wdata[32*8-1:8]};
	//	end
  //	res_tag=res_tag>>(4-eq_pos)*8; wdata={8'h3d,wdata[32*8-1:8]};
  //	//wdata={8'h3d,wdata[32*8-1:8]};
	//	for(i=0;i<sp_pos;i=i+1) begin
	//		tmp8=$random;
	//		while(tmp8==8'h3d || tmp8==8'h20) tmp8=$random;
	//		res_value={tmp8,res_value[127:8]};
	//		//res_value={res_value[119:0],tmp8};
	//		wdata={tmp8,wdata[32*8-1:8]};
	//	end
  //	res_value={8'h20,res_value[127:8]}; res_value=res_value>>(16-sp_pos-1)*8; 
	//	wdata={8'h20,wdata[32*8-1:8]}; wdata = wdata >> (30-sp_pos-eq_pos)*8;
	//	//wdata={8'h20,wdata[32*8-1:8]}; wdata = wdata >> (30-sp_pos-eq_pos)*8;

	//	// setup first write 
	//	step(1); nextSamplePoint(); 
	//	avl_st_rx_valid = 1; avl_st_rx_sop = 1;  
	//	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	//	if(rd_cnt >= sp_pos+eq_pos+2) begin
	//		avl_st_rx_eop = 1; avl_st_rx_empty = rd_cnt-sp_pos-eq_pos-2;
	//	end
	//	// setup first write 
	//	while(rd_cnt < sp_pos+eq_pos +2) begin
	//		step(1); nextSamplePoint(); 
	//		avl_st_rx_valid = 1; avl_st_rx_sop = 0;  
	//		avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	//		if(rd_cnt >= sp_pos+eq_pos+2) begin
	//			avl_st_rx_eop = 1; avl_st_rx_empty = rd_cnt-sp_pos-eq_pos-2;
	//		end
	//	end
	//	step(1); nextSamplePoint(); 
	//	avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	//	if(j%2) begin
	//	while(out2_valid!=1) step(1);
	//  `FAIL_UNLESS_EQUAL(out2_valid,1);
	//  `FAIL_UNLESS_EQUAL(out2_tag,res_tag);
	//  `FAIL_UNLESS_EQUAL(out2_value,res_value);
	//	end else begin
	//	while(out1_valid!=1) step(1);
	//	`FAIL_UNLESS_EQUAL(out1_valid,1);
	//	`FAIL_UNLESS_EQUAL(out1_tag,res_tag);
	//	`FAIL_UNLESS_EQUAL(out1_value,res_value);
	//	end
	//	step(1);
	//end
  //`SVTEST_END

  `SVUNIT_TESTS_END
//
//	initial begin
//		//$monitor("%d, %b, %x, %x, %x, %x,%d,%d",$stime,clk, res_tag, res_value, wdata,tmp8,eq_pos,sp_pos);
//		$monitor("%d, %b, %b, %b, %x, %b, %b, %d, %b, %x, %x, %b,%x,%x,%d,%d,%d,%d,%x,%x,%d,%x,%x,%d,%d,%d,%d",$stime,my_parser_op_dual.clk, my_parser_op_dual.rst, my_parser_op_dual.avl_st_rx_valid,my_parser_op_dual.avl_st_rx_data,my_parser_op_dual.avl_st_rx_sop,my_parser_op_dual.avl_st_rx_eop,my_parser_op_dual.avl_st_rx_empty,my_parser_op_dual.out1_valid,my_parser_op_dual.out1_tag,my_parser_op_dual.out1_value,my_parser_op_dual.out2_valid,my_parser_op_dual.out2_tag,my_parser_op_dual.out2_value, rd_cnt,my_parser_op_dual.state1,my_parser_op_dual.op1_cnt,my_parser_op_dual.buf1_rdata,res_tag,my_parser_op_dual.tmp1_data,my_parser_op_dual.tmp2_data,res_tag,res_value,my_parser_op_dual.buf1_wr,my_parser_op_dual.state2,my_parser_op_dual.buf_wdata,my_parser_op_dual.buf1_rd);
//		//$monitor("%d, %b, %b, %b, %b",$stime,clk, rst, en,wr);
//		$dumpfile("parser.vcd");
//		$dumpvars(0,parser_op_dual_unit_test.my_parser_op_dual);
//		$dumpvars;
//	end

endmodule
