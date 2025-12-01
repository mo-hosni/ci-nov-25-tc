# Verification Tests Overview

## Test Development Status

All verification tests have been created and are ready for execution. This document provides an overview of each test suite.

## Test Suite Summary

### 1. test_pwm - PWM/TMR32 Controller Test
**Location**: `verilog/dv/cocotb/test_pwm/`
**Purpose**: Verify PWM controller functionality
**Peripherals Tested**: PWM0-PWM3 (4 out of 12 instances)
**GPIO Pins**: 6, 7, 8, 9
**Base Addresses**: 
- PWM0: 0x3000_0000
- PWM1: 0x3001_0000
- PWM2: 0x3002_0000
- PWM3: 0x3003_0000

**Test Flow**:
1. Configure GPIOs for PWM output
2. Initialize PWM controllers with example configuration
3. Monitor PWM output signals on GPIOs
4. Verify PWM waveform generation

**Source**: Adapted from CF_TMR32 IP dv_example

---

### 2. test_uart - UART Controller Test
**Location**: `verilog/dv/cocotb/test_uart/`
**Purpose**: Verify UART transmit/receive functionality
**Peripherals Tested**: UART0
**GPIO Pins**: 
- TX: 18
- RX: 19
**Base Address**: 0x300C_0000

**Test Flow**:
1. Configure UART0 for 115200 baud
2. Enable transmitter and receiver
3. Send test pattern
4. Verify loopback or reception
5. Check UART status registers

**Source**: Adapted from CF_UART IP dv_example

---

### 3. test_spi - SPI Controller Test
**Location**: `verilog/dv/cocotb/test_spi/`
**Purpose**: Verify SPI master functionality
**Peripherals Tested**: SPI0
**GPIO Pins**:
- SCK: 37
- MOSI: 36
- MISO: 35
- SS: 34
**Base Address**: 0x3014_0000

**Test Flow**:
1. Configure SPI controller (CPOL=0, CPHA=0)
2. Set prescaler for desired clock rate
3. Assert chip select
4. Transmit test data bytes [0x55, 0xAA, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC]
5. Receive data bytes and verify
6. Deassert chip select

**Source**: Adapted from CF_SPI IP dv_example

---

### 4. test_i2c - I2C Controller Test
**Location**: `verilog/dv/cocotb/test_i2c/`
**Purpose**: Verify I2C master functionality
**Peripherals Tested**: I2C0
**GPIO Pins** (bidirectional):
- SCL: 5
- SDA: 4
**Base Address**: 0x3015_0000

**Test Flow**:
1. Configure I2C controller with prescaler for ~100kHz
2. Enable I2C peripheral
3. Generate START condition
4. Send slave address (0x50) with write bit
5. Send test data bytes [0x00, 0x11, 0x22, 0x33]
6. Generate STOP condition
7. Monitor bus activity and verify

**Source**: Created from scratch (no IP example available)

---

### 5. test_sram - SRAM Test
**Location**: `verilog/dv/cocotb/test_sram/`
**Purpose**: Verify SRAM read/write functionality
**Peripherals Tested**: SRAM0
**Base Addresses**:
- SRAM0: 0x3016_0000 (4KB)
- SRAM1: 0x3017_0000 (4KB)

**Test Flow**:
1. Write test patterns to various SRAM addresses
2. Read back and verify data
3. Test different access patterns (sequential, random)
4. Verify address space boundaries
5. Test byte-lane writes using wbs_sel_i

**Source**: Adapted from CF_SRAM_1024x32 IP dv_example

---

### 6. test_adc - ADC Test
**Location**: `verilog/dv/cocotb/test_adc/`
**Purpose**: Verify ADC conversion functionality
**Peripherals Tested**: ADC (12-bit sky130_ef_ip__adc3v_12bit)
**Analog Input**: analog_io[16] (GPIO23)
**Base Address**: 0x3018_0000

