UVM_VERBOSITY ?= UVM_MEDIUM
SEED ?= 0
DB_TRACE ?= 0
PHASE_TRACE ?= 0
DWIDTH ?= 8
AWIDTH ?= 4
WCLK_T ?= 10
RCLK_T ?= 10

# Common compile flags
COMP_FLAGS := \
	-full64 \
	-sverilog \
	-kdb \
	-debug_access+all \
	-timescale=1ns/1ps \
	-ntb_opts uvm \
	-cm line+tgl+cond+fsm+branch+assert \
	-cm_dir seeds/simv_$(SEED).vdb \
	+ntb_random_seed=$(SEED) \
	+plusarg_save \
	+define+DUMP=1 \
	+UVM_OBJECTION_TRACE \
	+UVM_VERBOSITY=$(UVM_VERBOSITY) \
	+define+DWIDTH=$(DWIDTH) \
	+define+AWIDTH=$(AWIDTH) \
	+define+WCLK_T=$(WCLK_T) \
	+define+RCLK_T=$(RCLK_T) \
	+incdir+../tb

# Conditionally add trace flags
ifeq ($(DB_TRACE), 1)
	COMP_FLAGS += +UVM_CONFIG_DB_TRACE
endif
ifeq ($(PHASE_TRACE), 1)
	COMP_FLAGS += +UVM_PHASE_TRACE
endif

# Source files
SRC_RTL  = ../src/*.sv
SRC_PKG  = ../tb/fifo_uvm_pkg.sv
TB_TOP   = ../tb/tb_async_fifo_uvm.sv

all: sim verdi

compile: clean
	@echo "=== Compiling ==="
	@mkdir -p seeds
	${VCS_HOME}/bin/vcs $(COMP_FLAGS) \
		$(SRC_RTL) \
		$(SRC_PKG) \
		$(TB_TOP) \
	-l compile.log

sim: compile
	@echo "=== Running simulation ==="
	./simv -cm line+tgl+cond+fsm+branch+assert |& tee sim.log

compile_bug: clean
	@echo "=== Compiling (BUGGED) ==="
	@mkdir -p seeds
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

cov:
	@k=0; \
	@for i in 5 10 15 20; do \
		for j in 5 10 15 20; do \
			$(MAKE) sim SEED=$$k WCLK_T=$$i RCLK_T=$$j; \
			k=$$((k + 5)); \
		done \
	done
	${VCS_HOME}/bin/urg -dir seeds/*.vdb -dbname merged.vdb
	${VERDI_HOME}/bin/verdi -cov -covdir merged.vdb &

clean:
	rm -rf simv csrc simv.daidir *.fsdb novas* *.key *.log verdi*

.PHONY: all clean compile compile_bug cov sim sim_bug verdi
