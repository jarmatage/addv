There are the following folders in the project:
  - src         - contains all the system verilog for the async fifo.
  - bugged      - a copy of the src folder but with a bug injected into the async fifo.
  - tb          - contains testbenches for the code.
  - sim_sv      - compile and simulate the async fifo, SV-style.
  - sim_sv_bug  - compile and simulate the bugged async fifo, SV-style.
  - sim_dpi     - compile and simulate the async fifo, DPI-style.
  - sim_dpi_bug - compile and simulate the bugged async fifo, DPI-style.


All the sim directories have Makefiles, simply running `make` will run everything for you.

The targets in the Makefiles are:
  - all     - for running everything
  - compile - for running VCS
  - sim     - for running the simv executable
  - verdi   - for launching Verdi
  - clean   - for removing all simulation files
