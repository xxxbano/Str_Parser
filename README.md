# Str_Parser
Input a string, the parser based on '=',ascii'0x3d' and ' '(Space), ascii'0x20' output out_tag = left_side, out_value = right_side.
###### example
- Input:8=TXS.1 9=fsaft 
- Ouput1: out_tag:8, out_value:TXS.1; 
- output2: out_tag:9,out_value:fsaft
##### Verilog files:
- [parser_op_dual.v](rtl/parser_op_dual.v): Version 3 based on Version 2. dual channel mode. Low latency.
- [parser_op.v](rtl/parser_op.v): Version 2. 64-bit write in, 64-bit read out. Low latency.
- [parser.v](rtl/parser.v): Version 1. 64-bit write in, 8-bit read out.
- [fifo.v](rtl/fifo.v): first word fall through mode. Used in Version 2 and 3.
##### UnitTest files:
Method: Randomly generate out_tag and out_value, and concatenate them to form a string package by following the parsing rules. Then, input the string package to the target parser. At last, verify the output with the generated result.
- [parser_unit_test.sv](testbench/parser_unit_test.sv): 
  - Test1:1-Byte tag, random value (1~16-Byte). 
  - Test2:2-Byte tag, random value (1~16-Byte), 
  - Test3:3-Byte tag, random value (1~16-Byte),
  - Test4:4-Byte tag, random value (1~16-Byte), 
  - Test5: random tag (1-4-Byte), random value (1-16-Byte), 200 times
- [parser_op_unit_test.sv](testbench/parser_op_unit_test.sv): 
  - Test1:1-Byte tag, random value (1~16-Byte). 
  - Test2:2-Byte tag, random value (1~16-Byte), 
  - Test3:3-Byte tag, random value (1~16-Byte),
  - Test4:4-Byte tag, random value (1~16-Byte), 
  - Test5: random tag (1-4-Byte), random value (1-16-Byte), 200 times
- [parser_op_dual_unit_test.sv](testbench/parser_op_dual_unit_test.sv): 
  - Test1: random tag (1-4-Byte), random value (1-16-Byte), 200 times
- [TestResult](testbench/TestResult): Test Summary
##### ToDo:
- 

#### Waveform from UnitTest
##### parser_op_dual: Version 3
Input Hex: 000000000000208F 1277E5AAC5C6F98C ED760D013D12658D; '='='3D',' '='20' => out_tag=12658D,out_value=0000208F 1277E5AAC5C6F98C ED760D01
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig2.png "Logo Title Text 1")
Dual channel interleaving output
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig1.png "Logo Title Text 1")
200 times rondom data test
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig3.png "Logo Title Text 1")

##### parser_op: Version 2
1-byte tag test
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig4.png "Logo Title Text 1")
2-byte tag test
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig5.png "Logo Title Text 1")
3-byte tag test
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig6.png "Logo Title Text 1")
4-byte tag test
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig7.png "Logo Title Text 1")
Random test. 1~4-byte tag, 1~16-byte value
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig8.png "Logo Title Text 1")

##### parser: Version 1
1-byte tag test
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig9.png "Logo Title Text 1")
2-byte tag test
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig10.png "Logo Title Text 1")
3-byte tag test
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig11.png "Logo Title Text 1")
4-byte tag test
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig12.png "Logo Title Text 1")
Random test. 1~4-byte tag, 1~16-byte value
![alt text](https://github.com/xxxbano/Str_Parser/blob/master/doc/fig13.png "Logo Title Text 1")

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

