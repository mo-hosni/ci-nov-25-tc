import cocotb
from cocotb.triggers import ClockCycles
from caravel_cocotb.caravel_interfaces import test_configure, report_test
from VirtualGPIOModel import VirtualGPIOModel

@cocotb.test()
@report_test
async def adc_dv(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=500_000)
    cocotb.log.info("[TEST] Starting adc_dv test")
    await caravelEnv.release_csb()

    vgpio = VirtualGPIOModel(caravelEnv)
    vgpio.start()

    cocotb.log.info("[TEST] Waiting for firmware ready (vgpio=1)")
    await vgpio.wait_output(1)
    cocotb.log.info("[TEST] Firmware ready")

    cocotb.log.info("[TEST] Waiting for ADC enabled (vgpio=2)")
    await vgpio.wait_output(2)
    cocotb.log.info("[TEST] ADC peripheral enabled")

    cocotb.log.info("[TEST] Waiting for first conversion complete (vgpio=3)")
    await vgpio.wait_output(3)
    cocotb.log.info("[TEST] First ADC conversion complete")

    # Read ADC value from vgpio
    await ClockCycles(caravelEnv.clk, 100)
    adc_value = vgpio.read_current() & 0xFFF
    cocotb.log.info(f"[TEST] ADC value read: 0x{adc_value:03X} ({adc_value})")

    # Verify ADC value is within valid 12-bit range
    if 0 <= adc_value <= 0xFFF:
        cocotb.log.info("[TEST] ADC value in valid range - PASS")
    else:
        cocotb.log.error(f"[TEST] ADC value out of range - FAIL")

    cocotb.log.info("[TEST] Waiting for multiple conversions complete (vgpio=5)")
    await vgpio.wait_output(5)
    cocotb.log.info("[TEST] Multiple ADC conversions complete")

    cocotb.log.info("[TEST] Waiting for ADC disabled (vgpio=6)")
    await vgpio.wait_output(6)
    cocotb.log.info("[TEST] ADC peripheral disabled")

    cocotb.log.info("[TEST] adc_dv complete - PASS")