**Test Flow**:
1. Enable ADC peripheral
2. Configure sample width
3. Start single conversion
4. Wait for conversion complete (poll STATUS register)
5. Read 12-bit ADC data
6. Perform multiple conversions
7. Verify data is within valid range (0x000-0xFFF)

**Register Map**:
- ADC_DATA (0x00): 12-bit conversion result
- ADC_CTRL (0x04): Control register (START, CONTINUOUS, ENABLE)
- ADC_STATUS (0x08): Status register (DONE, BUSY)
- ADC_CFG (0x0C): Sample width configuration
- ADC_THRESHOLD (0x10): Threshold value

**Source**: Created from scratch (no IP example available)

---

### 7. test_system - System Integration Test
**Location**: `verilog/dv/cocotb/test_system/`
**Purpose**: Comprehensive system-level test of all peripherals
**Peripherals Tested**: All (PWM, UART, SPI, I2C, SRAM, ADC)

**Test Flow**:
1. **GPIO Configuration** (vgpio=1)
   - Configure all GPIO pins for their respective peripherals
   - Load GPIO configurations
   
2. **PWM Initialization** (vgpio=2)
   - Configure PWM0 and PWM1 with example settings
   
3. **UART Initialization** (vgpio=3)
   - Configure UART0 and UART1 for 115200 baud
   - Enable TX/RX
   
4. **SPI Initialization** (vgpio=4)
   - Configure SPI0 with CPOL=0, CPHA=0
   
5. **I2C Initialization** (vgpio=5)
   - Configure I2C0 for ~100kHz operation
   
6. **SRAM Test** (vgpio=6)
   - Write/read test patterns to SRAM0 and SRAM1
   - Verify data integrity
   
7. **ADC Enable** (vgpio=7)
   - Enable ADC peripheral
   
8. **UART Communication** (vgpio=8)
   - Send "SYS\n" message via UART0
   - System test complete

**Verification Points**:
- All peripherals initialize successfully
- No bus conflicts or acknowledgment timeouts
- SRAM data integrity verified
- UART message transmission verified
- All milestones reached in proper sequence

**Source**: Created specifically for system-level integration testing

---

## Test Infrastructure

### VirtualGPIOModel.py
Helper class for firmware/testbench synchronization via Logic Analyzer (LA) probes.

**Features**:
- Background monitoring of LA data
- Wait for specific vgpio values (milestones)
- Read current vgpio value
- Timeout handling with error reporting

**Usage**:
```python
vgpio = VirtualGPIOModel(caravelEnv)
vgpio.start()
await vgpio.wait_output(1)  # Wait for milestone 1
```

### design_info.yaml
Configuration file for caravel-cocotb test framework.

**Key Settings**:
- CARAVEL_ROOT: /nc/caravel
- USER_PROJECT_ROOT: /workspace/ci-nov-25-tc/multi_peripheral_system
- Clock period: 25ns (40MHz)
- Include paths for all IP cores and firmware drivers
- Test list with timeout configurations

### cocotb_tests.py
Main test collection module that imports all individual tests for execution.

---

## Running the Tests

### Prerequisites
- caravel-cocotb framework installed
- All IP cores linked via ipm_linker
- RTL files in place
- Firmware drivers available

### Execution Command
```bash
cd /workspace/ci-nov-25-tc/multi_peripheral_system/verilog/dv/cocotb
caravel-cocotb -test <test_name>
```

### Available Tests
- `test_pwm` - PWM controller test
- `test_uart` - UART controller test
- `test_spi` - SPI controller test
- `test_i2c` - I2C controller test
- `test_sram` - SRAM memory test
- `test_adc` - ADC conversion test
- `test_system` - System integration test

### Run All Tests
```bash
caravel-cocotb -test all
```

---

## Test Coverage

