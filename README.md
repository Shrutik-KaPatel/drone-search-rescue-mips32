# 🚁 Drone Search & Rescue Edge Processing
## Using a 5-Stage Pipelined MIPS32 Processor

![Vivado](https://img.shields.io/badge/Tool-Vivado%202025.2-blue)
![Language](https://img.shields.io/badge/Language-Verilog-orange)
![Simulator](https://img.shields.io/badge/Simulator-XSim-green)
![Status](https://img.shields.io/badge/Status-Verified-brightgreen)
![Level](https://img.shields.io/badge/Level-Graduate-purple)

---

## 📖 Overview

This project implements a **5-stage pipelined MIPS32-like processor** in Verilog and demonstrates its application in a **drone search-and-rescue edge preprocessing** scenario.

In modern rescue operations, drones collect large volumes of sensor data — thermal readings, motion detection, and acoustic signals. Instead of transmitting raw data to remote AI systems, lightweight **edge preprocessing** can be performed directly on an embedded processor onboard the drone.

This project demonstrates how a custom pipelined MIPS32 processor can perform **real-time rescue score computation** from sensor data before forwarding prioritized results to an AI decision system.

---

## 🎯 Application Scenario

A search-and-rescue drone scans **5 locations** and collects three sensor readings per location:

| Sensor | Meaning |
|--------|---------|
| **Thermal** | Possible human body heat signature |
| **Motion** | Movement detected at location |
| **Sound** | Acoustic signal detected |

For each location the processor computes a **Rescue Priority Score:**
```
RescueScore = Thermal + Motion + Sound
```

Higher scores indicate locations where survivors are more likely present, allowing rescue teams to prioritize efficiently.

---

## 🏗️ Processor Architecture

### 5-Stage Pipeline
```
┌──────┐     ┌──────┐     ┌──────┐     ┌──────┐     ┌──────┐
│  IF  │────▶│  ID  │────▶│  EX  │────▶│ MEM  │────▶│  WB  │
└──────┘     └──────┘     └──────┘     └──────┘     └──────┘
  clk1         clk2         clk1         clk2         clk1
```

| Stage | Clock | Function |
|-------|-------|----------|
| IF — Instruction Fetch | clk1 | Fetch instruction from memory |
| ID — Instruction Decode | clk2 | Decode instruction, read registers |
| EX — Execute | clk1 | ALU operation, branch target compute |
| MEM — Memory Access | clk2 | Load from / store to memory |
| WB — Write Back | clk1 | Write result to register file |

### Pipeline Registers
```
IF/ID → ID/EX → EX/MEM → MEM/WB
```

### Key Design Characteristics

- Two-phase clock (clk1 and clk2 alternate)
- 32 general-purpose registers (32-bit wide)
- 1024 × 32-bit memory
- **No data forwarding**
- **No hazard detection unit**
- Manual NOP insertion required for hazard avoidance

### Supported Instructions

| Category | Instructions |
|----------|-------------|
| Register-Register ALU | ADD, SUB, AND, OR, SLT, MUL |
| Immediate ALU | ADDI, SUBI, SLTI |
| Memory | LW, SW |
| Branch | BEQZ, BNEQZ |
| Halt | HLT |

---

## 🗺️ Memory Map

| Region | Address Range | Contents |
|--------|--------------|----------|
| Instruction Memory | Mem[0] – Mem[118] | Program instructions + NOPs |
| Sensor Data | Mem[200] – Mem[214] | 5 locations × 3 sensor values |
| Rescue Scores | Mem[300] – Mem[304] | 5 computed output scores |

---

## 📊 Sensor Data and Results

### Input Sensor Data

| Location | Address | Thermal | Motion | Sound |
|----------|---------|---------|--------|-------|
| 1 | Mem[200–202] | 70 | 10 | 5 |
| 2 | Mem[203–205] | 65 | 12 | 6 |
| 3 | Mem[206–208] | 80 | 15 | 4 |
| 4 | Mem[209–211] | 75 | 8 | 7 |
| 5 | Mem[212–214] | 60 | 9 | 3 |

### Computed Rescue Scores

| Location | Address | Score | Priority |
|----------|---------|-------|----------|
| 1 | Mem[300] | **85** | 3rd |
| 2 | Mem[301] | **83** | 4th |
| 3 | Mem[302] | **99** | 1st 🥇 |
| 4 | Mem[303] | **90** | 2nd |
| 5 | Mem[304] | **72** | 5th |

---

## 💻 Program Design

### Why Fully Unrolled Loop

The instruction program uses a **fully unrolled loop** — all 5 iterations written as straight-line code with no branch instructions.

This design decision was made after extensive debugging revealed three compounding problems with a looped approach on this specific processor:

1. **HLT-in-pipeline hazard** — TAKEN_BRANCH resets after just 1 EX cycle, so HLT fetched after BNEQZ reaches WB with TAKEN_BRANCH=0 and triggers premature halt after iteration 1
2. **Branch offset complexity** — offset must be recalculated every time NOPs are added or removed, and the displayed PC after a taken branch is `target+1` not `target`, making this error-prone
3. **Vivado XSim runtime limit** — the default 1000ns cutoff kills the simulation mid-execution when branches cause the program to run longer than a straight-line equivalent

Unrolling eliminates all three problems simultaneously.

### NOP Scheduling Rule

Because this processor has no forwarding and no hazard detection, the pipeline timing rule is:

> ⚠️ **Always insert exactly 2 NOPs** after any instruction whose result is needed by a subsequent instruction.

This applies to: `LW`, `ADD`, `SUB`, `ADDI`, `SUBI` — any instruction that writes a register.

1 NOP is **not enough** for this two-phase clock design. With only 1 NOP, the consumer instruction reads the register in ID (clk2) before the producer has completed WB (clk1).

### Instruction Schedule Per Iteration
```verilog
LW  R4, 0(R2)     // Load Thermal
NOP               // \
NOP               //  } wait for R4
LW  R5, 1(R2)     // Load Motion
NOP               // \
NOP               //  } wait for R5
LW  R6, 2(R2)     // Load Sound
NOP               // \
NOP               //  } wait for R6
ADD R7, R4, R5    // Thermal + Motion → R7
NOP               // \
NOP               //  } wait for R7
ADD R8, R7, R6    // + Sound → R8 (Rescue Score)
NOP               // \
NOP               //  } wait for R8
SW  R8, 0(R3)     // Store score to output memory
NOP
NOP
ADDI R2, R2, 3    // Advance sensor pointer by 3
NOP
NOP
ADDI R3, R3, 1    // Advance output pointer by 1
NOP
NOP
```

---

## ✅ Simulation Results
```
=============================
Processed Rescue Scores:
Score1 = 85  (expected 85) ✓
Score2 = 83  (expected 83) ✓
Score3 = 99  (expected 99) ✓
Score4 = 90  (expected 90) ✓
Score5 = 72  (expected 72) ✓
=============================
```

---

## 🗂️ Repository Structure
```
drone-search-rescue-mips32/
│
├── rtl/
│   └── pipe_MIPS32.v          # Processor RTL — 5-stage pipeline
│
├── tb/
│   └── pipe_MIPS32_tb.v       # Testbench — program + sensor data + monitor
│
├── docs/
│   └── waveform.png           # XSim waveform screenshot
│
└── README.md
```

---

## 🚀 How to Run

### Requirements
- Xilinx Vivado 2025.2 or compatible version
- XSim behavioral simulator (included with Vivado)

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/yourusername/drone-search-rescue-mips32.git
cd drone-search-rescue-mips32
```

**2. Open Vivado and create a new RTL project**
- Add `rtl/pipe_MIPS32.v` as a **design source**
- Add `tb/pipe_MIPS32_tb.v` as a **simulation source**

**3. Set simulation runtime to unlimited**

In the Vivado Tcl console paste this before launching:
```tcl
set_property -name {xsim.simulate.runtime} -value {-all} -objects [get_filesets sim_1]
save_project
```

**4. Run behavioral simulation**
```
Flow Navigator → Simulation → Run Simulation → Run Behavioral Simulation
```

**5. View results**

Check the Tcl console for the final `$display` output showing all 5 scores.

> ⚠️ **Important:** Do not click Run Synthesis or Run Implementation — this is a behavioral simulation project only. The processor RTL uses simulation constructs and is not intended for FPGA synthesis.

---

## 🐛 Debugging Journey

This project required significant debugging to reach the correct output. The key issues encountered and resolved are documented here as learning reference.

### Issue 1 — Incorrect NOP count (1 NOP instead of 2)
**Symptom:** Score1 correct, all others wrong or zero  
**Cause:** Only 1 NOP between dependent instructions. R7 and R8 were being read before WB completed  
**Fix:** Changed all dependent instruction gaps to exactly 2 NOPs

### Issue 2 — Wrong branch offset after NOP changes
**Symptom:** Loop branching to wrong address, skipping first LW  
**Cause:** Adding NOPs shifted all addresses but offset was not recalculated  
**Fix:** Recalculate as `Imm = target - (branch_address + 1)`. Note: displayed PC after taken branch = `target + 1`

### Issue 3 — Premature HALT after iteration 1
**Symptom:** Only Score1 computed, processor halts immediately after  
**Cause:** HLT placed after BNEQZ enters the pipeline during the taken branch. TAKEN_BRANCH resets to 0 after just 1 EX cycle, so by the time HLT reaches WB the flag is already 0 and HALTED is set  
**Fix:** Replaced looped approach with fully unrolled straight-line program

### Issue 4 — Vivado XSim 1000ns runtime cutoff
**Symptom:** Simulation always stops at exactly Time=987ns regardless of testbench code  
**Cause:** Vivado's default simulation runtime is 1000ns. The file `pipe_MIPS32_tb.tcl` containing `run 1000ns` is regenerated on every relaunch, overwriting any manual edits  
**Fix:** Fully unrolled program completes in ~2400ns. Combined with `set_property runtime -all` + `save_project` before launch

---

## 📚 Key Concepts Demonstrated

- Pipelined processor design in Verilog
- Two-phase clocking strategy
- Manual pipeline hazard scheduling
- Instruction encoding for MIPS-like ISA
- Behavioral simulation and waveform analysis
- Edge computing concept applied to rescue systems
- Git version control for HDL projects

---

## 🔮 Future Improvements

- [ ] Add data forwarding unit to eliminate manual NOPs
- [ ] Add hazard detection and automatic stall logic
- [ ] Implement branch prediction
- [ ] Add cache memory
- [ ] Support floating-point rescue score weighting
- [ ] Integration with AI accelerator module for autonomous triage

---

## 🛠️ Tools Used

- Verilog HDL
- Xilinx Vivado 2025.2
- XSim Behavioral Simulator
- Git / GitHub

---

## 👤 Author

**Shrutik ka Patel**  
M.Eng. Electrical Engineering  
Carleton University, Ottawa, Canada

---

## 📄 License

This project is developed for academic purposes as part of graduate coursework in computer architecture and digital design.
