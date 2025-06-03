all: clean sim waves_verdi

compile:
	@echo "=== Compiling even_odd_ac + tb_even_odd_ac.sv ==="
	${VCS_HOME}/bin/vcs -full64 -sverilog -debug_access+all src/*.sv |& tee compile.log

sim: compile
	@echo "=== Running simulation (writes even_odd_ac_tb.fsdb) ==="
	./simv

waves_verdi:
	@echo "=== Launching Verdi on even_odd_ac_tb.fsdb ==="
	${VERDI_HOME}/bin/verdi -ssf even_odd_ac_tb.fsdb &

clean:
	rm -rf simv csrc simv.daidir even_odd_ac_tb.fsdb novas* *.key *.log verdiLog

.PHONY: all compile sim waves_verdi clean
