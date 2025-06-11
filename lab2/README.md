There are three folders in the project:
  - mips           - contains the orignal verilog MIPS
  - mips_sv        - contains a system verilog conversion of the unpipelined processor
  - mips_pipelined - contains the pipelined processor including extra credit

Under each project folder there are the following run directories:
  - sim        - For compiling, simulating and launching Verdi
  - synth      - For synthesizing with flip flops for memory
  - synth_sram - For synthesizing with SRAM

All the run directories have Makefiles, simply running `make` will run everything for you.

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
