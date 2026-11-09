// fsm-twins: the design and its UVM testbench, in compile order.
// The VHDL twin is analyzed first (VHDL-2008); everything else is SystemVerilog.
// Needs UVM 1.2 or IEEE 1800.2 from your simulator.
// No file sets a `timescale: give the time unit on the command line, 1ns/1ps (Questa:
// vlog -timescale 1ns/1ps; Vivado XSIM: xelab --timescale 1ns/1ps).

+incdir+tb/uvm

rtl/ctrl_fsm.vhd
rtl/ctrl_fsm.sv
rtl/fsm_twins_top.sv

tb/twins_if.sv
tb/uvm/twins_uvm_pkg.sv
tb/tb_top.sv
