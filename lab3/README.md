There are the following folders in the project:
  - src          - contains all the synthesizable system verilog for the lab
  - tb           - contains testbenches for the code.
  - sim_addsub   - compile and simulate the fp8 adder arithmetic unit
  - sim_mult     - compile and simulate the fp8 multiplier arithmetic unit
  - sim_int8     - compile and simulate the baseline int8 matrix multiplier
  - sim_fp8      - compile and simulate the fp8 matrix multiplier with APB
  - sim_matmul   - compile and simulate the matrix multiplier with both int8 and fp8 (extra credit)
  - synth_int8   - synthesize the baseline int8 matrix multiplier
  - synth_fp8    - synthesize the fp8 matrix multiplier
  - synth_matmul - synthesize the matrix multiplier with both int8 and fp8 (extra credit)

All the sim/synth directories have Makefiles, simply running `make` will run everything for you.

The targets in the sim Makefiles are:
  - all : for running everything
  - compile : for running VCS
  - sim : for running the simv executable
  - verdi : for launching Verdi
  - clean : for removing all simulation files

The targets in the synth Makefiles are:
  - all : for running everything
  - synth : for running DC compiler
  - clean : for removing all synthesis files
