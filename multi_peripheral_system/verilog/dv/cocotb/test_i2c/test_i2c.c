#include <firmware_apis.h>
#include "CF_I2C.h"

#define I2C_BASE 0x30150000
#define I2C0 ((CF_I2C_TYPE_PTR)I2C_BASE)

void main(void)
{
    enableHkSpi(false);

    // Configure I2C pins: SCL=5, SDA=4 (bidirectional open-drain)
    GPIOs_configure(5, GPIO_MODE_USER_STD_BIDIRECTIONAL);
    GPIOs_configure(4, GPIO_MODE_USER_STD_BIDIRECTIONAL);
    GPIOs_loadConfigs();

    User_enableIF();

    vgpio_write_output(1);

    // Enable and configure I2C
    CF_I2C_setGclkEnable(I2C0, 1);
    CF_I2C_enable(I2C0);
    CF_I2C_setPrescaler(I2C0, 50);  // Set prescaler for ~100kHz I2C

    vgpio_write_output(2);

    // Simple I2C write sequence to address 0x50 (typical EEPROM address)
    uint8_t slave_addr = 0x50;
    uint8_t test_data[] = {0x00, 0x11, 0x22, 0x33};

    // Start I2C transaction
    CF_I2C_start(I2C0);
    
    // Send slave address with write bit
    CF_I2C_writeData(I2C0, (slave_addr << 1) | 0x00);
    CF_I2C_waitBusy(I2C0);

    // Send test data bytes
    for (int i = 0; i < 4; i++) {
        CF_I2C_writeData(I2C0, test_data[i]);
        CF_I2C_waitBusy(I2C0);
    }

    // Stop I2C transaction
    CF_I2C_stop(I2C0);

    vgpio_write_output(3);

    // Disable I2C peripheral
    CF_I2C_disable(I2C0);

    vgpio_write_output(4);

    while (1) {}
}
