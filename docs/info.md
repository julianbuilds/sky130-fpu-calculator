## How it works

This project implements a **half-precision floating-point (FP16) calculator ASIC** 
designed for the SkyWater 130nm process via TinyTapeout.

The chip contains three main blocks:
- **FP16 Arithmetic Core**: Performs 6 operations (ADD, SUB, MUL, DIV, SQRT, POW) 
  on IEEE 754 half-precision numbers, using operators generated with FloPoCo.
- **UART RX**: Receives 7-byte command packets from the host at 115200 baud.
- **UART TX**: Sends 5-byte response packets with the result and status flags.

## How to test

Connect a USB-to-UART adapter (CP2102, CH340 or similar):
- `ui[0]` → UART RX (connect to TX of your adapter)
- `uo[0]` → UART TX (connect to RX of your adapter)

Send a 7-byte packet: `[0xAA, OP, A_hi, A_lo, B_hi, B_lo, 0x55]`  
Receive a 5-byte response: `[0xBB, R_hi, R_lo, FLAGS, 0x66]`

Operation codes: `0=ADD, 1=SUB, 2=MUL, 3=DIV, 4=SQRT, 5=POW`

Numbers are encoded as IEEE 754 FP16 (16-bit, big-endian).  
Clock: 10 MHz. UART: 115200 baud 8N1.
