module __testsuite;
  import svunit_pkg::svunit_testsuite;

  string name = "__ts";
  svunit_testsuite svunit_ts;
  
  
  //===================================
  // These are the unit tests that we
  // want included in this testsuite
  //===================================
  parser_op_dual_unit_test parser_op_dual_ut();
  parser_op_unit_test parser_op_ut();


  //===================================
  // Build
  //===================================
  function void build();
    parser_op_dual_ut.build();
    parser_op_ut.build();
    svunit_ts = new(name);
    svunit_ts.add_testcase(parser_op_dual_ut.svunit_ut);
    svunit_ts.add_testcase(parser_op_ut.svunit_ut);
  endfunction


  //===================================
  // Run
  //===================================
  task run();
    svunit_ts.run();
    parser_op_dual_ut.run();
    parser_op_ut.run();
    svunit_ts.report();
  endtask

endmodule
