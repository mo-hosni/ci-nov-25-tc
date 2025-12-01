# Integration Notes

## System Overview

This document provides technical integration details for the multi-peripheral Caravel user project.

### Design Hierarchy

```
user_project_wrapper (Caravel interface)
  └── user_project (Wishbone slave, top-level integration)
        ├── wishbone_bus_splitter (27 peripherals)
        ├── PWM instances (12× CF_TMR32_WB)
        ├── UART instances (8× CF_UART_WB)
        ├── SPI instance (1× CF_SPI_WB)
        ├── I2C instance (1× EF_I2C_WB)
        ├── SRAM instances (2× CF_SRAM_1024x32)
        ├── ADC instance (1× adc_wb_wrapper)
        └── PIC (WB_PIC)
```

---

## Clock and Reset

### Clock Domain
- **Single clock domain**: All logic operates on `wb_clk_i`
- **Clock source**: Caravel management SoC
- **Target frequency**: 25 MHz (40ns period)
- **No clock gating**: All peripherals run continuously when enabled

### Reset Strategy
- **Reset signal**: `wb_rst_i` (synchronous, active-high)
- **Reset source**: Caravel management SoC
- **Reset behavior**: All registers initialize to 0x00000000
- **Reset distribution**: Direct fanout to all peripheral instances

**Important**: No asynchronous reset used; all flops use synchronous reset only.

---

## Wishbone Bus Architecture

### Bus Parameters
- **Protocol**: Wishbone B4 Classic
- **Data width**: 32 bits
- **Address width**: 32 bits
- **Byte lanes**: 4 (`wbs_sel_i[3:0]`)
- **Endianness**: Little-endian

### Bus Timing
- **Single-cycle read latency**: ACK asserted one cycle after valid request
- **No wait states**: All peripherals respond in one cycle
- **Pipelined transactions**: Not supported (classic protocol)

### Address Decoding
```
wbs_adr_i[31:0]:
  [31:21] = 0x600 (user project base: 0x3000_0000)
  [20:16] = Peripheral select (0-26)
  [15:2]  = Register offset within peripheral
  [1:0]   = Byte offset (always 2'b00 for word-aligned)
```

**Peripheral Select Mapping**:
```
0-11:  PWM0-PWM11
12-19: UART0-UART7
20:    SPI0
21:    I2C0
22-23: SRAM0-SRAM1
24:    ADC0
25:    PIC
26:    Reserved (returns error)
```

### Bus Splitter Configuration
```verilog
wishbone_bus_splitter #(
    .NUM_PERIPHERALS(27),      // Non-power-of-2 for error detection
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32),
    .SEL_WIDTH(4),
    .ADDR_SEL_LOW_BIT(16)      // Use bits [20:16] for selection
) bus_splitter (
    // Master interface from Caravel
    .m_wb_clk_i(wb_clk_i),
    .m_wb_rst_i(wb_rst_i),
    .m_wb_adr_i(wbs_adr_i),
    // ... other connections
);
```

---

## Interrupt System

### Interrupt Controller (PIC)
- **Type**: Programmable Interrupt Controller (WB_PIC)
- **IRQ sources**: 16 inputs (currently using 23 for 23 peripherals)
- **Priority levels**: 4 (0=highest, 3=lowest)
- **Trigger modes**: Edge (rising) or level (high), per-IRQ configurable
- **Output**: Single `irq_out` signal

### IRQ Mapping
```
IRQ[0-11]:  PWM0-PWM11 interrupts
IRQ[12-19]: UART0-UART7 interrupts
IRQ[20]:    SPI0 interrupt
IRQ[21]:    I2C0 interrupt
IRQ[22]:    ADC0 interrupt
IRQ[23-15]: Reserved
```

### IRQ Connection to Caravel
```verilog
// Single consolidated IRQ output
assign user_irq[2] = pic_irq_out;
assign user_irq[1] = 1'b0;  // Unused
assign user_irq[0] = 1'b0;  // Unused
```

### IRQ Handling Flow
1. Peripheral asserts its IRQ line
2. PIC latches the interrupt (if enabled)
3. PIC evaluates priority and outputs `irq_out`
4. Caravel CPU services interrupt
5. Firmware reads PIC status to identify source
6. Firmware writes to peripheral IC register (W1C) to clear
7. Firmware writes to PIC IRQ_CLEAR to clear PIC latch

---

## Peripheral Integration Details

### PWM (CF_TMR32)
- **IP version**: v1.1.0
- **Instances**: 12
- **Wishbone wrapper**: Included in IP package
- **Clock**: `wb_clk_i` (25 MHz)
- **PWM frequency**: Configurable via PRD register
- **Output**: Single PWM signal per instance
- **IRQ sources**: Timer overflow, compare match, input capture

