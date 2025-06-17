all: sim verdi

compile: clean
	@echo "=== Compiling ==="
	${VCS_HOME}/bin/vcs -full64 -sverilog +define+DUMP=1 -debug_access+all -kdb -timescale=1ns/1ps \
		../src/params.sv \
		../src/fp8_value.sv \
		../src/fp8_addsub.sv \
		../src/fp8_mult.sv \
		../src/output_logic.sv \
		../src/ram.sv \
		../src/fp8_mac.sv \
		../src/seq_mac.sv \
		../src/systolic_data_setup.sv \
		../src/matmul.sv \
		../tb/helpers.sv \
		../tb/matmul_tb.sv \
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
