import cocotb
from caravel_cocotb.caravel_interfaces import test_configure, report_test
from cocotb.triggers import RisingEdge, FallingEdge
import sys
sys.path.append('..')
from VirtualGPIOModel import VirtualGPIOModel

@cocotb.test()
@report_test
async def spi_dv(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=1000000)
    cocotb.log.info("[TEST] start spi_dv")
    await caravelEnv.release_csb()

    vgpio = VirtualGPIOModel(caravelEnv)
    vgpio.start()

    spi_mosi = caravelEnv.dut.gpio8_monitor
    spi_miso = caravelEnv.dut.gpio9
    spi_sck = caravelEnv.dut.gpio10_monitor
    spi_ss = caravelEnv.dut.gpio11_monitor

    cocotb.log.info("[TEST] Waiting for firmware ready signal (vgpio=1)")
    await vgpio.wait_output(1)
    cocotb.log.info("[TEST] Firmware ready")

    cocotb.log.info("[TEST] Waiting for SPI peripheral enabled (vgpio=2)")
    await vgpio.wait_output(2)
    cocotb.log.info("[TEST] SPI peripheral enabled")

    test_data = [0x55, 0xAA, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC]
    rx_data = []

    if spi_ss.value != 0:
        await FallingEdge(spi_ss)
    cocotb.log.info("[TEST] SPI CS asserted")
    caravelEnv.dut.gpio9_en.value  = 1  # enable gpio input
    spi_miso.value = 0
    for byte_idx in range(8):
        byte_val = 0
        for bit_idx in range(8):
            await RisingEdge(spi_sck)
            bit = spi_mosi.value
            byte_val = (byte_val << 1) | int(bit)
        rx_data.append(byte_val)
        cocotb.log.info(f"[TEST] Received byte {byte_idx}: 0x{byte_val:02X}")


    cocotb.log.info("[TEST] Waiting for data transmission complete (vgpio=3)")
    await vgpio.wait_output(3)
    cocotb.log.info("[TEST] Data transmission complete")

    test_data = [0x66, 0xBB, 0x23, 0x42, 0x78, 0xab, 0xbb, 0xCF]

    for byte_idx in test_data:
        byte_val = bin(byte_idx)[2:].zfill(8)
        cocotb.log.info(f"byte val = {byte_val}")
        for bit_idx in range(8):
            if byte_val[bit_idx] == "1":
                spi_miso.value = 1
            else:
                spi_miso.value = 0
            await FallingEdge(spi_sck)



    cocotb.log.info("[TEST] Waiting for peripheral disabled (vgpio=6)")
    await vgpio.wait_output(6)
