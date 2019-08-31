#!/bin/sh -f

rm -rf verilog.trn verilog.dsn
rm -r INCA_libs

home_path=/fs1/eecg/roman/xia

project_path=$home_path/Develop/vlab/ncverilog_sample

verilog_path=$project_path/verilog
unittest_path=$project_path/unit-test

#runSVUnit -t sample.v -s modelsim    
runSVUnit -s modelsim -r -sdfnoerror   

