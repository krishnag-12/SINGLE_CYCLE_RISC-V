# 📂 Verilog Source Files – Single Cycle RISC-V Processor

This folder contains the modular **Verilog HDL source files** used in building the **Single Cycle RISC-V Processor**. Each file represents a key functional block in the processor's datapath or control logic.

---

## 📁 Folder Contents

| File Name            | Description                                         |
|----------------------|-----------------------------------------------------|
| `main_decoder.v`     | Generates main control signals based on opcode      |
| `alu_decoder.v`      | Determines the ALU operation based on funct fields  |
| `pc_adder.v`         | Computes PC + 4 for instruction sequencing          |
| `sign_extender.v`    | Sign-extends immediates to 32-bit                   |
| `control_unit.v`     | Integrates main and ALU decoders into control logic |
| `instruction_memory.v` | Provides instruction storage and fetch capability |
| `register_file.v`    | Implements the RISC-V register file (x0–x31)        |
| `alu.v`              | Arithmetic Logic Unit – performs operations         |
| `program_counter.v`  | Holds and updates the current PC value              |

---

## 💡 Usage Instructions

1. These files are intended to be included in the top-level module `riscv.v` (or `single_cycle_riscv.v`).
2. They are used in simulation and synthesis through Vivado.
3. If you're using Vivado:
   - Go to **Project Manager > Add Sources**.
   - Add all `.v` files from this folder to your design.

Alternatively, if you're compiling using a command-line simulator:
```bash
iverilog -o riscv_cpu riscv.v Verilog_Files/*.v
vvp riscv_cpu
```

---

## 📌 Notes
- Each module is written in clean, synthesizable Verilog.
- Modular design enables easier debugging, testing, and extensibility.
- You can modify these modules independently to experiment with new features like pipelining or branching.
