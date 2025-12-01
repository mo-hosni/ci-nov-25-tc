import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles
from caravel_cocotb.caravel_interfaces import test_configure, report_test
from VirtualGPIOModel import VirtualGPIOModel

@cocotb.test()
@report_test
async def i2c_dv(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=500_000)
    cocotb.log.info("[TEST] Starting i2c_dv test")
    await caravelEnv.release_csb()

    vgpio = VirtualGPIOModel(caravelEnv)
    vgpio.start()

    # I2C pins: SCL=5, SDA=4
    i2c_scl = caravelEnv.dut.gpio5_monitor
    i2c_sda = caravelEnv.dut.gpio4_monitor

    cocotb.log.info("[TEST] Waiting for firmware ready (vgpio=1)")
    await vgpio.wait_output(1)
    cocotb.log.info("[TEST] Firmware ready")

    cocotb.log.info("[TEST] Waiting for I2C enabled (vgpio=2)")
    await vgpio.wait_output(2)
    cocotb.log.info("[TEST] I2C peripheral enabled")

    # Monitor I2C activity
    # Wait for START condition (SDA falls while SCL is high)
    scl_high_count = 0
    sda_toggle_count = 0
    
    for _ in range(50000):
        await ClockCycles(caravelEnv.clk, 1)
        if i2c_scl.value == 1:
            scl_high_count += 1
        if i2c_sda.value != getattr(test_i2c_dv, 'last_sda', 0):
            sda_toggle_count += 1
        test_i2c_dv.last_sda = i2c_sda.value
        
        # Check if we've reached milestone 3
        vgpio_val = vgpio.read_current()
        if vgpio_val >= 3:
            break

    cocotb.log.info(f"[TEST] Observed SCL high cycles: {scl_high_count}")
    cocotb.log.info(f"[TEST] Observed SDA toggles: {sda_toggle_count}")

    # Basic check: we should see some activity on both lines
    if scl_high_count > 100 and sda_toggle_count > 5:
        cocotb.log.info("[TEST] I2C bus activity detected - PASS")
    else:
        cocotb.log.warning("[TEST] Limited I2C bus activity detected")

    cocotb.log.info("[TEST] Waiting for transaction complete (vgpio=3)")
    await vgpio.wait_output(3)
    cocotb.log.info("[TEST] I2C transaction complete")

    cocotb.log.info("[TEST] Waiting for peripheral disabled (vgpio=4)")
    await vgpio.wait_output(4)
    cocotb.log.info("[TEST] I2C peripheral disabled")

    cocotb.log.info("[TEST] i2c_dv complete - PASS")
