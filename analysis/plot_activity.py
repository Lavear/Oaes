import sys
import re
import matplotlib.pyplot as plt

def parse_vcd_activity(vcd_file, bin_size=10):
    """
    Parses a VCD file and counts transitions per time bin.
    Note: This is a simplified parser for standard VCDs.
    """
    time_bins = {}
    current_time = 0
    
    with open(vcd_file, 'r') as f:
        for line in f:
            line = line.strip()
            
            # Timestamp update (e.g., #100)
            if line.startswith('#'):
                try:
                    current_time = int(line[1:])
                except ValueError:
                    pass
                continue

            # Value change (logic 0 or 1)
            # Looks for lines ending in an identifier code (e.g., "1$")
            # We treat any value change line as a toggle.
            if any(c in line for c in '01xXzZ') and not line.startswith('$'):
                bin_idx = (current_time // bin_size) * bin_size
                time_bins[bin_idx] = time_bins.get(bin_idx, 0) + 1

    return time_bins

# Usage
vcd_filename = "aes_power_activity.vcd" # Make sure this matches your Verilog filename
bins = parse_vcd_activity(vcd_filename, bin_size=10)

# Plotting
times = sorted(bins.keys())
activity = [bins[t] for t in times]

plt.figure(figsize=(10, 6))
plt.plot(times, activity, color='orange', linewidth=2)
plt.fill_between(times, activity, color='orange', alpha=0.3)
plt.title("AES Switching Activity (Dynamic Power Proxy)")
plt.xlabel("Simulation Time (ns)")
plt.ylabel("Signal Toggles (Count)")
plt.grid(True)
plt.show()
