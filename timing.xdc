# Constraints para Proyecto 2 - Problema 1
# Clock 100 MHz
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

# Input delays
set_input_delay -clock clk -max 2.000 [get_ports resetn]

# Clock uncertainty
set_clock_uncertainty 0.200 [get_clocks clk]