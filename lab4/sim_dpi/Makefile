LOG_LEVEL ?= 2

all: sim verdi

compile: clean
	@echo "=== Compiling ==="
	${VCS_HOME}/bin/vcs -full64 -sverilog +define+DUMP=1 -debug_access+all -kdb -timescale=1ns/1ps +plusarg_save +log_level=$(LOG_LEVEL) \
		../src/*.sv \
		../tb/dpi.c \
		../tb/dpi_checker.sv \
		../tb/tb_async_fifo_dpi.sv \
	-l compile.log

sim: compile
	@echo "=== Running simulation ==="
	./simv |& tee sim.log

compile_bug: clean
	@echo "=== Compiling ==="
	${VCS_HOME}/bin/vcs -full64 -sverilog +define+DUMP=1 -debug_access+all -kdb -timescale=1ns/1ps +plusarg_save +log_level=$(LOG_LEVEL) +define+BUGGED \
		../src/*.sv \
		../tb/dpi.c \
		../tb/dpi_checker.sv \
		../tb/tb_async_fifo_dpi.sv \
	-l compile.log

sim_bug: compile_bug
	@echo "=== Running simulation ==="
	./simv |& tee sim.log

verdi:
	@echo "=== Launching Verdi ==="
	${VERDI_HOME}/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -nologo &

clean:
	rm -rf simv csrc simv.daidir *.fsdb novas* *.key *.log verdi*

.PHONY: all clean compile compile_bug sim sim_bug verdi
