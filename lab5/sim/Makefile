LOG_LEVEL ?= 2
SEED ?= 0

all: sim verdi

compile: clean
	@echo "=== Compiling ==="
	mkdir seeds
	${VCS_HOME}/bin/vcs \
		-full64 \
		-sverilog \
		-kdb \
		-debug_access+all \
		-timescale=1ns/1ps \
		-ntb_opts uvm \
		-cm line+tgl+cond+fsm+branch+assert \
		-cm_dir seeds/simv_$(SEED).vdb \
		+plusarg_save \
		+define+DUMP=1 \
		+log_level=$(LOG_LEVEL) \
		+ntb_random_seed=$(SEED) \
		../src/*.sv \
		../tb/setup_uvm.sv \
		../tb/instruction.sv \
		../tb/instr_gen.sv \
		../tb/instr_monitor.sv \
		../tb/instr_coverage.sv \
		../tb/instr_env.sv \
		../tb/instr_test.sv \
		../tb/tb_mips.sv \
	-l compile.log

sim: compile
	@echo "=== Running simulation ==="
	./simv |& tee sim.log

verdi:
	@echo "=== Launching Verdi ==="
	${VERDI_HOME}/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -nologo &

cov:
	${VCS_HOME}/bin/urg -dir seeds/*.vdb -dbname merged.vdb
	${VERDI_HOME}/bin/verdi -cov -covdir merged.vdb &

clean:
	rm -rf simv csrc simv.daidir *.fsdb novas* *.key *.log verdi*

.PHONY: all clean compile cov sim verdi
