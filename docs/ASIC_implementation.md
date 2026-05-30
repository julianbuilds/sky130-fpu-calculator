# Sky130 Floating-Point Unit (FPU) Calculator

[![DRC Check](https://img.shields.io/badge/DRC-Passed-success)](https://github.com/julianbuilds/repo)
[![LVS Check](https://img.shields.io/badge/LVS-Passed-success)](https://github.com/julianbuilds/repo)
[![PDK](https://img.shields.io/badge/PDK-Sky130-blue)](https://github.com/google/skywater-pdk)

## Project Overview
This repository contains the RTL design and physical implementation (RTL-to-GDSII) of a hardware **Floating-Point Unit (FPU) Calculator**, targeted for the **Skywater 130nm** open-source process node. The design handles standard arithmetic operations through digital logic principles and has been physically implemented using the OpenLane/LibreLane toolchain.

## Architecture and Design
The core functionality is implemented in SystemVerilog. 
* **Top Module:** `tt_um_digital_asic_fp_calculator`
* **Clock Period:** 100ns
* **Interfaces:** Features an asynchronous reset (`rst_n`), system clock (`clk`), and standard data I/O buses.

## Physical Implementation (OpenLane Flow)
The physical design process successfully navigated complex routing and Power Distribution Network (PDN) constraints:
* **Cell Library:** `sky130_fd_sc_hd` (High Density)
* **Die Area:** Rigidly constrained to `682.64 um x 225.76 um`.
* **PDN Strategy:** To comply with macro-level integration rules and avoid utilizing the forbidden `met5` layer, the power grid was constructed up to `met4`. `DESIGN_IS_CORE` was set to `false` to prevent unwanted power ring generation.
* **Timing Closure:** Hold violations under specific extreme corners (e.g., `min_ff_n40C`) were successfully mitigated using OpenROAD's post-routing resizing tools.

## Verification & Sign-off Status
The design has passed the fundamental physical verification checks, ensuring its core logic is ready for manufacturing:
- [x] **Logic Synthesis (Yosys):** Successful
- [x] **Antenna Rule Checks:** Passed
- [x] **LVS (Layout vs Schematic):** Passed
- [x] **DRC (Design Rule Check):** Passed (Magic & KLayout)

## Directory Structure
* `src/`: Contains all SystemVerilog/Verilog source files (`fp_calculator_top.v`, `uart_tx.v`, etc.) and the OpenLane `config.json`.
* `runs/`: Contains the generated GDSII, LEF, and DEF files after running the hardening process.
* `docs/`: Includes the final IEEE formatted project report.

## How to Build
To harden the macro using the OpenLane flow, ensure the OpenLane environment is set up and execute the flow targeting the configuration file located in the `src/` directory.

---
*Designed for academic evaluation and open-source ASIC exploration.*
