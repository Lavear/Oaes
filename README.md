# **AES-128 Cryptographic Datapath: Design & Low-Power Analysis**

### **Overview**

This repository contains the Verilog HDL implementation of a 128-bit **Advanced Encryption Standard (AES)** cryptographic core. The project focuses on the hardware design of the AES algorithm and performs a comprehensive **Gate-Level Power Analysis** using Cadence Genus.

The primary objective is to implement the standard FIPS-197 AES algorithm and verify a **Low-Power Optimization Strategy** using **Clock Gating** to reduce dynamic power consumption in the sequential elements.

---

### **📂 File Description**

Here is the breakdown of the key files and folders included in this project:

#### **1. Source Code (`/src` or root)**

* **`aes_top.v`**: The top-level module for the **Iterative Architecture**. It controls the FSM (Finite State Machine) that loops data through the round logic 10 times.
* 
**`aes_pipeline_top.v`**: An alternative **Pipelined Architecture**. It unrolls the loops into 10 distinct hardware stages for high-throughput applications.


* 
**`aes_datapath.v`**: The container module that instantiates the four critical transformations for a single round.


* **`subbytes.v` / `aes_sbox.v**`: Implements the Non-Linear Substitution step using Look-Up Tables (LUTs). This provides the property of *Confusion*.


* 
**`shiftrows.v`**: Implements the cyclical byte shifting (Permutation) for *Diffusion*.


* 
**`mixcolumns.v`**: Implements the matrix multiplication step over Galois Field () to mix data within columns.


* 
**`aes_key_step.v`**: The key expansion logic that generates the *next* round key from the *current* key on the fly.



#### **2. Simulation & Verification (`/tb`)**

* **`tb_aes_top.v`**: The testbench. It acts as the "environment" that:
* Generates the Clock (`clk`) and Reset (`rst_n`).
* Feeds NIST Standard input vectors (`plaintext`, `key`).
* Captures the output `ciphertext` and compares it against the expected result.
* **Crucial:** Generates the `.vcd` (Value Change Dump) file used for power analysis.



#### **3. Synthesis & Scripts (`/scripts`)**

* **`run_synthesis.tcl`**: The Tcl script for **Cadence Genus**. It loads the libraries, reads the Verilog, applies constraints, and runs the synthesis engine.
* **`run_power_analysis.tcl`**: A script specifically for reading the `.vcd` file and generating power reports (Dynamic vs. Leakage).

#### **4. Visualization (`/graphs` or root)**

* **`plot_power.py`**: A Python script used to parse Genus reports and generate Pie Charts and Bar Graphs for the final report.
* **`aes_power_activity.vcd`**: The waveform database generated during simulation (used to plot the "Power Heartbeat").

---

### **⚙️ Architecture Explanation**

This project explores two architectural variants of AES:

1. **Iterative Architecture (Default):**
* Uses **one** shared hardware block for the Round Logic.
* Data loops back through this block 10 times.
* **Pros:** Small area (low gate count).
* **Cons:** Lower throughput (1 encryption per 10 cycles).


2. **Pipelined Architecture:**
* Uses **10** separate hardware blocks placed in a series.


* Registers (`pipe_state`) are placed between stages to hold intermediate data.


* **Pros:** High throughput (1 encryption per cycle).
* **Cons:** High area and higher peak power consumption.



---

### **⚡ Power Analysis & Optimization**

The project utilizes **Cadence Genus** for logic synthesis on a 45nm technology node.

#### **Baseline Power Profile**

* The **Datapath** (S-Boxes) consumes ~62% of total power due to high switching activity.
* **Sequential Logic** (Registers) accounts for ~38% of power in the unoptimized design.

#### **Optimization: Clock Gating**

To reduce power, **Integrated Clock Gating (ICG)** cells were inserted during synthesis.

* **Concept:** The clock signal to registers is disabled (gated) when the data enable signal is low.
* **Result:** Power consumption in the `Key Expansion` and `State Registers` was reduced by **~40%**.
* **Trade-off:** A small area overhead (<1%) was introduced for the gating logic (`RC_CG_HIER`).

---

### **🚀 How to Run**

#### **1. Simulation (SimVision/NCLaunch)**

Compile the design to verify functionality and generate the waveform:

```bash
irun -access +rwc tb_aes_top.v aes_top.v aes_datapath.v subbytes.v shiftrows.v mixcolumns.v aes_key_step.v

```

* *Output:* `aes.vcd` (Waveform file).

#### **2. Synthesis (Genus)**

Run the synthesis script to generate the netlist and power reports:

```bash
genus -f run_synthesis.tcl

```

* *Output:* `aes_netlist.v` and `power_breakdown.rpt`.

#### **3. Generate Plots**

Use the provided Python script to visualize the results:

```bash
python3 plot_power.py

```

---

### **📊 Results Summary**

| Metric | Value | Notes |
| --- | --- | --- |
| **Technology** | 45nm Standard Cell | Slow Library |
| **Total Cells** | 9,867 |  |
| **Max Frequency** | ~200 MHz | Estimated |
| **Total Power** | 1.49 mW | @ 1.1V |
| **Leakage Power** | < 1 µW | Negligible |

---

### **References**

* **AES Standard:** NIST FIPS-197.
* **Tools:** Cadence Xcelium and ModelSim (RTL Coding), SimVision (Waveform Debugging), Cadence Genus (Synthesis and Power Analysis).
