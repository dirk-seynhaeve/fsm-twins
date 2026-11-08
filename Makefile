# SPDX-License-Identifier: Apache-2.0
#
# Simulate fsm-twins with Questa (vlib/vcom/vlog/vsim on PATH).
#
#   make            compile and run twins_test (directed tour, then random traffic)
#   make tour       run twins_tour_test (the directed tour alone)
#   make SEED=42    pick the seed; SEED=random for a new one each run
#   make clean
#
# The testbench needs no constrained randomization and no covergroups, so it also runs on the
# free starter editions of simulators that leave those out.

TEST  ?= twins_test
SEED  ?= 1
WORK  := sim/work

VHDL  := rtl/ctrl_fsm.vhd
SV    := rtl/ctrl_fsm.sv rtl/fsm_twins_top.sv tb/twins_if.sv tb/uvm/twins_uvm_pkg.sv tb/tb_top.sv

.PHONY: all run tour compile clean

all: run

compile: sim/.compiled

sim/.compiled: $(VHDL) $(SV) $(wildcard tb/uvm/*.svh)
	@mkdir -p sim
	cd sim && vlib work
	cd sim && vcom -quiet -2008 $(addprefix ../,$(VHDL))
	cd sim && vlog -quiet -sv +incdir+../tb/uvm $(addprefix ../,$(SV))
	@touch $@

run: compile
	cd sim && vsim -c -quiet -sv_seed $(SEED) tb_top +UVM_TESTNAME=$(TEST) \
	  -do "run -all; quit -f" | tee $(TEST).log
	@grep -q "UVM_ERROR :    0" sim/$(TEST).log && grep -q "UVM_FATAL :    0" sim/$(TEST).log \
	  && echo "PASS: $(TEST)" || (echo "FAIL: $(TEST)"; exit 1)

tour:
	$(MAKE) run TEST=twins_tour_test

clean:
	rm -rf sim
