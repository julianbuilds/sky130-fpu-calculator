# Makefile
# See https://docs.tinytapeout.com for more details

# SIM can be icarus or verilator
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Añade todos tus archivos de diseño aquí (buscándolos desde la carpeta src)
VERILOG_SOURCES += $(PWD)/../src/project.v \
                   $(PWD)/../src/chip_top.v \
                   $(PWD)/../src/fp_calculator_top.v \
                   $(PWD)/../src/uart_controller.v \
                   $(PWD)/../src/uart_tx.v \
                   $(PWD)/../src/uart_rx.v \
                   $(PWD)/../src/flopoco_synthesized.v

# TOPLEVEL es el módulo principal de tu diseño según Tiny Tapeout
TOPLEVEL = tt_um_digital_asic_fp_calculator

# MODULE es el nombre del archivo de pruebas de Python (sin el .py)
MODULE = test

# Incluye la infraestructura de simulación de Cocotb
include $(shell cocotb-config --makefiles)/Makefile.sim