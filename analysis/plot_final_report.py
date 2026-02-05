import matplotlib.pyplot as plt
import numpy as np

# ==========================================
# 1. DATA ENTRY (From your Table)
# ==========================================
# Units are in Micro-Watts (uW)

# Top-Level Modules
# Note: "Top Level Overhead" is calculated as Total - Sum(Modules)
# Total AES = 1494.31
# Sum(Datapath + KeyExp + StateReg + Controller) = 928.59 + 331.11 + 150.44 + 6.54 = 1416.68
# Overhead = 1494.31 - 1416.68 = 77.63 (Routing, Clock Tree, Glue Logic)
top_labels = ['Datapath', 'Key Expansion', 'State Registers', 'Controller', 'Top-Level Overhead']
top_values = [928.59, 331.11, 150.44, 6.54, 77.63]
top_colors = ['#ff6666', '#66b3ff', '#99ff99', '#ffcc99', '#d3d3d3'] # Red for Datapath (Hot!)

# Datapath Internals
# Datapath Total = 928.59
# Listed Children: SubBytes (494.29) + MixCols (280.71) + AddRoundKey (68.22) = 843.22
# Datapath Overhead (Muxes, wiring) = 928.59 - 843.22 = 85.37
dp_labels = ['SubBytes (S-Box)', 'MixColumns', 'AddRoundKey', 'Other Logic']
dp_values = [494.29, 280.71, 68.22, 85.37]
dp_colors = ['#800000', '#b30000', '#ff3333', '#ff9999'] # Shades of Red

# ==========================================
# 2. CREATE DASHBOARD (2 Subplots)
# ==========================================
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 7))

# --- CHART 1: TOP-LEVEL DISTRIBUTION (Donut Chart) ---
wedges, texts, autotexts = ax1.pie(top_values, labels=top_labels, colors=top_colors, 
                                   autopct='%1.1f%%', startangle=140, pctdistance=0.85,
                                   explode=[0.05, 0, 0, 0, 0])

# Draw a white circle at the center to make it a "Donut" chart
centre_circle = plt.Circle((0,0),0.70,fc='white')
ax1.add_artist(centre_circle)

ax1.set_title('Total AES Power Distribution\n(1.49 mW Total)', fontsize=14, fontweight='bold')
plt.setp(autotexts, size=10, weight="bold", color="black")

# --- CHART 2: DATAPATH BREAKDOWN (Bar Chart) ---
# We use a bar chart here to compare magnitudes clearly
y_pos = np.arange(len(dp_labels))

bars = ax2.barh(y_pos, dp_values, color=dp_colors)
ax2.set_yticks(y_pos)
ax2.set_yticklabels(dp_labels, fontsize=11)
ax2.invert_yaxis()  # Labels read top-to-bottom
ax2.set_xlabel('Power Consumption (µW)', fontsize=12)
ax2.set_title('Inside the Datapath: Where is the power going?', fontsize=14, fontweight='bold')
ax2.grid(axis='x', linestyle='--', alpha=0.7)

# Add value labels to the end of bars
for bar in bars:
    width = bar.get_width()
    ax2.text(width + 10, bar.get_y() + bar.get_height()/2, 
             f'{width:.1f} µW', 
             ha='left', va='center', fontweight='bold', color='#333333')

# ==========================================
# 3. SAVE AND SHOW
# ==========================================
plt.suptitle('AES Block-Level Power Analysis (Clock Gated Design)', fontsize=16, y=0.98)
plt.tight_layout(rect=[0, 0.05, 1, 0.95])
plt.savefig('aes_final_power_dashboard.png', dpi=300)
print("Generated: aes_final_power_dashboard.png")
plt.show()
