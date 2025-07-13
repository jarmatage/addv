There are the following folders in the project:
  - src   - contains all the system verilog for the pipelined mips processor.
  - tb    - contains uvm classes and the testbench for the code.
  - sim   - compile and simulate the mips processor
  - synth - synthesize the design with a clock frequency sweep.


All the sim directories have Makefiles, simply running `make` will run everything for you.

The targets in the sim Makefile are:
  - all         - for running everything
  - compile     - for running VCS
  - sim         - for running the simv executable
  - compile_bug - compile the fifo with a BUGGED macro
  - sim_bug     - simulate the fifo with a BUGGED macro
  - verdi       - for launching Verdi
  - cov         - runs a sweep of simulations with different seeds and then lauches verdi
  - clean       - for removing all simulation files
