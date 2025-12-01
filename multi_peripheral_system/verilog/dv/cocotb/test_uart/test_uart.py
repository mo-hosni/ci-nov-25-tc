import cocotb
from cocotb.triggers import RisingEdge
from caravel_cocotb.caravel_interfaces import test_configure, report_test, UART
from VirtualGPIOModel import VirtualGPIOModel  # Ensure this helper is available

@cocotb.test()
@report_test
async def uart_dv(dut):
    # Initialize test environment (adjust timeout if needed)
    caravelEnv = await test_configure(dut, timeout_cycles=200_000)
    cocotb.log.info("[TEST] start uart_dv")
    await caravelEnv.release_csb()

    # Start the virtual GPIO model (listens to/controls the virtual GPIO register)
    vgpio = VirtualGPIOModel(caravelEnv)
    vgpio.start()

    # Prepare UART monitor on external pins (TX=5, RX=6)
    uart = UART(caravelEnv, {"tx": 5, "rx": 6})
    uart.baud_rate = 115200

    cocotb.log.info("[TEST] Waiting for firmware signal sequence via Virtual GPIO...")

    # 1) Firmware ready
    await vgpio.wait_output(1)
    cocotb.log.info("[TEST] Firmware ready")

    # 2) Peripheral enabled
    await vgpio.wait_output(2)
    cocotb.log.info("[TEST] UART enabled - starting UART receive monitor")

    # Start monitoring UART in parallel with firmware execution
    # Firmware will send data and then signal milestone 3
    msg = await uart.get_line()  # waits until '\n'
    cocotb.log.info(f"[TEST] Received UART: '{msg}'")

    expected = "Hello UART"
    if expected in msg:
        cocotb.log.info("[TEST] PASS - expected UART message received")
    else:
        cocotb.log.error(f"[TEST] FAIL - expected '{expected}', got '{msg}'")
        assert False, f"UART test failed: expected '{expected}', got '{msg}'"

    # 3) Transmission complete (firmware signals after UART data sent)
    await vgpio.wait_output(3)
    cocotb.log.info("[TEST] UART transmission phase complete")

    # 4) Peripheral disabled
    await vgpio.wait_output(4)
    cocotb.log.info("[TEST] UART disabled")

    # 5) Final pulse after attempted post-disable action
    await vgpio.wait_output(5)
    cocotb.log.info("[TEST] Post-disable check pulse observed")

    # 6) Optional cross-peripheral marker
    await vgpio.wait_output(6)
    cocotb.log.info("[TEST] Optional cross-peripheral marker observed")

    cocotb.log.info("[TEST] end uart_dv")
