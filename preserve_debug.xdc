# preserve_debug.xdc
set_property DONT_TOUCH true [get_cells -hier -quiet *cpu*]
set_property DONT_TOUCH true [get_cells -hier -quiet *u_tlut_wrapper*]

set key_nets [get_nets -hier -quiet {trap pcpi_ready mem_valid led_out}]
if {[llength $key_nets]} {
  set_property DONT_TOUCH true $key_nets
  set_property MARK_DEBUG true $key_nets
}

# Reloj de ejemplo (ajusta periodo y pin según tu board)
create_clock -name sys_clk -period 10.000 [get_ports clk]
