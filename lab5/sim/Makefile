LOG_LEVEL ?= 2

all: sim verdi

compile: clean
	@echo "=== Compiling ==="
	${VCS_HOME}/bin/vcs -full64 -sverilog -ntb_opts uvm +define+DUMP=1 -debug_access+all -kdb -timescale=1ns/1ps +plusarg_save +log_level=$(LOG_LEVEL) \
		../src/*.sv \
		../tb/setup_uvm.sv \
		../tb/instruction.sv \
		../tb/instr_gen.sv \
		../tb/instr_monitor.sv \
		../tb/tb_mips.sv \
	-l compile.log

sim: compile
	@echo "=== Running simulation ==="
	./simv |& tee sim.log

verdi:
	@echo "=== Launching Verdi ==="
	${VERDI_HOME}/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -nologo &

clean:
	rm -rf simv csrc simv.daidir *.fsdb novas* *.key *.log verdi*

.PHONY: all clean compile sim verdi
