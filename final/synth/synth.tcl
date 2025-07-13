# Async Fifo Design Compiler Run Script
proc run_design {{wperiod 1.0} {rperiod 1.0}} {
    setup_clocks $wperiod $rperiod
    compile_design
    report_design $wperiod $rperiod
}

proc setup_clocks {wperiod rperiod} {
    # Remove existing clocks
    remove_clock -all

    # Create new clocks with specified periods
    create_clock -period $wperiod write.clk
    create_clock -period $rperiod read.clk
    set_clock_uncertainty 0.1 [get_clocks]

    # Set delay on the ports
    set inputs [all_inputs -exclude_clock_ports]
    set_input_delay 0.1 -clock write.clk [filter_collection $inputs {name=~write.*}]
    set_input_delay 0.1 -clock read.clk  [filter_collection $inputs {name=~read.*}]
    set outputs [all_outputs]
    set_output_delay 0.1 -clock write.clk [filter_collection $outputs {name=~write.*}]
    set_output_delay 0.1 -clock read.clk  [filter_collection $outputs {name=~read.*}]
}

proc compile_design {} {
    compile -ungroup_all -map_effort high
    compile_ultra -incremental
}

proc report_design {wperiod rperiod} {
    set rpt [file join rpt "${wperiod}_$rperiod"]
    file mkdir $rpt

    # Generate reports
    redirect [file join $rpt check.rpt]      {check_design}
    redirect [file join $rpt constraint.rpt] {report_constraint -sig 6 -all_violators}
    redirect [file join $rpt timing.rpt]     {report_timing}
    redirect [file join $rpt cell.rpt]       {report_cell}
    redirect [file join $rpt power.rpt]      {report_power}
    redirect [file join $rpt area.rpt]       {report_area}
    redirect [file join $rpt qor.rpt]        {report_qor}
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

# Perform frequency sweep
for {set i 0.5} {$i <= 2.0} {set i [expr $i + 0.1]} {
    for {set j 0.5} {$j <= 2.0} {set j [expr $j + 0.1]} {
        run_design $i $j
    }
}
exit
