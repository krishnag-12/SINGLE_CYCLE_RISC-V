# 🛠️ Vivado Project Files – RISC-V Processor

This folder contains the **Vivado (.xpr)** project files for the **Single Cycle RISC-V Processor** implemented in Verilog HDL.

---

## 📂 Folder Contents

The files in this directory include:

- `RISC-V.xpr` – Vivado project file (main entry point)
- `.xpr.cache/`, `.runs/`, `.hw/`, `.ip_user_files/` – Vivado-generated folders
- `srcs/` – Source folder containing all Verilog design and testbench files
- `sim/` – Optional simulation scripts and results (if any)

---

## 🚀 Purpose

These files are used to open and simulate the RISC-V processor design in **Xilinx Vivado**. You can run behavioral simulation, analyze the waveform, and verify functionality using the testbench provided.

---

## ▶️ How to Use

1. **Open Vivado**.
2. Click on **File > Open Project**.
3. Navigate to this folder and select `RISC-V.xpr`.
4. Wait for Vivado to load all design sources and simulation files.
5. Set `single_cycle_riscv_tb` as the **top module for simulation**.
6. Run **Behavioral Simulation** to see the processor in action.

---

## 💡 Notes

- Ensure you have **Vivado installed** (tested with Vivado 2020.2 or later).
- If simulation sources or IPs are missing, re-add them manually through **Project Settings > Sources**.
- You may need to regenerate the simulation settings if they were removed.

---
