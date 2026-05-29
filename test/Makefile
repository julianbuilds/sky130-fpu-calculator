# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more details

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

SRC_DIR = $(PWD)/../src

# VERILOG_SOURCES includes all the source files required for simulation
VERILOG_SOURCES += $(SRC_DIR)/project.v
VERILOG_SOURCES += $(SRC_DIR)/chip_top.v
VERILOG_SOURCES += $(SRC_DIR)/fp_calculator_top.v
VERILOG_SOURCES += $(SRC_DIR)/uart_controller.v
VERILOG_SOURCES += $(SRC_DIR)/uart_tx.v
VERILOG_SOURCES += $(SRC_DIR)/uart_rx.v
VERILOG_SOURCES += $(SRC_DIR)/fp16_synthesized.v

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = tt_um_digital_asic_fp_calculator

# MODULE is the basename of the Python test file
MODULE = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim