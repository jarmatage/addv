all: sim verdi

compile: clean
	@echo "=== Compiling async_fifo + tb_async_fifo.sv ==="
	${VCS_HOME}/bin/vcs -full64 -sverilog -debug_access+all -kdb -lca \
		../src/*.v \
		../top.v \
		../mips_tb.v \
	|& tee compile.log

sim: compile
	@echo "=== Running simulation (writes fifo_tb.fsdb) ==="
	./simv

verdi:
	@echo "=== Launching Verdi on fifo_tb.fsdb ==="
	${VERDI_HOME}/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -nologo &

clean:
	rm -rf simv csrc simv.daidir *.fsdb novas* *.key *.log verdi*

.PHONY: all clean compile sim verdi

