"""
VirtualGPIOModel - Helper class for firmware/testbench synchronization via virtual GPIO

This module provides a mechanism for firmware running on the Caravel management SoC
to communicate with the cocotb testbench through the logic analyzer (LA) probes.

The firmware writes values using vgpio_write_output() which maps to LA writes,
and the testbench reads these values to coordinate test milestones.
"""

import cocotb
from cocotb.triggers import Edge, RisingEdge
import threading


class VirtualGPIOModel:
    """Virtual GPIO model for firmware/testbench communication"""
    
    def __init__(self, caravelEnv):
        """
        Initialize VirtualGPIOModel
        
        Args:
            caravelEnv: Caravel test environment from test_configure()
        """
        self.caravelEnv = caravelEnv
        self.dut = caravelEnv.dut
        self.current_value = 0
        self.monitor_task = None
        self._stop = False
        
    def start(self):
        """Start monitoring the virtual GPIO signals"""
        self.monitor_task = cocotb.start_soon(self._monitor())
        
    async def _monitor(self):
        """Background task to monitor LA probes for vgpio changes"""
        while not self._stop:
            try:
                # Monitor the LA probes that firmware uses for vgpio_write_output()
                # Typically uses la_data_in[31:0] or similar
                # Wait for any change
                await Edge(self.dut.uut.mprj.la_data_in)
                
                # Read the current value
                # The lower 32 bits are typically used for vgpio
                la_value = int(self.dut.uut.mprj.la_data_in.value)
                self.current_value = la_value & 0xFFFFFFFF
                
            except Exception as e:
                # Ignore errors during shutdown
                if not self._stop:
                    cocotb.log.warning(f"VirtualGPIO monitor error: {e}")
                break
                
    def read_current(self):
        """
        Read the current virtual GPIO value
        
        Returns:
            int: Current 32-bit value written by firmware
        """
        try:
            la_value = int(self.dut.uut.mprj.la_data_in.value)
            self.current_value = la_value & 0xFFFFFFFF
        except:
            pass
        return self.current_value
        
    async def wait_output(self, expected_value, timeout_cycles=100000):
        """
        Wait for the virtual GPIO to reach a specific value
        
        Args:
            expected_value: The value to wait for
            timeout_cycles: Maximum clock cycles to wait
            
        Raises:
            AssertionError: If timeout occurs before expected value is seen
        """
        cocotb.log.debug(f"Waiting for vgpio={expected_value:#x}")
        
        for cycle in range(timeout_cycles):
            current = self.read_current()
            if current == expected_value:
                cocotb.log.debug(f"vgpio reached {expected_value:#x} after {cycle} cycles")
                return
                
            await RisingEdge(self.caravelEnv.clk)
            
        # Timeout
        current = self.read_current()
        cocotb.log.error(
            f"Timeout waiting for vgpio={expected_value:#x}. "
            f"Current value: {current:#x}"
        )
        raise AssertionError(
            f"Timeout: vgpio did not reach {expected_value:#x} "
            f"(stuck at {current:#x})"
        )
        
    def stop(self):
        """Stop the monitoring task"""
        self._stop = True
        if self.monitor_task:
            self.monitor_task.kill()
