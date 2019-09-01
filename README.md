# Str_Parser
Input is a string. The parser parse a group of data in a string which has an ascii'0x3d'=>'=', the output is, out_tag = left_side of "=", out_value = right_side of "=". The string might has many groups of data which are seperated by ascii'0x01' or '0x20'. 
###### example
let's say $ => ascii'0x01'. The string is terminated with a $.
- Input: string "8=TXS.1$9=fsaft$"
- 1st output: out_tag: 8, out_value: TXS.1
- 2nd output: out_tag: 9, out_value: fsaft
##### Verilog files:
- [parser.v](rtl/parser.v)
  - Version 1. 64-bit write in, 8-bit read out. 
  - Handle general string input. (e.g. "8=TXS.1$9=fsaft$fsda=ffteaf$78=fsaf")
- [parser_op.v](rtl/parser_op.v)
  - Version 2. 64-bit write in, 64-bit read out. 
  - Low latency. 
  - Handle general string input. (e.g. "8=TXS.1$9=fsaft$fsda=ffteaf$78=fsaf")
  - The input has a complex combinatin logic. Should be took care in a real project.
- [parser_op_dual.v](rtl/parser_op_dual.v): 
  - Version 3 based on Version 2. dual channel mode. 
  - Low latency. 
  - But, based on old Version 2. Cannot handle general string input yet. Only for 1 string 1 grp of data (e.g. "8=TXS.1$" "9=fsaft$" "fsda=ffteaf$") 
  - The dual channel mode idea can be applied on Version 1 and 2.
- [fifo.v](rtl/fifo.v): first word fall through mode. Used in Version 3.
##### UnitTest files:
Random Test Method: Randomly generate out_tag and out_value, and concatenate them to form a string package by following the parsing rules. Then, input the string package to the target parser. At last, verify the output with the generated result.
- [parser_unit_test.sv](testbench/parser_unit_test.sv): 
  - test_rst: reset test
  - test_2_continus_case_empty_0: Input 2 groups of data, the last 8-byte has 0-byte empty  
  - test_2_continus_case_empty_1: Input 2 groups of data, the last 8-byte has 1-byte empty 
  - test_2_continus_case_empty_3: Input 2 groups of data, the last 8-byte has 3-byte empty
  - test_2_continus_case_ignore_1st_for_5B_tag: Input 2 grps of dat, 1st grp dat has 5-byte tag, ignore 1st grp dat.
  - test_2_continus_case_ignore_2nd_for_5B_tag: Input 2 grps of dat, 2nd grp dat has 5-byte tag, ignore 2nd grp dat.
  - test_2_continus_case_1st_ignore_17B_value: Input 2 grps of dat, 1st grp dat has 17-byte val, ignore byte [16~]
  - test_2_continus_case_2nd_ignore_17B_value: Input 2 grps of dat, 2nd grp dat has 17-byte val, ignore byte [16~]
  - test_random_200: Input 1 groups of data, random tag (1-4-Byte), random value (1-16-Byte), 200 times
- [parser_op_unit_test.sv](testbench/parser_op_unit_test.sv): 
  - test_rst: reset test
  - test_2_continus_case_empty_0: Input 2 groups of data, the last 8-byte has 0-byte empty  
  - test_2_continus_case_empty_1: Input 2 groups of data, the last 8-byte has 1-byte empty 
  - test_2_continus_case_empty_3: Input 2 groups of data, the last 8-byte has 3-byte empty
  - test_2_continus_case_ignore_1st_for_5B_tag: Input 2 grps of dat, 1st grp dat has 5-byte tag, ignore 1st grp dat.
  - test_2_continus_case_ignore_2nd_for_5B_tag: Input 2 grps of dat, 2nd grp dat has 5-byte tag, ignore 2nd grp dat.
  - test_2_continus_case_1st_ignore_17B_value: Input 2 grps of dat, 1st grp dat has 17-byte val, ignore byte [16~]
  - test_2_continus_case_2nd_ignore_17B_value: Input 2 grps of dat, 2nd grp dat has 17-byte val, ignore byte [16~]
- [parser_op_dual_unit_test.sv](testbench/parser_op_dual_unit_test.sv): 
  - Test1: random tag (1-4-Byte), random value (1-16-Byte), 200 times
