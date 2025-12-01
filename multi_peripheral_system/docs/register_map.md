# Register Map

## Address Space Overview

**Base Address**: `0x3000_0000`  
**Peripheral Window Size**: 64 KB (0x10000) per peripheral  
**Total Address Space**: 1.75 MB (0x001A_0000)

## Address Decode

The user project uses bits `[20:16]` of the Wishbone address bus for peripheral selection:

```
wbs_adr_i[31:0]
  [31:21] - Must be 0x600 (user project area)
  [20:16] - Peripheral select (0-26)
  [15:2]  - Register offset within peripheral
  [1:0]   - Byte offset (word-aligned)
```

## Global Address Map

| Peripheral | Instances | Base Address | End Address | Size | IRQ Lines |
|-----------|-----------|--------------|-------------|------|-----------|
| **PWM (CF_TMR32)** | 12 | `0x3000_0000` | `0x300B_FFFF` | 768 KB | 0-11 |
| **UART (CF_UART)** | 8 | `0x300C_0000` | `0x3013_FFFF` | 512 KB | 12-19 |
| **SPI (CF_SPI)** | 1 | `0x3014_0000` | `0x3014_FFFF` | 64 KB | 20 |
| **I2C (EF_I2C)** | 1 | `0x3015_0000` | `0x3015_FFFF` | 64 KB | 21 |
| **SRAM** | 2 | `0x3016_0000` | `0x3017_FFFF` | 128 KB | - |
| **ADC** | 1 | `0x3018_0000` | `0x3018_FFFF` | 64 KB | 22 |
| **PIC** | 1 | `0x3019_0000` | `0x3019_FFFF` | 64 KB | - |

---

## PWM Controllers (CF_TMR32)

**IP Core**: CF_TMR32 v1.1.0  
**Instances**: 12 (PWM0 - PWM11)  
**Base Addresses**:
- PWM0: `0x3000_0000`
- PWM1: `0x3001_0000`
- PWM2: `0x3002_0000`
- PWM3: `0x3003_0000`
- PWM4: `0x3004_0000`
- PWM5: `0x3005_0000`
- PWM6: `0x3006_0000`
- PWM7: `0x3007_0000`
- PWM8: `0x3008_0000`
- PWM9: `0x3009_0000`
- PWM10: `0x300A_0000`
- PWM11: `0x300B_0000`

### Register Map (per instance)

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | TMR | RW | 0x00000000 | Timer/Counter register |
| 0x04 | PRD | RW | 0x00000000 | Period register |
| 0x08 | TMRCMP0 | RW | 0x00000000 | Compare register 0 (PWM duty cycle) |
| 0x0C | TMRCMP1 | RW | 0x00000000 | Compare register 1 |
| 0x10 | CTRL | RW | 0x00000000 | Control register |
| 0x14 | CFG | RW | 0x00000000 | Configuration register |
| 0x18 | PWM0 | RW | 0x00000000 | PWM0 output configuration |
| 0x1C | PWM1 | RW | 0x00000000 | PWM1 output configuration |
| 0x20 | ICCTRL | RW | 0x00000000 | Input capture control |
| 0x24 | ICCFG | RW | 0x00000000 | Input capture configuration |
| 0x28 | ICCMP0 | RO | 0x00000000 | Input capture value 0 |
| 0x2C | ICCMP1 | RO | 0x00000000 | Input capture value 1 |
| 0xFC | IM | RW | 0x00000000 | Interrupt mask register |
| 0x100 | RIS | RO | 0x00000000 | Raw interrupt status |
| 0x104 | MIS | RO | 0x00000000 | Masked interrupt status |
| 0x108 | IC | W1C | 0x00000000 | Interrupt clear |

**IRQ Lines**: PWM0→IRQ0, PWM1→IRQ1, ..., PWM11→IRQ11

---

## UART Controllers (CF_UART)

**IP Core**: CF_UART v2.0.1  
**Instances**: 8 (UART0 - UART7)  
**Base Addresses**:
- UART0: `0x300C_0000`
- UART1: `0x300D_0000`
- UART2: `0x300E_0000`
- UART3: `0x300F_0000`
- UART4: `0x3010_0000`
- UART5: `0x3011_0000`
- UART6: `0x3012_0000`
- UART7: `0x3013_0000`

