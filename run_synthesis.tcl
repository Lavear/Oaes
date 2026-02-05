# ========================================================
# 1. SETUP LIBRARY
# ========================================================
# Using the stable 'run_fv' library
set_db library {/home/install/CONFRML172/share/cfm/lec/demo/run_fv/slow.lib}

# ========================================================
# 2. READ RTL (Current Folder)
# ========================================================
read_hdl aes_top.v
read_hdl aes_controller.v
read_hdl key_expansion.v
read_hdl state_reg.v
read_hdl aes_datapath.v
read_hdl subbytes.v
read_hdl shiftrows.v
read_hdl mixcolumns.v
read_hdl addroundkey.v

# ========================================================
# 3. BUILD CIRCUIT
# ========================================================
elaborate aes_top

# Define 50 MHz Clock
create_clock -name "clk" -period 20 [get_ports clk]

# Synthesize
syn_generic
syn_map
syn_opt

# ========================================================
# 4. GENERATE DETAILED REPORTS (Fixed Flags!)
# ========================================================
write_hdl > aes_netlist.v

# FIX: Used "-hier -depth 3" instead of "-levels 3"
report_power -hier -depth 3 > power_breakdown.rpt

# Standard Area Report
report_area > area_breakdown.rpt

puts "========================================================"
puts " DONE. Check 'power_breakdown.rpt' for the module breakdown."
puts "========================================================"
exit
