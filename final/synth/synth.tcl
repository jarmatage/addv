# Async Fifo Design Compiler Run Script
proc setup_clocks {{wperiod 1.0} {rperiod 1.0}} {
    # Remove existing clocks
    remove_clock -all

    # Create new clocks with specified periods
    create_clock -period $wperiod write.clk
    create_clock -period $rperiod read.clk
    set clock_uncertainty 0.1 [get_clocks]

    # Set delay on the ports
    set inputs [all_inputs -exclude_clock_ports]
    set_input_delay 0.1 -clock write.clk [filter_collection $inputs {name=~write.*}]
    set_input_delay 0.1 -clock read.clk  [filter_collection $inputs {name=~read.*}]
    set outputs [all_outputs]
    set_output_delay 0.1 -clock write.clk [filter_collection $outputs {name=~write.*}]
    set_output_delay 0.1 -clock read.clk  [filter_collection $outputs {name=~read.*}]
}

# Set libraries
lappend search_path [file join $::env(PDK_DIR) osu_soc lib files]
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

setup_clocks 0.8 0.8

# Compile
compile_ultra -timing_high_effort_script

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
