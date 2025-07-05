#!/bin/bash
# Makefile for Xilinx Vivado xsim simulation

# Vivado設定
VIVADO_PATH = /opt/Xilinx/2025.1/Vivado
SHELL = /bin/bash

# シミュレーションのトップモジュール
TOP_MODULE = tb_kairo_soc

# RTLソースファイル
RTL_SOURCES = \
	../rtl/core/kairo.sv \
	../rtl/core/kairo_reg.sv \
	../rtl/core/kairo_mul.sv \
	../rtl/core/kairo_div.sv \
	../rtl/core/kairo_csr.sv \
	../rtl/core/kairo_alu.sv \
	../rtl/core/kairo_decode.sv \
	../rtl/soc/kairo_soc.sv \
	../rtl/soc/kairo_mif.sv \
	../rtl/soc/kairo_lct.sv \
	../rtl/soc/kairo_bussel.sv \
	../rtl/apb/apb_timer.sv \
	../rtl/apb/apb_plic.sv \
	../rtl/apb/apb_gpio.sv \
	../rtl/mem/mem_ram.sv \
	../rtl/rv_debug/rtl/debug_top.sv \
	../rtl/rv_debug/rtl/debug_dtm.sv \
	../rtl/rv_debug/rtl/debug_dm.sv \
	../rtl/rv_debug/rtl/debug_d2s.sv \
	../rtl/rv_debug/rtl/debug_core.sv \
	../rtl/tb/tb_kairo_soc.sv

# xsimの実行ファイル
XVLOG = xvlog
XELAB = xelab
XSIM = xsim

# シミュレーションのワークディレクトリ
WORK_DIR = xsim.dir

# デフォルトのターゲット
all: compile elaborate simulate

# コンパイル
compile:
	@echo "Setting up Vivado environment..."
	@source $(VIVADO_PATH)/settings64.sh && \
	echo "Compiling RTL sources..." && \
	$(XVLOG) -sv --relax $(RTL_SOURCES)

# エラボレーション
elaborate:
	@echo "Elaborating design..."
	@source $(VIVADO_PATH)/settings64.sh && \
	$(XELAB) -debug typical --relax -top $(TOP_MODULE) -snapshot $(TOP_MODULE)_snapshot

# シミュレーション実行（波形ファイル生成）
simulate:
	@echo "Running simulation..."
	@source $(VIVADO_PATH)/settings64.sh && \
	$(XSIM) $(TOP_MODULE)_snapshot -wdb $(TOP_MODULE).wdb -log $(TOP_MODULE).log -tclbatch run.tcl

# GUI付きシミュレーション
gui:
	@echo "Running simulation with GUI..."
	@source $(VIVADO_PATH)/settings64.sh && \
	$(XSIM) $(TOP_MODULE)_snapshot -gui -wdb $(TOP_MODULE).wdb

# TCLバッチファイル作成
run.tcl:
	@echo "Creating TCL batch file..."
	@echo "run all" > run.tcl
	@echo "quit" >> run.tcl

# WAVEの表示
wave:
	@echo "View wave with GUI..."
	@source $(VIVADO_PATH)/settings64.sh && \
	$(XSIM) -gui $(TOP_MODULE).wdb

# クリーンアップ
clean:
	@echo "Cleaning up..."
	rm -rf $(WORK_DIR) *.wdb *.log *.jou *.pb webtalk* run.tcl

# ヘルプ
help:
	@echo "Usage:"
	@echo "  make           - Compile, elaborate and run simulation"
	@echo "  make compile   - Compile RTL sources only"
	@echo "  make elaborate - Elaborate design only"
	@echo "  make simulate  - Run simulation only"
	@echo "  make gui       - Run simulation with GUI"
	@echo "  make wave      - View wave with GUI"
	@echo "  make clean     - Clean up generated files"
	@echo "  make help      - Show this help message"

.PHONY: all compile elaborate simulate gui clean help run.tcl