**Integration**:
```verilog
CF_TMR32_WB pwm0 (
    .clk(wb_clk_i),
    .rst_n(~wb_rst_i),  // IP uses active-low reset internally
    .wb_adr_i(s_wb_adr_o[0*32 +: 32]),
    .wb_dat_i(s_wb_dat_o[0*32 +: 32]),
    .wb_dat_o(s_wb_dat_i[0*32 +: 32]),
    .wb_sel_i(s_wb_sel_o[0*4 +: 4]),
    .wb_cyc_i(s_wb_cyc_o[0]),
    .wb_stb_i(s_wb_stb_o[0]),
    .wb_we_i(s_wb_we_o[0]),
    .wb_ack_o(s_wb_ack_i[0]),
    .pwm_out(pwm0_out),
    .irq(pwm0_irq)
);
```

### UART (CF_UART)
- **IP version**: v2.0.1
- **Instances**: 8
- **Wishbone wrapper**: Included in IP package
- **Baud rate**: Configurable via prescaler
- **Data format**: 8N1 (8 data bits, no parity, 1 stop bit)
- **FIFO**: Optional (check IP documentation)
- **IRQ sources**: RX ready, TX empty, frame error, overrun

**Pad Connections**: TX and RX on separate pins (never same pin!)

### SPI (CF_SPI)
- **IP version**: v2.0.1
- **Mode**: Master only
- **Clock modes**: All four SPI modes supported
- **Data width**: 8 bits per transfer
- **Slave select**: Single SS line (multi-slave via firmware)
- **IRQ sources**: Transfer complete, RX ready

### I2C (EF_I2C)
- **IP version**: v1.1.0
- **Mode**: Master/Slave
- **Speed**: Standard (100 kHz), Fast (400 kHz)
- **Clock stretching**: Supported
- **Multi-master**: Arbitration supported
- **IRQ sources**: Transfer complete, address match, arbitration lost

**Special**: SDA uses open-drain on analog_io[0] for bidirectional signaling.

### SRAM (CF_SRAM_1024x32)
- **IP version**: v1.2.0
- **Type**: Hard macro (pre-hardened)
- **Capacity**: 4 KB (1024 words × 32 bits)
- **Instances**: 2 (total 8 KB)
- **Access**: Single-cycle read/write via Wishbone
- **No IRQ**: Memory-mapped only

**PnR Note**: SRAM instances are placed as hard macros in user_project_wrapper.

### ADC (sky130_ef_ip__adc3v_12bit)
- **Repository**: https://github.com/nativechips/sky130_ef_ip__adc3v_12bit
- **Netlist**: ADC_TOP.pnl.v (pre-synthesized analog macro)
- **Controller**: sar_ctrl.v (digital SAR controller)
- **Resolution**: 12 bits
- **Input**: Analog signal on analog_io[16] (GPIO23)
- **Conversion time**: TBD (check datasheet)
- **IRQ**: Conversion complete

**Custom Wrapper**: `adc_wb_wrapper.v` wraps sar_ctrl and provides Wishbone interface.

---

## IP Linking (ipm_linker)

### Setup
1. Create `ip/` directory in project root
2. Copy `/nc/agent_tools/ipm_linker/link_IPs.json` template
3. Edit `link_IPs.json` to specify required IPs
4. Run ipm_linker tool

### link_IPs.json Example
```json
{
  "ips": [
    {
      "name": "CF_TMR32",
      "version": "v1.1.0",
      "mount_path": "ip/CF_TMR32"
    },
    {
      "name": "CF_UART",
      "version": "v2.0.1",
      "mount_path": "ip/CF_UART"
    },
    {
      "name": "CF_SPI",
      "version": "v2.0.1",
      "mount_path": "ip/CF_SPI"
    },
    {
      "name": "EF_I2C",
      "version": "v1.1.0",
      "mount_path": "ip/EF_I2C"
    },
    {
      "name": "CF_SRAM_1024x32",
      "version": "v1.2.0",
      "mount_path": "ip/CF_SRAM_1024x32"
    }
  ]
}
```

### Linking Command
```bash
python /nc/agent_tools/ipm_linker/ipm_linker.py \
  --file /workspace/ci-nov-25-tc/multi_peripheral_system/ip/link_IPs.json \
  --project-root /workspace/ci-nov-25-tc/multi_peripheral_system
```

---

## Simulation and Verification

### Cocotb Tests
Tests are located in `verilog/dv/cocotb/<test_name>/`

**Test Structure**:
- `<test_name>.py` - Cocotb testbench (Python)
- `<test_name>.c` - Firmware for test (C)
- `cocotb_tests.py` - Test runner configuration
- `design_info.yaml` - Design metadata for caravel-cocotb

### Running Caravel-Cocotb Tests
```bash
cd verilog/dv/cocotb
caravel-cocotb-runner --testcase=<test_name>
```

**Test Categories**:
1. **Individual peripheral tests**: One test per peripheral type
   - pwm_test: Verify PWM frequency and duty cycle
   - uart_test: Loopback test for all 8 UARTs
   - spi_test: SPI transfer test
   - i2c_test: I2C read/write operations
   - sram_test: Memory read/write test
   - adc_test: ADC conversion test
   - pic_test: Interrupt priority and masking