- [TestResult](testbench/TestResult): Test Summary
##### ToDo:
- Need to test more corner cases.
- Implement dual mode for Version 1 and 2.

#### Waveform from UnitTest
##### [parser_op.v](rtl/parser_op.v): Version 2
###### test_2_continus_case_empty_0. Fig 1: input data, Fig 2: 1st output, Fig 3: 2nd output
- Input: 01 456789abcdef1123456789abcdef 3d 1234 01 1123456789abcdef1123456789abcdef 3d 12345678
- 1st output: tag: 12345678 value: 1123456789abcdef1123456789abcdef
- 2nd output: tag: 00001234 value: 0001456789abcdef1123456789abcdef
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig31.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig32.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig33.png "Logo Title Text 1")
###### test_2_continus_case_empty_1. Fig 1: input data, Fig 2: 1st output, Fig 3: 2nd output
- Input: 01 456789abcdef1123456789abcdef 3d 1234 01 23456789abcdef1123456789abcdef 3d 12345678
- 1st output: tag: 12345678 value: 0123456789abcdef1123456789abcdef
- 2nd output: tag: 00001234 value: 0001456789abcdef1123456789abcdef
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig34.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig35.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig36.png "Logo Title Text 1")
###### test_2_continus_case_empty_3. Fig 1: input data, Fig 2: 1st output, Fig 3: 2nd output
- Input: 01 89abcdef1123456789abcdef 3d 1234 01 23456789abcdef1123456789abcdef 3d 12345678;
- 1st output: tag: 12345678 value: 0123456789abcdef1123456789abcdef
- 2nd output: tag: 00001234 value: 0000000189abcdef1123456789abcdef
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig37.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig38.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig39.png "Logo Title Text 1")
###### test_2_continus_case_ignore_1st_for_5B_tag. Fig 1: input data, Fig 2: 1st output, Fig 3: 2nd output
- Input: 01 456789abcdef2123456789abcdef 3d 1234 01 23456789abcdef2123456789abcd 3d ef12345678;;
- 1st output: ignored
- 2nd output: tag: 00001234 value: 0001456789abcdef1123456789abcdef
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig40.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig41.png "Logo Title Text 1")
###### test_2_continus_case_ignore_2nd_for_5B_tag. Fig 1: input data, Fig 2: 1st output, Fig 3: 2nd output
- Input: 01 456789abcdef1123456789abcd 3d ef12345678 01 23456789abcdef1123456789abcdef 3d 1234;
- 1st output: tag: 00001234 value: 0123456789abcdef1123456789abcdef
- 2nd output: ignored
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig42.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig43.png "Logo Title Text 1")
###### test_2_continus_case_1st_ignore_17B_value. Fig 1: input data, Fig 2: 1st output, Fig 3: 2nd output
- Input: 01 23456789abcdef1123456789abcdef 3d 1234 01 ff1123456789abcdef1123456789abcdef 3d 12345678;
- 1st output: tag: 12345678 value: 1123456789abcdef1123456789abcdef, ignored 'ff'
- 2nd output: tag: 00001234 value: 0123456789abcdef1123456789abcdef
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig44.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig45.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig46.png "Logo Title Text 1")
###### test_2_continus_case_2nd_ignore_17B_value. Fig 1: input data, Fig 2: 1st output, Fig 3: 2nd output
- Input: 01 ff1123456789abcdef1123456789abcdef 3d 1234 01 23456789abcdef1123456789abcdef 3d 12345678;;
- 1st output: tag: 12345678 value: 0123456789abcdef1123456789abcdef
- 2nd output: tag: 00001234 value: 1123456789abcdef1123456789abcdef, ignored 'ff'
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig47.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig48.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig49.png "Logo Title Text 1")

