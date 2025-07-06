all: sim verdi

compile: clean
	${VCS_HOME}/bin/vcs -full64 -sverilog -debug_access+all -kdb \
		-timescale=1ns/1ps \
		-ntb_opts uvm \
		+plusarg_save \
		+define+DUMP=1 \
		../src/*.sv \
		../src/common/*.sv \
		../src/master/*.sv \
		../src/matmul/*.sv \
		../tb/matmul_tb.sv \
	-l compile.log

sim: compile
	./simv |& tee sim.log

verdi:
	${VERDI_HOME}/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -nologo &

clean:
	rm -rf simv csrc simv.daidir *.fsdb novas* *.key *.log verdi*

.PHONY: all clean compile sim verdi
