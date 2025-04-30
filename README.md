# 🚀 Single Cycle RISC-V Processor (Verilog HDL)

This project is a Verilog implementation of a **Single Cycle RISC-V Processor**, designed to execute basic RISC-V instructions in a single clock cycle. The processor follows the **RV32I** base instruction set architecture and implements key components such as the ALU, instruction memory, control unit, and register file.

---

## 🛠️ Main Features

- Fully modular design
- Executes one instruction per clock cycle
- Supports R-type, I-type, S-type, and B-type instructions
- Implements RV32I subset
- Written and simulated using **Verilog HDL** on **Xilinx Vivado**

---

## 📁 Project Structure

- `riscv.v` – Top-level module that integrates all components
- `program_counter.v` – Maintains the current instruction address
- `instruction_memory.v` – Stores the instruction set
- `register_file.v` – Stores CPU registers (x0 to x31)
- `sign_extender.v` – Handles immediate extraction and sign-extension
- `alu.v` – Performs arithmetic and logic operations
- `control_unit.v` – Decodes instructions and generates control signals
- `data_memory.v` – Simulates read/write data memory
- `pc_adder.v` – Computes `PC + 4` for the next instruction address
- `single_cycle_riscv_tb.v` – Testbench for simulating the processor in Vivado

---

## 📌 Main Module: `single_cycle_riscv`

### **Inputs:**
- `clk`: Clock signal
- `rst`: Reset signal (active high)

### **Functional Highlights:**
- Fetches and decodes instructions using the current Program Counter
- Performs ALU operations based on control logic
- Writes back results to the register file or memory
- Increments the Program Counter after each instruction

---

## 🧪 Simulation

This project is simulated using **Vivado**. A testbench named `single_cycle_riscv_tb.v` is included to test the processor’s functionality.

### 🔁 Clock & Reset Behavior

```verilog
// Clock toggles every 5ns (10ns period)
always #5 clk = ~clk;

// Reset pulse sequence
initial begin
    clk = 0;
    rst = 1;
    #10;
    rst = 0;  // Assert reset
    #10;
    rst = 1;  // Deassert reset
    #100;
    $finish;
end
```

---

## ▶️ Steps to Simulate in Vivado:
- Launch Vivado and create a new project.
- Add all Verilog source files and the testbench (`single_cycle_riscv_tb.v`) to the project.
- Set `single_cycle_riscv_tb` as the top module for simulation.
- Run Behavioral Simulation.
- Observe waveform outputs like:
 - `PC`
 - `instruction`
 - `ALU result`
 - `Register writes`
 - `Memory reads/writes`
You can use Vivado’s waveform viewer to analyze how the datapath components behave on each clock cycle.

---

## 🙌 Acknowledgments
Thanks to the open-source hardware and education communities for RISC-V documentation and reference designs.
