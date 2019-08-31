`include "svunit_defines.svh"
`include "clk_and_reset.svh"
`include "parser.v"

module parser_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "parser_ut";
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
	logic [32*8-1:0] wdata;

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

	// read text
	//integer fd;
	//initial begin
	//	fd = $fopen("file.txt","r");
	//	$fgets(line,fd);
	//	$display("%s",line);
	//	//$display("%x",line.atoi());
	//	//$display("%x",line.atohex());
	//	for(i=0;i<line.len();i=i+1) begin
	//		tmp_mem[i] = line.getc(i);
	//		$display("%c,%x",tmp_mem[i],tmp_mem[i]);
	//	end
	//	$fclose(fd);
	//end

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  parser my_parser(.*);


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
	`FAIL_UNLESS_EQUAL(my_parser.wr_cnt,0);
	`FAIL_UNLESS_EQUAL(my_parser.rd_cnt,0);
  `SVTEST_END

  //`SVTEST(test_simple)
	//step(1); nextSamplePoint(); 
	//avl_st_rx_valid = 1; avl_st_rx_sop = 1; avl_st_rx_eop = 0; avl_st_rx_empty = 0;
	////$display("%x",tmp_mem[rd_cnt]);
	//res_tag_tmp = 0; res_tag = 0; res_value = 0;
	//while(1) begin
	//	avl_st_rx_data = {tmp_mem[rd_cnt],avl_st_rx_data[63:8]};
	//	//if(tmp_mem[rd_cnt]==8'h20) break;
	//	if(tmp_mem[rd_cnt]==8'h20 || rd_cnt%8==7) break;
	//	res_value = {res_value[119:0],tmp_mem[rd_cnt]};
	//	if(tmp_mem[rd_cnt]==8'h3d) begin 
	//		res_value = 0;
	//		res_tag = res_tag_tmp;
	//	end
	//	res_tag_tmp = {res_tag_tmp[23:0],tmp_mem[rd_cnt]};
	//	rd_cnt=rd_cnt+1;
	//end
	//while(1) begin
	//	if(rd_cnt%8==7) begin avl_st_rx_eop = 1; break; end
	//	avl_st_rx_empty = avl_st_rx_empty+1;
	//	avl_st_rx_data = {8'h00,avl_st_rx_data[63:8]};
	//	rd_cnt=rd_cnt+1;
	//end
	//step(1); nextSamplePoint(); 
	//if(avl_st_rx_eop) begin
	//	avl_st_rx_valid = 0; avl_st_rx_eop = 0; 
	//end
	//while(out1_valid!=1) step(1);
	//`FAIL_UNLESS_EQUAL(out1_valid,1);
	//`FAIL_UNLESS_EQUAL(out1_tag,res_tag);
	//`FAIL_UNLESS_EQUAL(out1_value,res_value);
  //`SVTEST_END
	
  `SVTEST(test_8_bit_tag)
	// initial test data
	//while(eq_pos<1) eq_pos = $random%4; 
	while(eq_pos<1) eq_pos = 1; 
	while(sp_pos<1) sp_pos = $random%16; 
	res_tag = 0; res_value = 0; rd_cnt=0;
	for(i=0;i<eq_pos;i=i+1) begin
		tmp8=$random;
		while(tmp8==8'h3d || tmp8==8'h20) tmp8=$random;
		res_tag={res_tag[23:0],tmp8};
		wdata={tmp8,wdata[32*8-1:8]};
	end
  //res_tag=res_tag>>(4-eq_pos)*8; wdata={8'h3d,wdata[32*8-1:8]};
  wdata={8'h3d,wdata[32*8-1:8]};
	for(i=0;i<sp_pos;i=i+1) begin
		tmp8=$random;
		while(tmp8==8'h3d || tmp8==8'h20) tmp8=$random;
		//res_value={tmp8,res_value[127:8]};
		res_value={res_value[119:0],tmp8};
		wdata={tmp8,wdata[32*8-1:8]};
	end
	//res_value=res_value>>(16-sp_pos)*8; wdata={8'h20,wdata[32*8-1:8]}; wdata = wdata >> (30-sp_pos-eq_pos)*8;
	wdata={8'h20,wdata[32*8-1:8]}; wdata = wdata >> (30-sp_pos-eq_pos)*8;

	// setup first write 
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 1;  
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	if(rd_cnt > sp_pos+eq_pos+2) begin
		avl_st_rx_eop = 1; avl_st_rx_empty = rd_cnt-sp_pos-eq_pos-2;
	end
	// setup first write 
	while(rd_cnt < sp_pos+eq_pos+2) begin
		step(1); nextSamplePoint(); 
		avl_st_rx_valid = 1; avl_st_rx_sop = 0;  
		avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
		if(rd_cnt > sp_pos+eq_pos) begin
			avl_st_rx_eop = 1; avl_st_rx_empty = rd_cnt-sp_pos-eq_pos;
		end
	end
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	while(out1_valid!=1) step(1);
	`FAIL_UNLESS_EQUAL(out1_valid,1);
	`FAIL_UNLESS_EQUAL(out1_tag,res_tag);
	`FAIL_UNLESS_EQUAL(out1_value,res_value);
  `SVTEST_END

  `SVTEST(test_16_bit_tag)
	// initial test data
	//while(eq_pos<1) eq_pos = $random%4; 
	while(eq_pos<1) eq_pos = 2; 
	while(sp_pos<1) sp_pos = $random%16; 
	res_tag = 0; res_value = 0; rd_cnt=0;
	for(i=0;i<eq_pos;i=i+1) begin
		tmp8=$random;
		while(tmp8==8'h3d || tmp8==8'h20) tmp8=$random;
		res_tag={res_tag[23:0],tmp8};
		wdata={tmp8,wdata[32*8-1:8]};
	end
  //res_tag=res_tag>>(4-eq_pos)*8; wdata={8'h3d,wdata[32*8-1:8]};
  wdata={8'h3d,wdata[32*8-1:8]};
	for(i=0;i<sp_pos;i=i+1) begin
		tmp8=$random;
		while(tmp8==8'h3d || tmp8==8'h20) tmp8=$random;
		//res_value={tmp8,res_value[127:8]};
		res_value={res_value[119:0],tmp8};
		wdata={tmp8,wdata[32*8-1:8]};
	end
	//res_value=res_value>>(16-sp_pos)*8; wdata={8'h20,wdata[32*8-1:8]}; wdata = wdata >> (30-sp_pos-eq_pos)*8;
	wdata={8'h20,wdata[32*8-1:8]}; wdata = wdata >> (30-sp_pos-eq_pos)*8;

	// setup first write 
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 1;  
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	if(rd_cnt > sp_pos+eq_pos+2) begin
		avl_st_rx_eop = 1; avl_st_rx_empty = rd_cnt-sp_pos-eq_pos-2;
	end
	// setup first write 
	while(rd_cnt < sp_pos+eq_pos+2) begin
		step(1); nextSamplePoint(); 
		avl_st_rx_valid = 1; avl_st_rx_sop = 0;  
		avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
		if(rd_cnt > sp_pos+eq_pos) begin
			avl_st_rx_eop = 1; avl_st_rx_empty = rd_cnt-sp_pos-eq_pos;
		end
	end
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	while(out1_valid!=1) step(1);
	`FAIL_UNLESS_EQUAL(out1_valid,1);
	`FAIL_UNLESS_EQUAL(out1_tag,res_tag);
	`FAIL_UNLESS_EQUAL(out1_value,res_value);
  `SVTEST_END


  `SVTEST(test_24_bit_tag)
	// initial test data
	//while(eq_pos<1) eq_pos = $random%4; 
	while(eq_pos<1) eq_pos = 3; 
	while(sp_pos<1) sp_pos = $random%16; 
	res_tag = 0; res_value = 0; rd_cnt=0;
	for(i=0;i<eq_pos;i=i+1) begin
		tmp8=$random;
		while(tmp8==8'h3d || tmp8==8'h20) tmp8=$random;
		res_tag={res_tag[23:0],tmp8};
		wdata={tmp8,wdata[32*8-1:8]};
	end
  //res_tag=res_tag>>(4-eq_pos)*8; wdata={8'h3d,wdata[32*8-1:8]};
  wdata={8'h3d,wdata[32*8-1:8]};
	for(i=0;i<sp_pos;i=i+1) begin
		tmp8=$random;
		while(tmp8==8'h3d || tmp8==8'h20) tmp8=$random;
		//res_value={tmp8,res_value[127:8]};
		res_value={res_value[119:0],tmp8};
		wdata={tmp8,wdata[32*8-1:8]};
	end
	//res_value=res_value>>(16-sp_pos)*8; wdata={8'h20,wdata[32*8-1:8]}; wdata = wdata >> (30-sp_pos-eq_pos)*8;
	wdata={8'h20,wdata[32*8-1:8]}; wdata = wdata >> (30-sp_pos-eq_pos)*8;

	// setup first write 
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 1;  
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	if(rd_cnt > sp_pos+eq_pos+2) begin
		avl_st_rx_eop = 1; avl_st_rx_empty = rd_cnt-sp_pos-eq_pos-2;
	end
	// setup first write 
	while(rd_cnt < sp_pos+eq_pos+2) begin
		step(1); nextSamplePoint(); 
		avl_st_rx_valid = 1; avl_st_rx_sop = 0;  
		avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
		if(rd_cnt > sp_pos+eq_pos) begin
			avl_st_rx_eop = 1; avl_st_rx_empty = rd_cnt-sp_pos-eq_pos;
		end
	end
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	while(out1_valid!=1) step(1);
	`FAIL_UNLESS_EQUAL(out1_valid,1);
	`FAIL_UNLESS_EQUAL(out1_tag,res_tag);
	`FAIL_UNLESS_EQUAL(out1_value,res_value);
  `SVTEST_END

  `SVTEST(test_32_bit_tag)
	// initial test data
	//while(eq_pos<1) eq_pos = $random%4; 
	while(eq_pos<1) eq_pos = 4; 
	while(sp_pos<1) sp_pos = $random%16; 
	res_tag = 0; res_value = 0; rd_cnt=0;
	for(i=0;i<eq_pos;i=i+1) begin
		tmp8=$random;
		while(tmp8==8'h3d || tmp8==8'h20) tmp8=$random;
		res_tag={res_tag[23:0],tmp8};
		wdata={tmp8,wdata[32*8-1:8]};
	end
  //res_tag=res_tag>>(4-eq_pos)*8; wdata={8'h3d,wdata[32*8-1:8]};
  wdata={8'h3d,wdata[32*8-1:8]};
	for(i=0;i<sp_pos;i=i+1) begin
		tmp8=$random;
		while(tmp8==8'h3d || tmp8==8'h20) tmp8=$random;
		//res_value={tmp8,res_value[127:8]};
		res_value={res_value[119:0],tmp8};
		wdata={tmp8,wdata[32*8-1:8]};
	end
	//res_value=res_value>>(16-sp_pos)*8; wdata={8'h20,wdata[32*8-1:8]}; wdata = wdata >> (30-sp_pos-eq_pos)*8;
	wdata={8'h20,wdata[32*8-1:8]}; wdata = wdata >> (30-sp_pos-eq_pos)*8;

	// setup first write 
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 1; avl_st_rx_sop = 1;  
	avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
	if(rd_cnt > sp_pos+eq_pos+2) begin
		avl_st_rx_eop = 1; avl_st_rx_empty = rd_cnt-sp_pos-eq_pos-2;
	end
	// setup first write 
	while(rd_cnt < sp_pos+eq_pos+2) begin
		step(1); nextSamplePoint(); 
		avl_st_rx_valid = 1; avl_st_rx_sop = 0;  
		avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
		if(rd_cnt > sp_pos+eq_pos) begin
			avl_st_rx_eop = 1; avl_st_rx_empty = rd_cnt-sp_pos-eq_pos;
		end
	end
	step(1); nextSamplePoint(); 
	avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
	while(out1_valid!=1) step(1);
	`FAIL_UNLESS_EQUAL(out1_valid,1);
	`FAIL_UNLESS_EQUAL(out1_tag,res_tag);
	`FAIL_UNLESS_EQUAL(out1_value,res_value);
  `SVTEST_END

  `SVTEST(test_ramdon_200)
	// initial test data
	for(j=0;j<200;j=j+1) begin
		while(eq_pos<1) eq_pos = $random%5; 
		while(sp_pos<1) sp_pos = $random%17; 
		res_tag = 0; res_value = 0; rd_cnt=0;
		for(i=0;i<eq_pos;i=i+1) begin
			tmp8=$random;
			while(tmp8==8'h3d || tmp8==8'h20) tmp8=$random;
			res_tag={res_tag[23:0],tmp8};
			wdata={tmp8,wdata[32*8-1:8]};
		end
  	//res_tag=res_tag>>(4-eq_pos)*8; wdata={8'h3d,wdata[32*8-1:8]};
  	wdata={8'h3d,wdata[32*8-1:8]};
		for(i=0;i<sp_pos;i=i+1) begin
			tmp8=$random;
			while(tmp8==8'h3d || tmp8==8'h20) tmp8=$random;
			//res_value={tmp8,res_value[127:8]};
			res_value={res_value[119:0],tmp8};
			wdata={tmp8,wdata[32*8-1:8]};
		end
		//res_value=res_value>>(16-sp_pos)*8; wdata={8'h20,wdata[32*8-1:8]}; wdata = wdata >> (30-sp_pos-eq_pos)*8;
		wdata={8'h20,wdata[32*8-1:8]}; wdata = wdata >> (30-sp_pos-eq_pos)*8;

		// setup first write 
		step(1); nextSamplePoint(); 
		avl_st_rx_valid = 1; avl_st_rx_sop = 1;  
		avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
		if(rd_cnt > sp_pos+eq_pos+2) begin
			avl_st_rx_eop = 1; avl_st_rx_empty = rd_cnt-sp_pos-eq_pos-2;
		end
		// setup first write 
		while(rd_cnt < sp_pos+eq_pos+2) begin
			step(1); nextSamplePoint(); 
			avl_st_rx_valid = 1; avl_st_rx_sop = 0;  
			avl_st_rx_data = wdata[63:0]; wdata = wdata >> 64; rd_cnt = rd_cnt + 8;
			if(rd_cnt > sp_pos+eq_pos) begin
				avl_st_rx_eop = 1; avl_st_rx_empty = rd_cnt-sp_pos-eq_pos;
			end
		end
		step(1); nextSamplePoint(); 
		avl_st_rx_valid = 0; avl_st_rx_sop = 0;  avl_st_rx_eop = 0; 
		while(out1_valid!=1) step(1);
		`FAIL_UNLESS_EQUAL(out1_valid,1);
		`FAIL_UNLESS_EQUAL(out1_tag,res_tag);
		`FAIL_UNLESS_EQUAL(out1_value,res_value);
		step(1);
	end
  `SVTEST_END

  `SVUNIT_TESTS_END

//	initial begin
//		$monitor("%d, %b, %x, %x, %x, %x,%d,%d",$stime,clk, res_tag, res_value, wdata,tmp8,eq_pos,sp_pos);
//		//$monitor("%d, %b, %b, %b, %x, %b, %b, %d, %b, %x, %x, %b,%x,%x,%d,%d,%d,%d,%d,%x,%x,%d,%d,%d",$stime,my_parser.clk, my_parser.rst, my_parser.avl_st_rx_valid,my_parser.avl_st_rx_data,my_parser.avl_st_rx_sop,my_parser.avl_st_rx_eop,my_parser.avl_st_rx_empty,my_parser.out1_valid,my_parser.out1_tag,my_parser.out1_value,my_parser.out2_valid,my_parser.out2_tag,my_parser.out2_value, rd_cnt,my_parser.state,my_parser.op_cnt,my_parser.rd_cnt,my_parser.fifo_rdata,res_tag,my_parser.flg_data,rd_cnt,eq_pos,sp_pos);
//		//$monitor("%d, %b, %b, %b, %b",$stime,clk, rst, en,wr);
//		$dumpfile("parser.vcd");
//		$dumpvars(0,parser_unit_test.my_parser);
//		$dumpvars;
//	end

endmodule
