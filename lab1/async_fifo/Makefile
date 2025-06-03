all: compile sim waves_verdi

compile:
	@echo "=== Compiling async_fifo + tb_async_fifo.sv ==="
	${VCS_HOME}/bin/vcs -full64 -sverilog -debug_access+all src/*.sv >& compile.log

sim: compile
	@echo "=== Running simulation (writes fifo_tb.fsdb) ==="
	./simv_async_fifo

waves_verdi:
	@echo "=== Launching Verdi on fifo_tb.fsdb ==="
	${VERDI_HOME}/bin/verdi -ssf fifo_tb.fsdb &

clean:
	rm -rf simv_async_fifo csrc simv_async_fifo.daidir fifo_tb.fsdb vcs_compile.log *.key *.log

.PHONY: all compile sim waves_verdi clean
