# Multi-Peripheral Caravel User Project

## Initial User Requirement

**Date**: 2025-12-01

**Original Request**:
Create a Caravel design with the following peripherals:
- 12 PWM controllers
- 8 UART controllers
- 1 SPI controller
- 1 I2C controller
- 2 SRAM (4KB each)
- 1 ADC (12-bit, using sky130_ef_ip__adc3v_12bit)
  - ADC_TOP.pnl.v as the netlist
  - sar_ctrl.v as the controller
  - ADC input connected to GPIO23 (analog_io[16])

## Project Overview

This project implements a comprehensive multi-peripheral system integrated with the Caravel SoC harness. The design provides 24 peripheral instances accessible via Wishbone bus, with interrupt management through a programmable interrupt controller.

### Status: **In Progress - Project Setup Phase**

### Technology Stack
- **ASIC Platform**: Efabless Caravel (Skywater 130nm)
- **Bus Protocol**: Wishbone B4 Classic (32-bit)
- **RTL Language**: Verilog-2005
- **Verification**: Cocotb + Caravel-Cocotb framework
- **Physical Design**: OpenLane 2 (LibreLane)

## Architecture Overview

### Peripheral Count Summary
| Peripheral Type | Count | IP Source | Wishbone Wrapped |
|----------------|-------|-----------|------------------|
| PWM (CF_TMR32) | 12 | CF_TMR32 v1.1.0 | Yes |
| UART | 8 | CF_UART v2.0.1 | Yes |
| SPI | 1 | CF_SPI v2.0.1 | Yes |
| I2C | 1 | EF_I2C v1.1.0 | Yes |
| SRAM (4KB) | 2 | CF_SRAM_1024x32 v1.2.0 | Yes (Hard Macro) |
| ADC (12-bit) | 1 | sky130_ef_ip__adc3v_12bit | Custom |

**Total Peripherals**: 25 instances
**Total IRQ Sources**: 24 (one per peripheral, excluding SRAM)

### Address Map

Base address: `0x3000_0000`
Window size: 64 KB (0x10000) per peripheral

| Peripheral | Instance | Address Range | IRQ Line |
|-----------|----------|---------------|----------|
| PWM | 0-11 | 0x3000_0000 - 0x300B_FFFF | IRQ0-11 |
| UART | 0-7 | 0x300C_0000 - 0x3013_FFFF | IRQ12-19 |
| SPI | 0 | 0x3014_0000 - 0x3014_FFFF | IRQ20 |
| I2C | 0 | 0x3015_0000 - 0x3015_FFFF | IRQ21 |
| SRAM | 0-1 | 0x3016_0000 - 0x3017_FFFF | N/A |
| ADC | 0 | 0x3018_0000 - 0x3018_FFFF | IRQ22 |
| PIC | - | 0x3019_0000 - 0x3019_FFFF | N/A |

### System Block Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                     Caravel Management SoC                      │
│                    (Wishbone Master)                            │
└───────────────────────────┬────────────────────────────────────┘
                            │ Wishbone Bus
                            ↓
┌────────────────────────────────────────────────────────────────┐
│              user_project (Wishbone Slave)                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │          Wishbone Bus Splitter (27 peripherals)          │  │
│  │         (NUM_PERIPHERALS = 27, non-power-of-2)           │  │
│  └─┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬─┘  │
│    │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │    │
│    ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓    │
│  PWM0-11 (CF_TMR32)                                             │
│          UART0-7 (CF_UART)                                      │
│                  SPI0 (CF_SPI)                                  │
│                       I2C0 (EF_I2C)                             │
│                            SRAM0-1 (CF_SRAM_1024x32)            │
│                                     ADC0 (sky130_adc)           │
│                                          PIC (WB_PIC)           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │    Programmable Interrupt Controller (16 sources)        │  │
│  │              irq_out → user_irq[2:0]                     │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
                            │
                            ↓
