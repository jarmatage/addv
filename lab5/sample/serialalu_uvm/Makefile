UVM_VERBOSITY = UVM_MEDIUM
TEST = serialalu_test
VCS =	$(VCS_HOME)/bin/vcs -full64 -sverilog -timescale=1ns/1ns \
	-ntb_opts uvm \
	-cm line+cond+fsm+branch+tgl -cm_dir ./coverage.vdb -l comp.log \

SIMV = ./simv +UVM_VERBOSITY=$(UVM_VERBOSITY) \
	+UVM_TESTNAME=$(TEST) +UVM_TR_RECORD +UVM_LOG_RECORD \
	+verbose=1 +ntb_random_seed=244 -l vcs.log

x:	comp run 

comp:
	$(VCS) +incdir+. serialalu_tb_top.sv

run:
	$(SIMV)

clean:
	rm -rf coverage.vdb csrc DVEfiles inter.vpd simv simv.daidir ucli.key vc_hdrs.h vcs.log .inter.vpd.uvm
