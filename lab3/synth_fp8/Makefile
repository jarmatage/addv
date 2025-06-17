all: synth

synth: clean
	@echo "=== Launching Design Compiler ==="
	dc_shell-t -f synth.tcl |& tee synth.log

clean:
	rm -rf *.syn *.pvl *.mr *.svf command.log  WORK rpt

.PHONY: all clean synth

