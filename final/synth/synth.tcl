# Async Fifo Design Compiler Run Script
lappend search_path [file join $::env(PDK_DIR) osu_soc lib files]

# Set libraries
set alib_library_analysis_path "."
set link_library [list gscl45nm.db dw_foundation.sldb]
set target_library [list gscl45nm.db]

# Configure tool
define_design_lib WORK -path ./WORK
set verilogout_show_unconnected_pins "true"

# Read verilog
analyze -format sverilog [glob -type f {../src/*}]

# Convert the design into lib cells
elaborate async_fifo
link
uniquify

# Configure tool settings
set_optimize_registers true

# Set the driving cell for all input ports
set_driving_cell -lib_cell INVX1 [all_inputs]

# Create read and write clocks
create_clock -period 1.0 write.clk;
create_clock -period 1.0 read.clk;

# Set delay on the ports
set inputs [all_inputs -exclude_clock_ports]
set_input_delay 0.1 -clock write.clk [filter_collection $inputs {name=~write.*}]
set_input_delay 0.1 -clock read.clk  [filter_collection $inputs {name=~read.*}]
set outputs [all_outputs]
set_output_delay 0.1 -clock write.clk [filter_collection $outputs {name=~write.*}]
set_output_delay 0.1 -clock read.clk  [filter_collection $outputs {name=~read.*}]

# Compile
compile -ungroup_all -map_effort high
compile_ultra -incremental -timing_high_effort_script

# Validate
check_design

# Generate reports
file mkdir rpt
redirect [file join rpt constraint.rpt] { report_constraint -sig 6 -all_violators }
redirect [file join rpt timing.rpt]     { report_timing }
redirect [file join rpt cell.rpt]       { report_cell }
redirect [file join rpt power.rpt]      { report_power }
redirect [file join rpt area.rpt]       { report_area }

exit
