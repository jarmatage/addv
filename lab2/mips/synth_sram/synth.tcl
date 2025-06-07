# Async Fifo Design Compiler Run Script
puts "tcl = $tcl_patchLevel"

# Point to OSU 45nm PDK
set osu_freepdk [file join $::env(PDK_DIR) osu_soc lib files]
lappend search_path $osu_freepdk
set alib_library_analysis_path $osu_freepdk

# Point to the SRAM
set sram_path [file normalize "../../sram_32x64"]
lappend search_path $sram_path
lappend alib_library_analysis_path $sram_path

# Set libraries
set link_library [list gscl45nm.db dw_foundation.sldb SRAM_32x64_1rw.db]
set target_library [list gscl45nm.db SRAM_32x64_1rw.db]

# Configure tool
define_design_lib WORK -path ./WORK
set verilogout_show_unconnected_pins "true"

# Read verilog
set files [glob -type f {../src/*}]
lappend files "../top_with_sram.v"
analyze -format sverilog $files

# Convert the design into lib cells
elaborate "top"
current_design "top"
link
uniquify

# Configure tool settings
set_wire_load_model -name typical
set_max_area 0
set_max_delay 2.0
set_optimize_registers true

# Create read and write clocks
create_clock -period 1.10 clk; # 0.909 GHz

# Set the driving cell for all input ports
set_driving_cell -lib_cell INVX1 [all_inputs]

# Set delay on the ports
set_input_delay  0.1 -clock clk [remove_from_collection [all_inputs] clk]
set_output_delay 0.1 -clock clk [all_outputs]

# Compile
compile -ungroup_all -map_effort high
compile_ultra -incremental -timing

# Validate
check_design

# Generate reports
file mkdir rpt_sram
redirect [file join rpt_sram constraint.rpt] { report_constraint -sig 6 -all_violators }
redirect [file join rpt_sram timing.rpt]     { report_timing }
redirect [file join rpt_sram cell.rpt]       { report_cell }
redirect [file join rpt_sram power.rpt]      { report_power }
redirect [file join rpt_sram area.rpt]       { report_area }

exit
