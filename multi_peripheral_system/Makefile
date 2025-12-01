# Caravel Multi-Peripheral System Makefile

PROJECT_ROOT = $(shell pwd)
VERILOG_RTL = $(PROJECT_ROOT)/verilog/rtl
IP_DIR = $(PROJECT_ROOT)/ip

# Verilator options
VERILATOR = verilator
VLINT_FLAGS = --lint-only --Wno-EOFNEWLINE --Wno-DECLFILENAME -Wno-PINCONNECTEMPTY -Wno-UNDRIVEN -Wno-PINMISSING -Wno-WIDTH -Wno-TIMESCALEMOD -Wno-UNUSED
VDEFINES = +define+USE_POWER_PINS +define+MPRJ_IO_PADS=38
VINCDIR = +incdir+$(VERILOG_RTL)

# IP search paths
VPATH = -y $(VERILOG_RTL) \
        -y $(IP_DIR)/CF_TMR32/hdl/rtl \
        -y $(IP_DIR)/CF_TMR32/hdl/rtl/bus_wrappers \
        -y $(IP_DIR)/CF_UART/hdl/rtl \
        -y $(IP_DIR)/CF_UART/hdl/rtl/bus_wrappers \
        -y $(IP_DIR)/CF_SPI/hdl/rtl \
        -y $(IP_DIR)/CF_SPI/hdl/rtl/bus_wrappers \
        -y $(IP_DIR)/CF_I2C/hdl/rtl \
        -y $(IP_DIR)/CF_I2C/hdl/rtl/bus_wrappers \
        -y $(IP_DIR)/CF_SRAM_1024x32/hdl \
        -y $(IP_DIR)/CF_SRAM_1024x32/hdl/bus_wrapper \
        -y $(IP_DIR)/CF_SRAM_1024x32/hdl/controllers \
        -y $(IP_DIR)/CF_IP_UTIL/hdl/rtl

# ADC stubs for linting (since ADC is a hard macro)
ADC_STUB_DIR = $(PROJECT_ROOT)/verilog/rtl/stubs

.PHONY: lint lint-wrapper lint-project lint-adc clean

lint: lint-wrapper lint-project
	@echo "All RTL linting complete!"

lint-wrapper:
	@echo "Linting user_project_wrapper.v..."
	$(VERILATOR) $(VLINT_FLAGS) $(VDEFINES) $(VINCDIR) $(VPATH) $(VERILOG_RTL)/user_project_wrapper.v

lint-project:
	@echo "Linting user_project.v..."
	$(VERILATOR) $(VLINT_FLAGS) $(VDEFINES) $(VINCDIR) $(VPATH) -y $(ADC_STUB_DIR) $(IP_DIR)/sky130_ef_ip__adc3v_12bit/verilog/sar_ctrl.v $(VERILOG_RTL)/user_project.v

lint-adc:
	@echo "Linting adc_wb_wrapper.v..."
	$(VERILATOR) $(VLINT_FLAGS) $(VDEFINES) $(VINCDIR) $(VPATH) $(VERILOG_RTL)/adc_wb_wrapper.v

clean:
	rm -rf obj_dir
	@echo "Cleaned build artifacts"
