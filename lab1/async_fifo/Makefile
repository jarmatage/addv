all: sim verdi

compile:
	@echo "=== Compiling async_fifo + tb_async_fifo.sv ==="
	${VCS_HOME}/bin/vcs -full64 -sverilog -debug_access+all src/*.sv -kdb -lca |& tee compile.log

sim: compile
	@echo "=== Running simulation (writes fifo_tb.fsdb) ==="
	./simv

verdi:
	@echo "=== Launching Verdi on fifo_tb.fsdb ==="
	${VERDI_HOME}/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -nologo &

clean:
	rm -rf simv csrc simv.daidir fifo_tb.fsdb novas* *.key *.log

.PHONY: all compile sim waves_verdi clean

