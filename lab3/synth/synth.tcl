# Async Fifo Design Compiler Run Script
puts "tcl = $tcl_patchLevel"

# Point to OSU 45nm PDK
set osu_freepdk [file join $::env(PDK_DIR) osu_soc lib files]
lappend search_path $osu_freepdk
set alib_library_analysis_path $osu_freepdk

# Set libraries
set link_library [list gscl45nm.db dw_foundation.sldb]
set target_library [list gscl45nm.db]

# Configure tool
define_design_lib WORK -path ./WORK
set verilogout_show_unconnected_pins "true"

# Read verilog
set files [list fp8_value fp8_addsub fp8_mult fp8_mac matmul matmul_with_ram]
set files [lmap f $files {file join .. src ${f}.sv}]
analyze -format sverilog $files

# Convert the design into lib cells
elaborate "matrix_multiplication"
current_design "matrix_multiplication"
link
uniquify

# Configure tool settings
set_max_area 0
set_optimize_registers true

# Create read and write clocks
create_clock -period 2.0 clk;

# Set the driving cell for all input ports
set_driving_cell -lib_cell INVX1 [all_inputs]

# Set delay on the ports
set_input_delay  0.1 -clock clk [remove_from_collection [all_inputs] clk]
set_output_delay 0.1 -clock clk [all_outputs]

# Don't touch the instruction memory to prevent it from being treated as constant
set_dont_touch [get_cells imem]

# Compile
compile -ungroup_all -map_effort high
compile_ultra -incremental

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