##### [parser.v](rtl/parser.v): Version 1
###### test_2_continus_case_empty_0. Fig 1: input data, Fig 2: 1st output, Fig 3: 2nd output
- Input: 01 456789abcdef1123456789abcdef 3d 1234 01 1123456789abcdef1123456789abcdef 3d 12345678
- 1st output: tag: 12345678 value: 1123456789abcdef1123456789abcdef
- 2nd output: tag: 00001234 value: 0000456789abcdef1123456789abcdef
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig9.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig10.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig11.png "Logo Title Text 1")
###### test_2_continus_case_empty_1. Fig 1: input data, Fig 2: 1st output, Fig 3: 2nd output
- Input: 01 456789abcdef1123456789abcdef 3d 1234 01 23456789abcdef1123456789abcdef 3d 12345678
- 1st output: tag: 12345678 value: 0023456789abcdef1123456789abcdef
- 2nd output: tag: 00001234 value: 0000456789abcdef1123456789abcdef
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig12.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig13.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig14.png "Logo Title Text 1")
###### test_2_continus_case_empty_3. Fig 1: input data, Fig 2: 1st output, Fig 3: 2nd output
- Input: 01 89abcdef1123456789abcdef 3d 1234 01 23456789abcdef1123456789abcdef 3d 12345678;
- 1st output: tag: 12345678 value: 0023456789abcdef1123456789abcdef
- 2nd output: tag: 00001234 value: 0000000089abcdef1123456789abcdef
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig15.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig16.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig17.png "Logo Title Text 1")
###### test_2_continus_case_ignore_1st_for_5B_tag. Fig 1: input data, Fig 2: 1st output, Fig 3: 2nd output
- Input: 01 456789abcdef2123456789abcdef 3d 1234 01 23456789abcdef2123456789abcd 3d ef12345678;;
- 1st output: ignored
- 2nd output: tag: 00001234 value: 0000456789abcdef1123456789abcdef
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig18.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig19.png "Logo Title Text 1")
###### test_2_continus_case_ignore_2nd_for_5B_tag. Fig 1: input data, Fig 2: 1st output, Fig 3: 2nd output
- Input: 01 456789abcdef1123456789abcd 3d ef12345678 01 23456789abcdef1123456789abcdef 3d 1234;
- 1st output: tag: 00001234 value: 0023456789abcdef1123456789abcdef
- 2nd output: ignored
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig20.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig21.png "Logo Title Text 1")
###### test_2_continus_case_1st_ignore_17B_value. Fig 1: input data, Fig 2: 1st output, Fig 3: 2nd output
- Input: 01 23456789abcdef1123456789abcdef 3d 1234 01 ff1123456789abcdef1123456789abcdef 3d 12345678;
- 1st output: tag: 12345678 value: 1123456789abcdef1123456789abcdef, ignored 'ff'
- 2nd output: tag: 00001234 value: 0023456789abcdef1123456789abcdef
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig22.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig23.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig24.png "Logo Title Text 1")
###### test_2_continus_case_2nd_ignore_17B_value. Fig 1: input data, Fig 2: 1st output, Fig 3: 2nd output
- Input: 01 ff1123456789abcdef1123456789abcdef 3d 1234 01 23456789abcdef1123456789abcdef 3d 12345678;;
- 1st output: tag: 12345678 value: 0023456789abcdef1123456789abcdef
- 2nd output: tag: 00001234 value: 1123456789abcdef1123456789abcdef, ignored 'ff'
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig25.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig26.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig27.png "Logo Title Text 1")
###### Random test. Fig 1: input data, Fig 2: 1st output,
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig28.png "Logo Title Text 1")
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig29.png "Logo Title Text 1")
###### Random test. 1-4-byte tag, 1-16-byte value
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig30.png "Logo Title Text 1")

##### parser_op_dual: Version 3
Input Hex: 000000000000208F 1277E5AAC5C6F98C ED760D013D12658D; '='='3D',' '='20' => out_tag=12658D,out_value=0000208F 1277E5AAC5C6F98C ED760D01
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig2.png "Logo Title Text 1")
###### Dual channel interleaving output
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig1.png "Logo Title Text 1")
###### 200 times rondom data test
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig3.png "Logo Title Text 1")

#### About UnitTest
The UnitTest is designed by using SVUnit in Linux

##### Setup SVUnit:
1. Download: http://agilesoc.com/open-source-projects/svunit/
2. mv svunit-code to a directory
3. setenv SVUNIT_INSTALL /directory/svunit-code 
4. add path /direcotry svunit-code/bin 
5. cd testbench; ln -s ../rtl/*.v; if no files in testbench folder 
6. run testbench: ./runUtest.csh 

If you do not have modelsim, setup vcs etc.(has limitation) in runUtest.csh file
runSVunit -s (simulator)

