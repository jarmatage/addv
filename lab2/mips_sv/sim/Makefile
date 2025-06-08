all: sim verdi

compile: clean
	@echo "=== Compiling ==="
	${VCS_HOME}/bin/vcs -full64 -sverilog -debug_access+all -kdb -lca \
		../src/*.v \
		../top.v \
		../mips_tb.v \
	|& tee compile.log

sim: compile
	@echo "=== Running simulation ==="
	./simv

verdi:
	@echo "=== Launching Verdi ==="
	${VERDI_HOME}/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -nologo &

clean:
	rm -rf simv csrc simv.daidir *.fsdb novas* *.key *.log verdi*

.PHONY: all clean compile sim verdi

