import cocotb
from caravel_cocotb.caravel_interfaces import test_configure, report_test
from cocotb.triggers import RisingEdge, ClockCycles
import sys
sys.path.append("..")
from VirtualGPIOModel import VirtualGPIOModel

@cocotb.test()
@report_test
async def sram_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=15000000)
    cocotb.log.info("[TEST] ========================================")
    cocotb.log.info("[TEST] COMPREHENSIVE SRAM VERIFICATION SUITE")
    cocotb.log.info("[TEST] SRAM: 1024 words x 32 bits (4KB)")
    cocotb.log.info("[TEST] Address Range: 0x000 - 0x3FF (10-bit)")
    cocotb.log.info("[TEST] Focus: Corner addresses, data types, boundaries")
    cocotb.log.info("[TEST] ========================================")
    await caravelEnv.release_csb()

    vgpio = VirtualGPIOModel(caravelEnv)
    vgpio.error_code = 0xEEEE
    vgpio.start()

    cocotb.log.info("[TEST] Waiting for firmware initialization...")

    await vgpio.wait_output(1)
    cocotb.log.info("[TEST] Phase 1: System initialization complete")
    cocotb.log.info("[TEST]   -> SRAM accessible at base 0x30010000")

    await vgpio.wait_output(2)
    cocotb.log.info("[TEST] Phase 2: Corner address test (write + verify)")
    cocotb.log.info("[TEST]   -> FIRST word (0x000) = 0xDEADBEEF")
    cocotb.log.info("[TEST]   -> LAST word (0x3FF) = 0xCAFEBABE")
    await ClockCycles(caravelEnv.clk, 5)

    await vgpio.wait_output(3)
    cocotb.log.info("[TEST] Phase 3: Boundary address test (write + verify)")
    cocotb.log.info("[TEST]   -> Mid-point: 511/512, Quarter: 255/256, 767/768")
    await ClockCycles(caravelEnv.clk, 5)

    await vgpio.wait_output(4)
    cocotb.log.info("[TEST] Phase 4: Walking ones pattern (write + verify)")
    cocotb.log.info("[TEST]   -> 32 patterns: 0x00000001 to 0x80000000")
    await ClockCycles(caravelEnv.clk, 10)

    await vgpio.wait_output(5)
    cocotb.log.info("[TEST] Phase 5: Walking zeros pattern (write + verify)")
    cocotb.log.info("[TEST]   -> 32 patterns: 0xFFFFFFFE to 0x7FFFFFFF")
    await ClockCycles(caravelEnv.clk, 10)

    await vgpio.wait_output(6)
    cocotb.log.info("[TEST] Phase 6: Alternating patterns (write + verify)")
    cocotb.log.info("[TEST]   -> 0xAAAAAAAA / 0x55555555")
    await ClockCycles(caravelEnv.clk, 10)

    await vgpio.wait_output(7)
    cocotb.log.info("[TEST] Phase 7: Byte-level patterns (write + verify)")
    cocotb.log.info("[TEST]   -> 0x12345678, 0x9ABCDEF0, 0xFEDCBA98, 0x76543210")
    await ClockCycles(caravelEnv.clk, 5)

    await vgpio.wait_output(8)
    cocotb.log.info("[TEST] Phase 8: Nibble-level patterns (write + verify)")
    cocotb.log.info("[TEST]   -> 0xF0F0F0F0, 0x0F0F0F0F, 0xCCCCCCCC, 0x33333333")
    await ClockCycles(caravelEnv.clk, 5)


    await vgpio.wait_output(9)
    cocotb.log.info("[TEST] Phase 9: Byte lane test (write + verify)")
    cocotb.log.info("[TEST]   -> Individual bytes: 0x12, 0x34, 0x56, 0x78")
    cocotb.log.info("[TEST]   -> Expected result: 0x12345678")
    await ClockCycles(caravelEnv.clk, 5)

    await vgpio.wait_output(10)
    cocotb.log.info("[TEST] Phase 10: All zeros pattern (write + verify)")
    cocotb.log.info("[TEST]   -> Clear entire SRAM: 0x00000000")
    await ClockCycles(caravelEnv.clk, 50)

    await vgpio.wait_output(11)
    cocotb.log.info("[TEST] Phase 11: All ones pattern (write + verify)")
    cocotb.log.info("[TEST]   -> Set entire SRAM: 0xFFFFFFFF")
    await ClockCycles(caravelEnv.clk, 50)

    await vgpio.wait_output(15)
    cocotb.log.info("[TEST] Phase 15: Data retention check")
    cocotb.log.info("[TEST]   -> Verify corner addresses persist after operations")
    await ClockCycles(caravelEnv.clk, 5)

    await vgpio.wait_output(17)
    cocotb.log.info("[TEST] Phase 17: Halfword (16-bit) access test (write + verify)")
    cocotb.log.info("[TEST]   -> Individual halfwords: 0x5678, 0x1234")
    cocotb.log.info("[TEST]   -> Expected result: 0x12345678")
    await ClockCycles(caravelEnv.clk, 5)

    await vgpio.wait_output(18)