┌────────────────────────────────────────────────────────────────┐
│              user_project_wrapper                               │
│              (mprj_io[37:0] pad connections)                    │
└────────────────────────────────────────────────────────────────┘
```

## Implementation Plan

### Phase 1: Project Setup ✅ (In Progress)
- [x] Copy Caravel user project template
- [x] Create project directory structure
- [x] Initialize documentation (README, register_map, pad_map, integration_notes)
- [ ] Set up IP linking with ipm_linker tool

### Phase 2: RTL Development
- [ ] Integrate 12 PWM peripherals (CF_TMR32)
- [ ] Integrate 8 UART peripherals (CF_UART)
- [ ] Integrate 1 SPI peripheral (CF_SPI)
- [ ] Integrate 1 I2C peripheral (EF_I2C)
- [ ] Integrate 2 SRAM (CF_SRAM_1024x32)
- [ ] Fetch and integrate ADC (sky130_ef_ip__adc3v_12bit)
- [ ] Implement Wishbone bus splitter integration
- [ ] Implement Programmable Interrupt Controller (PIC)
- [ ] Create user_project top-level module
- [ ] Create user_project_wrapper with pad assignments

### Phase 3: Verification
- [ ] Create individual peripheral tests (cocotb)
- [ ] Create system integration test
- [ ] Run caravel-cocotb verification suite
- [ ] Debug and fix any issues

### Phase 4: Documentation
- [ ] Complete register map documentation
- [ ] Complete pad map documentation
- [ ] Complete integration notes
- [ ] Create firmware scaffold with C headers
- [ ] Write final retrospective

## Current Status

**Phase**: Project Setup
**Progress**: 20%

### Completed
- Caravel template copied successfully
- Project directory structure created
- Initial README documentation created

### Next Steps
1. Create detailed documentation files (register_map.md, pad_map.md, integration_notes.md)
2. Set up IP linking for all required peripherals
3. Begin RTL development with peripheral integration

## Design Decisions

### Key Choices
1. **27 Peripheral Instances**: Using non-power-of-2 count enables automatic error detection for invalid addresses
2. **64KB Address Windows**: Provides sufficient space for each peripheral's register map
3. **Programmable Interrupt Controller**: Centralized IRQ management with priority levels
4. **Hard Macro SRAMs**: Use pre-hardened SRAM blocks for area/power efficiency
5. **ADC on Analog IO**: Connect ADC input to analog_io[16] (GPIO23) as specified

### Assumptions
- All peripherals use their default configurations from IP library
- Single clock domain (wb_clk_i) for all logic
- Synchronous active-high reset (wb_rst_i)
- ADC controller (sar_ctrl.v) requires custom Wishbone wrapper

## Repository Structure

```
multi_peripheral_system/
├── docs/                          # Project documentation
│   ├── register_map.md           # Register definitions
│   ├── pad_map.md                # GPIO/pad assignments
│   └── integration_notes.md      # Integration guide
├── ip/                            # Linked IP modules
│   └── link_IPs.json             # IPM linker configuration
├── verilog/
│   ├── rtl/                      # RTL source files
│   │   ├── user_project.v        # Top-level user project
│   │   ├── user_project_wrapper.v
│   │   ├── wishbone_bus_splitter.v
│   │   ├── WB_PIC.v
│   │   └── adc_wb_wrapper.v      # Custom ADC wrapper
│   ├── dv/                       # Design verification
│   │   └── cocotb/               # Cocotb testbenches
│   └── includes/                 # Include files
├── openlane/                     # OpenLane configurations
│   └── user_project_wrapper/
├── fw/                           # Firmware
└── README.md                     # This file
```

## References

- [Caravel Documentation](https://caravel-harness.readthedocs.io/)
- [Wishbone B4 Specification](https://opencores.org/howto/wishbone)
- [CF_TMR32 IP Documentation](/nc/ip/CF_TMR32)
- [CF_UART IP Documentation](/nc/ip/CF_UART)
- [CF_SPI IP Documentation](/nc/ip/CF_SPI)
- [EF_I2C IP Documentation](/nc/ip/EF_I2C)
- [CF_SRAM_1024x32 IP Documentation](/nc/ip/CF_SRAM_1024x32)

---

**Last Updated**: 2025-12-01
**Status**: Project Setup Phase
