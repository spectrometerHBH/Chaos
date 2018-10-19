set_property PACKAGE_PIN W5 [get_ports EXCLK]
set_property PACKAGE_PIN R2 [get_ports button]
set_property PACKAGE_PIN A18 [get_ports Tx]
set_property PACKAGE_PIN B18 [get_ports Rx]
set_property IOSTANDARD LVCMOS33 [get_ports EXCLK]
set_property IOSTANDARD LVCMOS33 [get_ports button]
set_property IOSTANDARD LVCMOS33 [get_ports Tx]
set_property IOSTANDARD LVCMOS33 [get_ports Rx]

connect_debug_port u_ila_0/clk [get_nets [list clk/inst/clkfbout_buf_clk_wiz_0]]
connect_debug_port dbg_hub/clk [get_nets u_ila_0_clkfbout_buf_clk_wiz_0]

connect_debug_port u_ila_0/probe0 [get_nets [list {CORE/PC/PC[0]} {CORE/PC/PC[1]} {CORE/PC/PC[2]} {CORE/PC/PC[3]} {CORE/PC/PC[4]} {CORE/PC/PC[5]} {CORE/PC/PC[6]} {CORE/PC/PC[7]} {CORE/PC/PC[8]} {CORE/PC/PC[9]} {CORE/PC/PC[10]} {CORE/PC/PC[11]} {CORE/PC/PC[12]} {CORE/PC/PC[13]} {CORE/PC/PC[14]} {CORE/PC/PC[15]} {CORE/PC/PC[16]} {CORE/PC/PC[17]} {CORE/PC/PC[18]} {CORE/PC/PC[19]} {CORE/PC/PC[20]} {CORE/PC/PC[21]} {CORE/PC/PC[22]} {CORE/PC/PC[23]} {CORE/PC/PC[24]} {CORE/PC/PC[25]} {CORE/PC/PC[26]} {CORE/PC/PC[27]} {CORE/PC/PC[28]} {CORE/PC/PC[29]} {CORE/PC/PC[30]} {CORE/PC/PC[31]}]]
connect_debug_port u_ila_0/probe1 [get_nets [list CORE/PC/clk]]
connect_debug_port u_ila_0/probe2 [get_nets [list CORE/PC/rst]]


