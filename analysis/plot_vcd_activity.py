import matplotlib.pyplot as plt
import sys
import re

# ==========================================
# 1. SETUP
# ==========================================
vcd_filename = "aes.vcd"  # <--- MAKE SURE THIS MATCHES YOUR FILE NAME
bin_size = 100            # Group time steps to smooth the graph (try 10, 50, 100)

# ==========================================
# 2. VCD PARSER (Built-in, no pip install needed)
# ==========================================
def parse_vcd_activity(filename, bin_width):
    print(f"Reading {filename}... (This might take a moment)")
    
    time_bins = []
    activity_levels = []
    
    current_time = 0
    current_bucket_time = 0
    toggle_count = 0
    
    try:
        with open(filename, 'r') as f:
            in_dumpvars = False
            
            for line in f:
                line = line.strip()
                
                # Skip header info until we hit the real data
                if "$dumpvars" in line:
                    in_dumpvars = True
                    continue
                if not in_dumpvars and not line.startswith('#'):
                    continue

                # 1. Check for Time Change (e.g., #100, #200)
                if line.startswith('#'):
                    try:
                        new_time = int(line[1:])
                        
                        # If we crossed a "bin" boundary, save the data point
                        while current_time + bin_width <= new_time:
                            time_bins.append(current_time)
                            activity_levels.append(toggle_count)
                            
                            # Reset for next bin
                            current_time += bin_width
                            toggle_count = 0 
                            
                    except ValueError:
                        pass
                    continue
                
                # 2. Check for Value Changes (Logic 0, 1, or bus change)
                # Valid VCD changes look like: "1$", "0#", "b10101 %"
                # We count ANY change as "activity"
                if len(line) > 0 and line[0] in ['0', '1', 'x', 'z', 'b', 'r']:
                    toggle_count += 1
                    
        # Capture the last bin
        time_bins.append(current_time)
        activity_levels.append(toggle_count)
        
    except FileNotFoundError:
        print(f"ERROR: Could not find file '{filename}'")
        sys.exit(1)

    return time_bins, activity_levels

# ==========================================
# 3. RUN AND PLOT
# ==========================================
times, activity = parse_vcd_activity(vcd_filename, bin_size)

if not times:
    print("No data found! Check if VCD file is empty.")
    sys.exit()

print(f"Plotting {len(times)} data points...")

plt.figure(figsize=(12, 6))
plt.plot(times, activity, color='#d62728', linewidth=1) # Red color for power

plt.title('AES Switching Activity (Power Proxy)', fontsize=14)
plt.xlabel('Simulation Time (ns)', fontsize=12)
plt.ylabel('Switching Events (Toggle Count)', fontsize=12)
plt.grid(True, linestyle='--', alpha=0.7)

# Highlight the Encryption Rounds (Optional visual aid)
plt.fill_between(times, activity, color='#d62728', alpha=0.1)

plt.tight_layout()
plt.savefig('aes_activity_heartbeat.png', dpi=300)
print("Success! Saved graph to 'aes_activity_heartbeat.png'")
plt.show()