### Peripheral Coverage
| Peripheral | Instances | Tested | Coverage |
|-----------|-----------|--------|----------|
| PWM (CF_TMR32) | 12 | 4 | 33% (functional coverage) |
| UART (CF_UART) | 8 | 2 | 25% (functional coverage) |
| SPI (CF_SPI) | 1 | 1 | 100% |
| I2C (CF_I2C) | 1 | 1 | 100% |
| SRAM (4KB) | 2 | 2 | 100% |
| ADC (12-bit) | 1 | 1 | 100% |
| PIC (Interrupt) | 1 | 0 | 0% (not directly tested) |

**Note**: The system integration test exercises multiple instances of PWM and UART, providing broader coverage than individual tests.

### Wishbone Bus Coverage
- ✅ Single read transactions
- ✅ Single write transactions
- ✅ Byte-lane writes (wbs_sel_i)
- ✅ Multiple peripheral access
- ✅ Address decoding
- ✅ Acknowledgment handling
- ⚠️ Bus arbitration (single master, not applicable)
- ⚠️ Error responses (limited testing)

### GPIO/Pad Coverage
- ✅ Standard output mode
- ✅ Standard input mode (pull-up, no-pull)
- ✅ Bidirectional mode (I2C)
- ✅ Analog input (ADC)
- ✅ Multiple GPIO banks

---

## Expected Test Results

### Success Criteria
Each test should:
1. Complete all milestones (vgpio checkpoints)
2. Not timeout waiting for firmware
3. Verify peripheral-specific functionality
4. Generate proper waveforms on GPIO pins
5. Report "PASS" in final log message

### Common Failure Modes
1. **Wishbone timeout**: Bus not acknowledging transactions
2. **GPIO stuck**: Pins not toggling as expected
3. **Firmware hang**: vgpio milestone not reached
4. **Data mismatch**: Read data doesn't match written data
5. **Address decode error**: Wrong peripheral responding

### Debug Resources
- Waveform dumps (VCD files in sim/ directory)
- Cocotb log files
- Firmware compilation logs
- VirtualGPIO milestone tracking

---

## Next Steps

1. **Run test_pwm first** - Simplest test, verifies basic infrastructure
2. **Run individual peripheral tests** - Isolate any issues per peripheral
3. **Run test_system last** - Comprehensive integration verification
4. **Debug failures** - Use waveforms and logs to identify root causes
5. **Iterate and fix** - Update RTL/firmware as needed
6. **Document results** - Update this file with actual test results

---

## Test Development Notes

### PWM Test Updates
- Updated GPIO assignments from [5,8,11,14] to [6,7,8,9]
- Verified base addresses match register_map.md
- Preserved original TMR32 test logic

### UART Test Updates
- Updated UART0 base address from 0x30000000 to 0x300C0000
- Updated GPIO pins: TX=18, RX=19 (was TX=5, RX=6)
- Updated Python monitor pins to match

### SPI Test Updates
- Updated SPI0 base address from 0x30000000 to 0x30140000
- Updated GPIO pins: SCK=37, MOSI=36, MISO=35, SS=34
- Updated Python monitor signals to match

### SRAM Test Updates
- Updated SRAM0 base address from 0x30010000 to 0x30160000
- Verified 4KB memory size (1024 x 32-bit words)

### I2C Test (Created from Scratch)
- Used CF_I2C firmware driver API
- Implemented basic write transaction
- Monitor task checks for bus activity
- No external I2C slave model (loopback not possible)

### ADC Test (Created from Scratch)
- Implemented direct register access (no firmware driver)
- Simple single-conversion and multi-conversion tests
- Verifies 12-bit data range
- Analog input not driven in simulation (floating)

### System Test Design
- Exercises all peripherals in sequence
- Uses vgpio milestones for synchronization
- Includes SRAM data integrity check
- Sends UART message for end-to-end verification
- Comprehensive summary in Python test output

---

**Document Version**: 1.0
**Last Updated**: 2025-12-01
**Status**: Tests created, ready for execution
