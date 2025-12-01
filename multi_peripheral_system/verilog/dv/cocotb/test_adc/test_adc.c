#include <firmware_apis.h>

#define ADC_BASE 0x30180000

// Register offsets
#define ADC_DATA      (ADC_BASE + 0x00)
#define ADC_CTRL      (ADC_BASE + 0x04)
#define ADC_STATUS    (ADC_BASE + 0x08)
#define ADC_CFG       (ADC_BASE + 0x0C)
#define ADC_THRESHOLD (ADC_BASE + 0x10)

// Control register bits
#define ADC_CTRL_START      (1 << 0)
#define ADC_CTRL_CONTINUOUS (1 << 1)
#define ADC_CTRL_ENABLE     (1 << 2)

// Status register bits
#define ADC_STATUS_DONE (1 << 0)
#define ADC_STATUS_BUSY (1 << 1)

static inline void adc_write_reg(uint32_t addr, uint32_t val)
{
    *((volatile uint32_t *)addr) = val;
}

static inline uint32_t adc_read_reg(uint32_t addr)
{
    return *((volatile uint32_t *)addr);
}

void main(void)
{
    enableHkSpi(false);
    GPIOs_loadConfigs();
    User_enableIF();

    vgpio_write_output(1);

    // Enable ADC
    adc_write_reg(ADC_CTRL, ADC_CTRL_ENABLE);
    
    // Configure sample width (default = 8)
    adc_write_reg(ADC_CFG, 8);

    vgpio_write_output(2);

    // Start single conversion
    adc_write_reg(ADC_CTRL, ADC_CTRL_ENABLE | ADC_CTRL_START);

    // Wait for conversion to complete
    uint32_t timeout = 10000;
    uint32_t status;
    while (timeout > 0) {
        status = adc_read_reg(ADC_STATUS);
        if (status & ADC_STATUS_DONE) {
            break;
        }
        timeout--;
    }

    vgpio_write_output(3);

    // Read ADC data
    uint32_t adc_value = adc_read_reg(ADC_DATA) & 0xFFF;  // 12-bit data
    
    // Output the ADC value through vgpio (lower 16 bits)
    vgpio_write_output(adc_value & 0xFFFF);

    // Perform multiple conversions
    for (int i = 0; i < 5; i++) {
        adc_write_reg(ADC_CTRL, ADC_CTRL_ENABLE | ADC_CTRL_START);
        
        timeout = 10000;
        while (timeout > 0) {
            status = adc_read_reg(ADC_STATUS);
            if (status & ADC_STATUS_DONE) {
                break;
            }
            timeout--;
        }
        
        adc_value = adc_read_reg(ADC_DATA) & 0xFFF;
    }

    vgpio_write_output(5);

    // Disable ADC
    adc_write_reg(ADC_CTRL, 0);

    vgpio_write_output(6);

    while (1) {}
}
