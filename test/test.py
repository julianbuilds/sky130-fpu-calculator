import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_project(dut):
    dut._log.info("Starting FP16 Calculator testbench...")

    # Configurar un reloj de 10 MHz
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Reset del chip
    dut._log.info("Applying Reset...")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    dut._log.info("Reset completed. Chip is alive!")
    # Test básico: Dejar las entradas UART tranquilas en alto (idle)
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 100)