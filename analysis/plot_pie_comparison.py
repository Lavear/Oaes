import matplotlib.pyplot as plt

# ==========================================
# 1. DATA (Same as before)
# ==========================================
labels = ['Datapath', 'Key Expansion', 'State Reg', 'Controller', 'CG Logic']
baseline_vals = [452.75, 461.84, 276.58, 14.07, 0]
cg_vals = [928.59, 331.10, 150.43, 6.54, 8.72]
colors = ['#ff9999', '#66b3ff', '#99ff99', '#ffcc99', '#c2c2f0']

# ==========================================
# 2. CREATE PLOTS WITH LEGENDS
# ==========================================
# Increase figure size slightly to make room for legends
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 8))

# --- Plot 1: Baseline ---
base_data = [(v, l, c) for v, l, c in zip(baseline_vals, labels, colors) if v > 0]
b_vals, b_labels, b_colors = zip(*base_data)

# pctdistance=1.15 moves percentages outside the pie
wedges1, texts1, autotexts1 = ax1.pie(b_vals, colors=b_colors, autopct='%1.1f%%', 
                                      startangle=140, shadow=True, explode=[0.05]*len(b_vals),
                                      pctdistance=1.15)
ax1.set_title('Baseline Power\n(Total: 1.26 mW)', fontsize=14, fontweight='bold', pad=20)

# Create Legend for Plot 1
ax1.legend(wedges1, b_labels, title="Modules", loc="center left", bbox_to_anchor=(0.9, 0, 0.5, 1))


# --- Plot 2: With Clock Gating ---
wedges2, texts2, autotexts2 = ax2.pie(cg_vals, colors=colors, autopct='%1.1f%%', 
                                      startangle=140, shadow=True, explode=[0.05]*len(cg_vals),
                                      pctdistance=1.15)
ax2.set_title('With Clock Gating\n(Total: 1.49 mW*)', fontsize=14, fontweight='bold', pad=20)

# Create Legend for Plot 2
ax2.legend(wedges2, labels, title="Modules", loc="center left", bbox_to_anchor=(0.9, 0, 0.5, 1))


# ==========================================
# 3. FINISHING TOUCHES
# ==========================================
plt.suptitle('AES Power Distribution Comparison', fontsize=18, y=0.98)

plt.figtext(0.5, 0.02, 
            "*Note: Datapath power increase is an artifact of vectorless estimation.\n"
            "Real hardware savings are shown in the reduced Key Exp & State Reg slices.", 
            ha="center", fontsize=11, style='italic', color='#d62728')

# Adjust layout to prevent overlapping with the new legends
plt.tight_layout(rect=[0, 0.05, 1, 0.93])

plt.savefig('aes_pie_comparison_fixed.png', dpi=300, bbox_inches='tight')
print("Generated: aes_pie_comparison_fixed.png")
plt.show()
