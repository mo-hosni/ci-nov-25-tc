# Pad Map

## Overview

This document defines the GPIO pad assignments for all peripherals in the multi-peripheral Caravel user project.

**Total Available Pads**: 38 (`mprj_io[37:0]`)  
**Reserved Pads**: `mprj_io[4:0]` (avoid using)  
**Usable Pads**: `mprj_io[37:5]` (33 pads)

## Pad Assignment Summary

| Peripheral | Instance | Signals | Pad Range | Count |
|-----------|----------|---------|-----------|-------|
| **PWM** | 0-11 | pwm_out | `mprj_io[17:6]` | 12 |
| **UART** | 0-7 | tx, rx | `mprj_io[33:18]` | 16 (8×2) |
| **SPI** | 0 | sck, mosi, miso, ss | `mprj_io[37:34]` | 4 |
| **I2C** | 0 | scl, sda | `mprj_io[5], mprj_io[4]` | 2 |
| **ADC** | 0 | adc_in | `analog_io[16]` (GPIO23) | 1 |

**Note**: I2C SDA and SCL use mprj_io digital pads for bidirectional open-drain signaling.

---

## Detailed Pad Assignments

### PWM Controllers (12 instances)

Each PWM controller outputs one PWM signal.

| Instance | Signal | Pad | Direction | Type |
|---------|--------|-----|-----------|------|
| PWM0 | pwm_out | `mprj_io[6]` | Output | Push-Pull |
| PWM1 | pwm_out | `mprj_io[7]` | Output | Push-Pull |
| PWM2 | pwm_out | `mprj_io[8]` | Output | Push-Pull |
| PWM3 | pwm_out | `mprj_io[9]` | Output | Push-Pull |
| PWM4 | pwm_out | `mprj_io[10]` | Output | Push-Pull |
| PWM5 | pwm_out | `mprj_io[11]` | Output | Push-Pull |
| PWM6 | pwm_out | `mprj_io[12]` | Output | Push-Pull |
| PWM7 | pwm_out | `mprj_io[13]` | Output | Push-Pull |
| PWM8 | pwm_out | `mprj_io[14]` | Output | Push-Pull |
| PWM9 | pwm_out | `mprj_io[15]` | Output | Push-Pull |
| PWM10 | pwm_out | `mprj_io[16]` | Output | Push-Pull |
| PWM11 | pwm_out | `mprj_io[17]` | Output | Push-Pull |

**Connection Example**:
```verilog
// PWM0 output
assign mprj_io_out[6] = pwm0_out;
assign mprj_io_oeb[6] = 1'b0;  // Enable output
```

---

### UART Controllers (8 instances)

Each UART controller has TX (output) and RX (input) signals.

| Instance | Signal | Pad | Direction | Type |
|---------|--------|-----|-----------|------|
| UART0 | tx | `mprj_io[18]` | Output | Push-Pull |
| UART0 | rx | `mprj_io[19]` | Input | - |
| UART1 | tx | `mprj_io[20]` | Output | Push-Pull |
| UART1 | rx | `mprj_io[21]` | Input | - |
| UART2 | tx | `mprj_io[22]` | Output | Push-Pull |
| UART2 | rx | `mprj_io[23]` | Input | - |
| UART3 | tx | `mprj_io[24]` | Output | Push-Pull |
| UART3 | rx | `mprj_io[25]` | Input | - |
| UART4 | tx | `mprj_io[26]` | Output | Push-Pull |
| UART4 | rx | `mprj_io[27]` | Input | - |
| UART5 | tx | `mprj_io[28]` | Output | Push-Pull |
| UART5 | rx | `mprj_io[29]` | Input | - |
| UART6 | tx | `mprj_io[30]` | Output | Push-Pull |
| UART6 | rx | `mprj_io[31]` | Input | - |
| UART7 | tx | `mprj_io[32]` | Output | Push-Pull |
| UART7 | rx | `mprj_io[33]` | Input | - |

**Connection Example**:
```verilog
// UART0 TX (output)
assign mprj_io_out[18] = uart0_tx;
assign mprj_io_oeb[18] = 1'b0;  // Enable output

// UART0 RX (input)
assign uart0_rx = mprj_io_in[19];
assign mprj_io_out[19] = 1'b0;
assign mprj_io_oeb[19] = 1'b1;  // Disable output (input mode)
```

**Important**: TX and RX must be on different pads to avoid conflicts.

---

### SPI Controller (1 instance)

| Instance | Signal | Pad | Direction | Type |
|---------|--------|-----|-----------|------|
| SPI0 | sck | `mprj_io[34]` | Output | Push-Pull |
| SPI0 | mosi | `mprj_io[35]` | Output | Push-Pull |
| SPI0 | miso | `mprj_io[36]` | Input | - |
| SPI0 | ss | `mprj_io[37]` | Output | Push-Pull |

