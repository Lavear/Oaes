import matplotlib.pyplot as plt
import numpy as np
import sys

# 1. Reuse the parser from before (simplified here)
def parse_vcd_simple(filename):
    activity = []
    try:
        with open(filename, 'r') as f:
            count = 0
            for line in f:
                if line.startswith('#'): # New time step
                    activity.append(count)
                    count = 0
                elif len(line) > 0 and line[0] in ['0', '1', 'b']:
                    count += 1
    except: pass
    return activity

# 2. Load Data
data = parse_vcd_simple("aes.vcd")
if not data: 
    print("Error reading file.")
    sys.exit()

# 3. Compute FFT (Frequency Domain)
# We treat the sample rate as arbitrary for this demo
fft_vals = np.fft.rfft(data)
fft_freq = np.fft.rfftfreq(len(data))
power_spectrum = np.abs(fft_vals)

# 4. Plot
plt.figure(figsize=(10, 5))
plt.plot(fft_freq[1:], power_spectrum[1:], color='purple') # Skip DC component
plt.title('Power Spectral Density (Side-Channel Vulnerability Check)')
plt.xlabel('Frequency (Normalized)')
plt.ylabel('Magnitude')
plt.grid(True, alpha=0.3)
plt.savefig('aes_spectrum.png', dpi=300)
print("Generated aes_spectrum.png")
