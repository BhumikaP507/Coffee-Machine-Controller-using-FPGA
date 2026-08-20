# ☕ Coffee Machine Controller using FPGA

A Verilog HDL implementation of a coffee vending machine controller, designed and deployed on a **Xilinx Artix-7 (Basys 3)** FPGA board. Built as a TE Semester-VI Mini Project (2025–26) for the Department of Electronics & Telecommunication Engineering, St. Francis Institute of Technology, Mumbai.

> Guide: Dr. Ravindra Chaudhari

---

## Overview

This project implements a **Moore Finite State Machine (FSM)** that governs the full operational flow of a coffee vending machine — product selection, payment verification, brewing simulation, and inventory management — entirely in hardware, exploiting the true parallelism and clock-cycle precision of an FPGA (as opposed to a sequential microcontroller-based design).

## Features

- **4-state Moore FSM** — `IDLE → PAYMENT → DISPENSE → (IDLE | EMPTY)`
- **Payment loop logic** — accumulates balance via debounced button presses until price threshold is met
- **7-second synchronous brewing timer** driven by a 100 MHz system clock
- **Dynamic inventory tracking** — starts at 3 cups, decrements per dispense, forces an `EMPTY` lockout state at zero (until manual refill)
- **Digital debouncing circuit** on the "Add Money" input for reliable single-pulse registration
- **20-bit clock divider** to bring the 100 MHz board clock down to a human-interactive rate
- **Multiplexed 4-digit seven-segment display** showing live state (`CUP3`, `P`, `d`, `E`) and inventory count
- **LED-based dispense indicator** (~3 Hz toggle) simulating physical pouring

## Hardware Used

| Component | Purpose |
|---|---|
| Digilent Basys 3 (Xilinx Artix-7, xc7a35tcpg236-1) | Core FPGA platform, 100 MHz clock |
| Onboard push buttons | Select coffee, add money, refill, reset |
| 4-digit 7-segment display | State & inventory feedback |
| Onboard LEDs | Dispense/pour indicator |

## Software Used

- **Xilinx Vivado Design Suite** — RTL coding (Verilog), simulation, synthesis, implementation, bitstream generation

## FSM States

| State | Display | Description |
|---|---|---|
| `IDLE` | `0` / `CUPx` | Machine ready, awaiting selection |
| `PAYMENT` | `P` | Awaiting sufficient balance |
| `DISPENSE` | `d` | 7-second brewing cycle, LED active |
| `EMPTY` | `E` | Out of stock, locked until refill |

## Repository Structure

```
├── sources/
│   └── coffee_machine.v      # Top-level FSM + datapath Verilog module
├── constraints/
│   └── basys3.xdc            # Pin mapping (XDC) for Basys 3
├── sim/
│   └── testbench.v           # Simulation testbench
└── docs/
    └── report.pdf            # Full mini-project report
```
*(adjust paths above to match your actual repo layout)*

## Results

- Verified stable `IDLE` state on reset with correct variable initialization
- Payment loop correctly held state until exact price condition met, with accurate $1-per-press debounced increments
- Inventory correctly decremented across 3 dispense cycles (`CUP3 → CUP2 → CUP1`) before forcing `EMPTY` lockout
- Seven-segment multiplexing verified with clean transitions between `0`, `P`, `d`, `E`
- Simulation (Vivado waveform) and physical hardware execution both confirmed correct FSM behavior

## Future Scope

- **Change calculation** for overpayment
- **Multiple beverage selection** (nested FSM for different coffee types/prices)
- **Real sensor/actuator integration** — coin acceptors, servo-driven dispensing, PWM control

## Team

- Bhumika Padmane (Roll No. 23)
- Rohit Prasad (Roll No. 31)
- Siddhi Rane (Roll No. 34)
- Deep Shah (Roll No. 41)

## References

See [`docs/report.pdf`](docs/report.pdf) for full literature survey and bibliography.[mini__1_ (3).pdf](https://github.com/user-attachments/files/31258025/mini__1_.3.pdf)
