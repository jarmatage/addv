LOG_LEVEL ?= 2

# Common compile flags
COMP_FLAGS = \
	-full64 \
	-sverilog \
	-kdb \
	-ntb_opts uvm \
	-debug_access+all \
    -timescale=1ns/1ps \
	+plusarg_save \
	+define+DUMP=1 \
	+log_level=$(LOG_LEVEL) \
	+incdir+../tb

# Source files
SRC_RTL  = ../src/*.sv
SRC_PKG  = ../tb/fifo_uvm_pkg.sv
TB_TOP   = ../tb/tb_async_fifo_uvm.sv

all: sim verdi

compile: clean
	@echo "=== Compiling ==="
	${VCS_HOME}/bin/vcs $(COMP_FLAGS) \
		$(SRC_RTL) \
		$(SRC_PKG) \
		$(TB_TOP) \
	-l compile.log

sim: compile
	@echo "=== Running simulation ==="
	./simv |& tee sim.log

compile_bug: clean
	@echo "=== Compiling (BUGGED) ==="
	${VCS_HOME}/bin/vcs $(COMP_FLAGS) +define+BUGGED \
		$(SRC_RTL) \
		$(SRC_PKG) \
		$(TB_TOP) \
	-l compile_bug.log

sim_bug: compile_bug
	@echo "=== Running simulation (BUGGED) ==="
	./simv |& tee sim_bug.log

verdi:
	@echo "=== Launching Verdi ==="
	${VERDI_HOME}/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -nologo &

clean:
	rm -rf simv csrc simv.daidir *.fsdb novas* *.key *.log verdi*

.PHONY: all clean compile compile_bug sim sim_bug verdi