### Register Map (per instance)

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | RXDATA | RO | 0x00000000 | Receive data register |
| 0x04 | TXDATA | WO | 0x00000000 | Transmit data register |
| 0x08 | STATUS | RO | 0x00000000 | Status register |
| 0x0C | CTRL | RW | 0x00000000 | Control register |
| 0x10 | CFG | RW | 0x00000000 | Configuration register (baud rate, etc.) |
| 0x14 | PR | RW | 0x00000000 | Prescaler register |
| 0xFC | IM | RW | 0x00000000 | Interrupt mask |
| 0x100 | RIS | RO | 0x00000000 | Raw interrupt status |
| 0x104 | MIS | RO | 0x00000000 | Masked interrupt status |
| 0x108 | IC | W1C | 0x00000000 | Interrupt clear |

**IRQ Lines**: UART0→IRQ12, UART1→IRQ13, ..., UART7→IRQ19

---

## SPI Controller (CF_SPI)

**IP Core**: CF_SPI v2.0.1  
**Instance**: 1 (SPI0)  
**Base Address**: `0x3014_0000`

### Register Map

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | RXDATA | RO | 0x00000000 | Receive data register |
| 0x04 | TXDATA | WO | 0x00000000 | Transmit data register |
| 0x08 | STATUS | RO | 0x00000000 | Status register |
| 0x0C | CTRL | RW | 0x00000000 | Control register |
| 0x10 | CFG | RW | 0x00000000 | Configuration (clock div, mode) |
| 0x14 | SS | RW | 0x00000000 | Slave select control |
| 0xFC | IM | RW | 0x00000000 | Interrupt mask |
| 0x100 | RIS | RO | 0x00000000 | Raw interrupt status |
| 0x104 | MIS | RO | 0x00000000 | Masked interrupt status |
| 0x108 | IC | W1C | 0x00000000 | Interrupt clear |

**IRQ Line**: SPI0→IRQ20

---

## I2C Controller (EF_I2C)

**IP Core**: EF_I2C v1.1.0  
**Instance**: 1 (I2C0)  
**Base Address**: `0x3015_0000`

### Register Map

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | PRE | RW | 0x00000000 | Prescaler register |
| 0x04 | CTRL | RW | 0x00000000 | Control register |
| 0x08 | TXDATA | WO | 0x00000000 | Transmit data register |
| 0x0C | RXDATA | RO | 0x00000000 | Receive data register |
| 0x10 | CMD | WO | 0x00000000 | Command register |
| 0x14 | STATUS | RO | 0x00000000 | Status register |
| 0xFC | IM | RW | 0x00000000 | Interrupt mask |
| 0x100 | RIS | RO | 0x00000000 | Raw interrupt status |
| 0x104 | MIS | RO | 0x00000000 | Masked interrupt status |
| 0x108 | IC | W1C | 0x00000000 | Interrupt clear |

**IRQ Line**: I2C0→IRQ21

---

## SRAM (CF_SRAM_1024x32)

**IP Core**: CF_SRAM_1024x32 v1.2.0  
**Instances**: 2 (SRAM0, SRAM1)  
**Type**: Hard macro with Wishbone interface  
**Base Addresses**:
- SRAM0: `0x3016_0000` (4KB, 1024 words × 32 bits)
- SRAM1: `0x3017_0000` (4KB, 1024 words × 32 bits)

### Memory Map (per instance)

| Address Range | Size | Description |
|--------------|------|-------------|
| 0x0000 - 0x0FFF | 4 KB | SRAM data (1024 × 32-bit words) |

**Access**: Direct word-aligned read/write via Wishbone  
**IRQ**: None

---

## ADC (sky130_ef_ip__adc3v_12bit)

**IP Core**: sky130_ef_ip__adc3v_12bit  
**Instance**: 1 (ADC0)  
**Base Address**: `0x3018_0000`  
**Analog Input**: analog_io[16] (GPIO23)

### Register Map

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | DATA | RO | 0x00000000 | ADC conversion result [11:0] |
| 0x04 | CTRL | RW | 0x00000000 | Control register |
| 0x08 | STATUS | RO | 0x00000000 | Status register |
| 0x0C | CFG | RW | 0x00000000 | Configuration register |
| 0x10 | THRESHOLD | RW | 0x00000000 | Threshold for comparisons |
| 0xFC | IM | RW | 0x00000000 | Interrupt mask |
| 0x100 | RIS | RO | 0x00000000 | Raw interrupt status |
| 0x104 | MIS | RO | 0x00000000 | Masked interrupt status |
| 0x108 | IC | W1C | 0x00000000 | Interrupt clear |

