import sys
import re

# =========================================================
# STANDARD CMOS CONSTANTS (Textbook Values)
# Change these if you want to emulate a different node!
# =========================================================

# Scenario: 180nm Technology (Older, Robust, High Voltage)
TECH_NAME       = "180nm Generic CMOS"
VOLTAGE         = 1.8         # Volts
CAPACITANCE     = 0.002e-12   # 2 femtoFarads per node (Avg)
CLOCK_FREQ_MHZ  = 50.0        # 50 MHz Clock speed

# =========================================================

def calculate_watts(vcd_file):
    print(f"Reading {vcd_file}...")
    toggle_count = 0
    time_steps = 0
    
    try:
        with open(vcd_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith('#'):
                    time_steps += 1
                # Check for value changes (0, 1, b...)
                if len(line) > 0 and line[0] in ['0', '1', 'b']:
                    toggle_count += 1
    except FileNotFoundError:
        print("Error: File not found.")
        sys.exit(1)

    # ---------------------------------------------------------
    # THE MATH
    # ---------------------------------------------------------
    # 1. Total Energy consumed during the simulation (Joules)
    #    Energy = 0.5 * C * V^2 * Num_Toggles
    #    (We use 0.5 because a toggle is 0->1 or 1->0, charging OR discharging)
    energy_per_toggle = 0.5 * CAPACITANCE * (VOLTAGE ** 2)
    total_energy_joules = toggle_count * energy_per_toggle

    # 2. Duration of the simulation
    #    We assume the simulation covered exactly one block encryption.
    #    At 50 MHz, 1 cycle = 20ns. 
    #    Iterative AES takes ~11 cycles = 220ns duration.
    duration_seconds = 11 * (1 / (CLOCK_FREQ_MHZ * 1e6))
    
    # 3. Average Power (Watts = Joules / Seconds)
    power_watts = total_energy_joules / duration_seconds
    
    return toggle_count, total_energy_joules, power_watts

if __name__ == "__main__":
    vcd_file = "aes_power.vcd" 
    if len(sys.argv) > 1: vcd_file = sys.argv[1]

    toggles, joules, watts = calculate_watts(vcd_file)
    
    print("=" * 50)
    print(f"POWER ESTIMATION REPORT: {TECH_NAME}")
    print("=" * 50)
    print(f"Total Toggles:      {toggles:,}")
    print(f"Total Energy:       {joules*1e9:.2f} nJ (nanoJoules)")
    print(f"Simulation Time:    11 cycles @ {CLOCK_FREQ_MHZ} MHz")
    print("-" * 50)
    print(f"ESTIMATED POWER:    {watts*1000:.2f} mW (Milliwatts)")
    print("=" * 50)
