
SIM ?= icarus
PYTHON_BIN = python
FST ?= -fst
TOPLEVEL_LANG ?= verilog

SRC_DIR = ../src
SIM_SRAM = $(PWD)/gf180_sram_sim.v

PROJECT_SOURCES = tt_um_godofstrategy_arm32.v \
                  core.v \
                  decoder.v \
                  register_file.v \
                  alu.v \
                  barrel_shifter.v \
                  memory_controller.v \
                  spi_debug_slave.v

ifneq ($(GATES),yes)

# RTL simulation
SIM_BUILD = sim_build/rtl

VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
VERILOG_SOURCES += $(SIM_SRAM)
VERILOG_SOURCES += $(PWD)/tb.v

COMPILE_ARGS += -DSIMULATION

TOPLEVEL = tb
COCOTB_TEST_MODULES = test

else

# Gate level simulation
SIM_BUILD = sim_build/gl

COMPILE_ARGS += -DGL_TEST
COMPILE_ARGS += -DFUNCTIONAL
COMPILE_ARGS += -DUSE_POWER_PINS
COMPILE_ARGS += -DSIM
COMPILE_ARGS += -DUNIT_DELAY=\#1

VERILOG_SOURCES += $(PDK_ROOT)/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/gf180mcu_fd_sc_mcu7t5v0.v

# SRAM model
VERILOG_SOURCES += $(SIM_SRAM)

VERILOG_SOURCES += $(PWD)/gate_level_netlist.v
VERILOG_SOURCES += $(PWD)/tb.v

TOPLEVEL = tb
COCOTB_TEST_MODULES = test

endif

COMPILE_ARGS += -I$(SRC_DIR)

include $(shell cocotb-config --makefiles)/Makefile.sim