**Connection Example**:
```verilog
// SPI outputs
assign mprj_io_out[34] = spi0_sck;
assign mprj_io_oeb[34] = 1'b0;

assign mprj_io_out[35] = spi0_mosi;
assign mprj_io_oeb[35] = 1'b0;

assign mprj_io_out[37] = spi0_ss;
assign mprj_io_oeb[37] = 1'b0;

// SPI input
assign spi0_miso = mprj_io_in[36];
assign mprj_io_out[36] = 1'b0;
assign mprj_io_oeb[36] = 1'b1;
```

---

### I2C Controller (1 instance)

I2C uses bidirectional open-drain signaling. The SDA line requires special handling.

| Instance | Signal | Pad | Direction | Type |
|---------|--------|-----|-----------|------|
| I2C0 | scl | `mprj_io[5]` | Bidirectional | Open-Drain |
| I2C0 | sda | `analog_io[0]` | Bidirectional | Open-Drain |

**Connection Example**:
```verilog
// I2C SCL (open-drain)
assign i2c0_scl_in = mprj_io_in[5];
assign mprj_io_out[5] = 1'b0;  // Always drive low or release
assign mprj_io_oeb[5] = i2c0_scl_oe ? 1'b1 : 1'b0;  // 1=release (input), 0=drive low

// I2C SDA (open-drain on analog_io)
// Connect to analog_io[0] for bidirectional capability
assign i2c0_sda_in = analog_io_in[0];
assign analog_io_out[0] = 1'b0;
assign analog_io_oeb[0] = i2c0_sda_oe ? 1'b1 : 1'b0;
```

**Note**: 
- For I2C, `oe=1` means release the line (input/high-Z)
- For I2C, `oe=0` means drive the line low
- Never drive high explicitly; use external pull-ups

---

### ADC (1 instance)

The ADC input is an analog signal connected to the analog IO pad.

| Instance | Signal | Pad | Direction | Type |
|---------|--------|-----|-----------|------|
| ADC0 | adc_in | `analog_io[16]` (GPIO23) | Input | Analog |

**Connection**:
The ADC macro is connected directly to `analog_io[16]` at the top level. No mprj_io assignment needed; this is handled in the ADC netlist.

---

## Pad Configuration Guidelines

### Output-Only Pads (Push-Pull)
```verilog
assign mprj_io_out[N] = signal_out;
assign mprj_io_oeb[N] = 1'b0;  // Enable output driver
```

### Input-Only Pads
```verilog
assign signal_in = mprj_io_in[N];
assign mprj_io_out[N] = 1'b0;
assign mprj_io_oeb[N] = 1'b1;  // Disable output driver
```

### Bidirectional Pads (Open-Drain for I2C)
```verilog
assign signal_in = mprj_io_in[N];
assign mprj_io_out[N] = 1'b0;  // Always output 0 (or release)
assign mprj_io_oeb[N] = ~signal_oe;  // Active-low: 0=output, 1=input
```

**Note**: `mprj_io_oeb` is active-low (0 = output enabled, 1 = output disabled/input)

---

## Pad Usage Summary

```
mprj_io[37:34] - SPI (4 pads)
mprj_io[33:18] - UART (16 pads: 8 instances × 2 signals)
mprj_io[17:6]  - PWM (12 pads)
mprj_io[5]     - I2C SCL
mprj_io[4:0]   - Reserved (do not use)

analog_io[16]  - ADC input (GPIO23)
analog_io[0]   - I2C SDA
```

**Total Digital Pads Used**: 33 out of 33 available  
**Total Analog Pads Used**: 2 (analog_io[0], analog_io[16])

---

## Firmware Configuration Example

```c
// GPIO configuration (typically done in Caravel initialization)
// This is handled by user_project_wrapper RTL, but firmware
// may need to configure GPIO management registers

// Example: Read PWM output status
volatile uint32_t *gpio_out = (volatile uint32_t *)0x21000004;
uint32_t pwm_status = (*gpio_out >> 6) & 0xFFF;  // Read mprj_io[17:6]

// Example: Set UART TX high
*gpio_out |= (1 << 18);  // Set mprj_io[18] high
```

---

## Customization

To change pad assignments:

1. Edit `user_project_wrapper.v`
2. Update the `assign` statements for `mprj_io_out[]`, `mprj_io_oeb[]`, and peripheral inputs
3. Update this document to reflect changes
4. Verify no conflicts in pad usage

**Warning**: Changing pad assignments may require updating:
- Testbench stimulus files
- Firmware GPIO access code  
- PCB design (if applicable)

---

**Last Updated**: 2025-12-01