**Control Register (CTRL) bits**:
- [0] - START: Start conversion
- [1] - CONTINUOUS: Continuous conversion mode
- [2] - ENABLE: ADC enable

**Status Register (STATUS) bits**:
- [0] - DONE: Conversion complete
- [1] - BUSY: Conversion in progress

**IRQ Line**: ADC0→IRQ22

---

## Programmable Interrupt Controller (PIC)

**Module**: WB_PIC  
**Instance**: 1  
**Base Address**: `0x3019_0000`  
**IRQ Sources**: 16 (expandable, currently using 23)

### Register Map

| Offset | Name | Access | Reset | Description |
|--------|------|--------|-------|-------------|
| 0x00 | IRQ_STATUS | RO | 0x00000000 | Current IRQ line status [15:0] |
| 0x04 | IRQ_PENDING | RO | 0x00000000 | Pending interrupts [15:0] |
| 0x08 | IRQ_ENABLE | RW | 0x00000000 | Per-IRQ enable mask [15:0] |
| 0x0C | GLOBAL_ENABLE | RW | 0x00000000 | Global interrupt enable [0] |
| 0x10 | IRQ_CLEAR | W1C | 0x00000000 | Clear latched IRQs [15:0] |
| 0x14 | IRQ_TYPE | RW | 0x00000000 | Trigger type: 0=level, 1=edge [15:0] |
| 0x18 | PRIORITY_0_3 | RW | 0x00000000 | Priority for IRQ0-3 (2 bits each) |
| 0x1C | PRIORITY_4_7 | RW | 0x00000000 | Priority for IRQ4-7 |
| 0x20 | PRIORITY_8_11 | RW | 0x00000000 | Priority for IRQ8-11 |
| 0x24 | PRIORITY_12_15 | RW | 0x00000000 | Priority for IRQ12-15 |

### IRQ Source Mapping

| IRQ Line | Source | Peripheral |
|---------|--------|------------|
| 0-11 | PWM0-11 | CF_TMR32 instances |
| 12-19 | UART0-7 | CF_UART instances |
| 20 | SPI0 | CF_SPI |
| 21 | I2C0 | EF_I2C |
| 22 | ADC0 | ADC controller |
| 23-15 | Reserved | Future use |

**Output**: Single consolidated `irq_out` signal → Caravel `user_irq[2:0]`

---

## Register Access Notes

### Read Behavior
- **Valid addresses**: Return register data
- **Invalid addresses**: Return `0xDEADBEEF`
- **RO registers**: Always return current value
- **WO registers**: Read returns 0x00000000

### Write Behavior
- **Valid addresses**: Update register
- **Invalid addresses**: ACK asserted, data discarded
- **RW registers**: Update all writable bits
- **RO registers**: Write ignored, ACK asserted
- **W1C registers**: Write 1 to clear corresponding bit

### Byte Lane Support
All peripherals support byte-lane writes via `wbs_sel_i[3:0]`:
- `wbs_sel_i[0]` = byte 0 [7:0]
- `wbs_sel_i[1]` = byte 1 [15:8]
- `wbs_sel_i[2]` = byte 2 [23:16]
- `wbs_sel_i[3]` = byte 3 [31:24]

---

## Firmware Access Example

```c
// Base addresses
#define PWM0_BASE    0x30000000
#define UART0_BASE   0x300C0000
#define SPI0_BASE    0x30140000
#define I2C0_BASE    0x30150000
#define SRAM0_BASE   0x30160000
#define ADC0_BASE    0x30180000
#define PIC_BASE     0x30190000

// Register offsets
#define CTRL_OFFSET  0x04
#define STATUS_OFFSET 0x08
#define IM_OFFSET    0xFC
#define IC_OFFSET    0x108

// Example: Configure PWM0
#define PWM0_CTRL    (*(volatile uint32_t*)(PWM0_BASE + 0x10))
#define PWM0_PRD     (*(volatile uint32_t*)(PWM0_BASE + 0x08))
#define PWM0_CMP0    (*(volatile uint32_t*)(PWM0_BASE + 0x08))

PWM0_PRD = 1000;          // Set period
PWM0_CMP0 = 500;          // 50% duty cycle
PWM0_CTRL = 0x01;         // Enable PWM
```

---

**Last Updated**: 2025-12-01

