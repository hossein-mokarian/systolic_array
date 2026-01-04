# Makefile
.PHONY: myall myrun myclean myview myhelp

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
WAVES ?= 1
# EXTRA_ARGS += --trace --trace-structs

VERILOG_SOURCES += $(PWD)/src/systolic_top.v

# COCOTB_TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
COCOTB_TOPLEVEL = SYSTOLIC_TOP

# COCOTB_TEST_MODULES is the basename of the Python test file(s)
COCOTB_TEST_MODULES = test_systolic

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

myclean:
	@echo "Additional Cleaning ..."
	rm -rf ./sim_build

myrun: myclean
	$(MAKE)

myview:
	@echo "Running gtkwave ..."
	gtkwave ./sim_build/SYSTOLIC_TOP.fst

myall: myclean myrun myview

myhelp:
	@echo "Available targets:"
	@echo "  make myall    - Clean, run simulation, and view waves"
	@echo "  make myrun    - Clean and run simulation"
	@echo "  make myclean  - Clean build files"
	@echo "  make myview   - View waveforms in gtkwave"
	@echo "  make myhelp     - Show this help"
	@echo ""
	@echo "  Alternative: you can use the defaults from cocotb. As simple as this:  make clean sim"