2. **System integration test**: `system_test`
   - Tests all peripherals together
   - Verifies address decoding
   - Checks IRQ routing
   - Performance benchmarking

### Waveform Analysis
- **Format**: VCD (Value Change Dump)
- **Location**: `sim/<test_name>/dump.vcd`
- **Viewer**: GTKWave or Surfer

---

## Synthesis and Linting

### Verilator Lint
```bash
verilator --lint-only --Wall --Wno-EOFNEWLINE \
  -I./verilog/rtl \
  -I./ip/CF_TMR32/hdl \
  -I./ip/CF_UART/hdl \
  ./verilog/rtl/user_project.v
```

### Yosys Synthesis
```bash
yosys -s syn/yosys.ys
```

**Synthesis Checks**:
- No inferred latches
- No combinational loops
- No unconnected signals
- Resource utilization report

---

## Physical Implementation (OpenLane)

### Two-Stage Flow
1. **Stage 1**: Harden individual macros (if needed)
2. **Stage 2**: Integrate into user_project_wrapper

### user_project_wrapper Configuration
Located in `openlane/user_project_wrapper/config.json`

**Key Settings**:
- `DESIGN_NAME`: "user_project_wrapper"
- `FP_PDN_MULTILAYER`: false
- `CLOCK_PORT`: "wb_clk_i"
- `CLOCK_PERIOD`: 40 (25 MHz)
- `MACROS`: Defines all hard macros (SRAM, ADC, etc.)

### Running OpenLane
```bash
openlane /workspace/ci-nov-25-tc/multi_peripheral_system/openlane/user_project_wrapper/config.json \
  --ef-save-views-to /workspace/ci-nov-25-tc/multi_peripheral_system
```

**Outputs**:
- `gds/user_project_wrapper.gds` - Final GDSII layout
- `lef/user_project_wrapper.lef` - Abstract view
- `verilog/gl/user_project_wrapper.v` - Gate-level netlist
- `spef/` - Parasitic extraction files
- `lib/` - Timing libraries

---

## Troubleshooting

### Common Issues

**Issue**: Wishbone bus hangs (no ACK)
- **Cause**: Peripheral not responding or invalid address
- **Fix**: Check address decode logic, verify CYC/STB routing

**Issue**: Interrupt not firing
- **Cause**: IRQ not enabled in PIC or peripheral
- **Fix**: Write to peripheral IM register and PIC IRQ_ENABLE

**Issue**: I2C communication fails
- **Cause**: SDA/SCL not properly configured as open-drain
- **Fix**: Verify mprj_io_oeb logic (active-low!)

**Issue**: SRAM read returns garbage
- **Cause**: Address not word-aligned or wrong byte lanes
- **Fix**: Ensure address [1:0] = 2'b00 and wbs_sel_i = 4'b1111

**Issue**: ADC always returns 0
- **Cause**: Analog input not connected or ADC not enabled
- **Fix**: Check analog_io[16] connection, set ADC CTRL[2] = 1

### Debugging Tools
- **Waveform inspection**: Use GTKWave to trace Wishbone signals
- **Firmware prints**: Use UART or memory-mapped status registers
- **Logic analyzer**: Caravel LA probes can monitor internal signals
- **Vector database**: Query `query_docs_db()` for error messages

---

## Design Constraints

### Area
- **User project area**: ~3000 µm × 3600 µm
- **SRAM hard macros**: ~150 µm × 150 µm each
- **Peripheral logic**: Depends on synthesis

### Timing
- **Target frequency**: 25 MHz (40ns period)
- **Setup margin**: Aim for 20% margin (8ns)
- **Hold margin**: Must meet hold time on all paths

### Power
- **Domains**: vccd1/vssd1 or vccd2/vssd2 (choose consistently)
- **Decoupling**: Handled by PDN in OpenLane
- **No power gating**: All peripherals always powered

---

## Acceptance Checklist

Before declaring the design complete, verify:

- [ ] All 27 peripherals instantiated correctly
- [ ] Wishbone bus splitter configured with NUM_PERIPHERALS=27
- [ ] Address map matches specification (no overlaps)
- [ ] All peripherals respond with ACK within one cycle
- [ ] Invalid addresses return 0xDEADBEEF on read
- [ ] IRQs routed to PIC correctly (23 sources)
- [ ] PIC outputs to user_irq[2:0]
- [ ] All pad assignments match pad_map.md
- [ ] I2C uses open-drain signaling
- [ ] UART TX and RX on different pads
- [ ] ADC input connected to analog_io[16]
- [ ] No latches in synthesis
- [ ] Verilator lint-clean (--Wno-EOFNEWLINE)
- [ ] All cocotb tests pass (individual + system)
- [ ] Gate-level simulation passes
- [ ] OpenLane completes without DRC/LVS errors
- [ ] Timing analysis shows positive slack
- [ ] Documentation complete (register_map, pad_map, this file)

---

**Last Updated**: 2025-12-01
