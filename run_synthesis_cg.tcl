# ========================================================
# 1. SETUP LIBRARY
# ========================================================
set_db library {/home/install/CONFRML172/share/cfm/lec/demo/run_fv/slow.lib}

# ========================================================
# 2. READ RTL
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
# 3. ENABLE CLOCK GATING (The New Part)
# ========================================================
elaborate aes_top

# Force Genus to insert Clock Gating logic
set_db lp_insert_clock_gating true

# Prevent flattening so we can still read the report
set_db auto_ungroup none

# Define Clock
create_clock -name "clk" -period 20 [get_ports clk]

# ========================================================
# 4. SYNTHESIZE
# ========================================================
syn_generic
syn_map
syn_opt

# ========================================================
# 5. GENERATE COMPARISON REPORTS
# ========================================================
write_hdl > aes_netlist_cg.v

# Report Power (Saved to a NEW file for comparison)
report_power -hier -depth 3 > power_with_cg.rpt

# Report Area (Area usually increases slightly due to extra gating logic)
report_area > area_with_cg.rpt

# Report Gates (Check this to see if "ICG" or "latch" cells appear)
report_gates > gates_used.rpt

puts "========================================================"
puts " CLOCK GATING SYNTHESIS COMPLETE."
puts " Compare 'power_breakdown.rpt' (Old) vs 'power_with_cg.rpt' (New)"
puts "========================================================"
exit
