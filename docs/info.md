## How it works

This project implements a 32-bit Floating-Point Unit (FPU) Arithmetic Core integrated with an interactive UART Controller.

## How to test

Connect a USB-to-UART bridge. Send serial data frames to ui_in[0] (UART RX) at 50 MHz. The final calculation results will be transmitted back through uo_out[0] (UART TX).