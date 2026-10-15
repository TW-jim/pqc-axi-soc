current_design NTT_Acc_Dilithium_Private_Top

set clk_name ACLK
set clk_port_name ACLK
set clk_period 2.0

set clk_port [get_ports $clk_port_name]

create_clock -name $clk_name -period $clk_period $clk_port

set clk_io_pct 0.20

set non_clock_inputs [lsearch -inline -all -not -exact [all_inputs] $clk_port]

set_input_delay \
    [expr $clk_period * $clk_io_pct] \
    -clock $clk_name \
    $non_clock_inputs

set_output_delay \
    [expr $clk_period * $clk_io_pct] \
    -clock $clk_name \
    [all_outputs]

set_false_path -from [get_ports ARESETn]
