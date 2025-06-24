There are the following folders in the project:
  - src - contains all the system verilog for the mips processor.
  - tb  - contains testbenches for the code.
  - sim - compile and simulate the mips processor


All the sim directories have Makefiles, simply running `make` will run everything for you.

The targets in the Makefiles are:
  - all     - for running everything
  - compile - for running VCS
  - sim     - for running the simv executable
  - verdi   - for launching Verdi
  - clean   - for removing all simulation files
