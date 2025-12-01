#include <firmware_apis.h>
#include "CF_TMR32.h"
#include "CF_UART.h"
#include "CF_SPI.h"
#include "CF_I2C.h"

// Base addresses for all peripherals
#define PWM0_BASE   0x30000000
#define PWM1_BASE   0x30010000
#define UART0_BASE  0x300C0000
#define UART1_BASE  0x300D0000
#define SPI0_BASE   0x30140000
#define I2C0_BASE   0x30150000
#define SRAM0_BASE  0x30160000
#define SRAM1_BASE  0x30170000
#define ADC_BASE    0x30180000
#define PIC_BASE    0x30190000

#define PWM0 ((CF_TMR32_TYPE_PTR)PWM0_BASE)
#define PWM1 ((CF_TMR32_TYPE_PTR)PWM1_BASE)
#define UART0 ((CF_UART_TYPE_PTR)UART0_BASE)
#define UART1 ((CF_UART_TYPE_PTR)UART1_BASE)
#define SPI0 ((CF_SPI_TYPE_PTR)SPI0_BASE)
#define I2C0 ((CF_I2C_TYPE_PTR)I2C0_BASE)

// ADC register definitions
#define ADC_CTRL (ADC_BASE + 0x04)
#define ADC_CTRL_ENABLE (1 << 2)

static inline void CF_UART_setBaudRate_Hz(CF_UART_TYPE_PTR uart, uint32_t baud_rate, uint32_t clock_freq_hz)
{
    uint32_t prescaler = (clock_freq_hz / (baud_rate * 8)) - 1;
    CF_UART_setPrescaler(uart, prescaler);
}

void main(void)
{
    enableHkSpi(false);

    // Configure GPIOs for all peripherals
    // PWM0-1: GPIO 6,7
    GPIOs_configure(6, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(7, GPIO_MODE_USER_STD_OUTPUT);
    
    // UART0-1: TX=18,20 RX=19,21
    GPIOs_configure(18, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(19, GPIO_MODE_USER_STD_INPUT_PULLUP);
    GPIOs_configure(20, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(21, GPIO_MODE_USER_STD_INPUT_PULLUP);
    
    // SPI0: SCK=37, MOSI=36, MISO=35, SS=34
    GPIOs_configure(36, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(35, GPIO_MODE_USER_STD_INPUT_NOPULL);
    GPIOs_configure(37, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(34, GPIO_MODE_USER_STD_OUTPUT);
    
    // I2C0: SCL=5, SDA=4
    GPIOs_configure(5, GPIO_MODE_USER_STD_BIDIRECTIONAL);
    GPIOs_configure(4, GPIO_MODE_USER_STD_BIDIRECTIONAL);

    GPIOs_loadConfigs();
    User_enableIF();

    vgpio_write_output(1);  // Pads configured

    // ===== Test PWM =====
    CF_TMR32_configureExamplePWM(PWM0);
    CF_TMR32_configureExamplePWM(PWM1);
    vgpio_write_output(2);  // PWM configured

    // ===== Test UART =====
    CF_UART_setGclkEnable(UART0, 1);
    CF_UART_enable(UART0);
    CF_UART_enableTx(UART0);
    CF_UART_enableRx(UART0);
    CF_UART_setBaudRate_Hz(UART0, 115200, 45000000);
    
    CF_UART_setGclkEnable(UART1, 1);
    CF_UART_enable(UART1);
    CF_UART_enableTx(UART1);
    CF_UART_setBaudRate_Hz(UART1, 115200, 45000000);
    vgpio_write_output(3);  // UART configured

    // ===== Test SPI =====
    CF_SPI_setGclkEnable(SPI0, 1);
    CF_SPI_enable(SPI0);
    CF_SPI_writePhase(SPI0, false);
    CF_SPI_writepolarity(SPI0, false);
    CF_SPI_setPrescaler(SPI0, 4);
    vgpio_write_output(4);  // SPI configured

    // ===== Test I2C =====
    CF_I2C_setGclkEnable(I2C0, 1);
    CF_I2C_enable(I2C0);
    CF_I2C_setPrescaler(I2C0, 50);
    vgpio_write_output(5);  // I2C configured

    // ===== Test SRAM =====
    volatile uint32_t *sram0 = (volatile uint32_t *)SRAM0_BASE;
    volatile uint32_t *sram1 = (volatile uint32_t *)SRAM1_BASE;
    
    sram0[0] = 0x12345678;
    sram1[0] = 0x9ABCDEF0;
    
    uint32_t sram0_read = sram0[0];
    uint32_t sram1_read = sram1[0];
    
    if (sram0_read == 0x12345678 && sram1_read == 0x9ABCDEF0) {
        vgpio_write_output(6);  // SRAM test passed
    } else {
        vgpio_write_output(0xEEEE);  // Error
        while(1);
    }

    // ===== Test ADC =====
    *((volatile uint32_t *)ADC_CTRL) = ADC_CTRL_ENABLE;
    vgpio_write_output(7);  // ADC enabled

    // Send test data via UART0
    const char* msg = "SYS\n";
    for (int i = 0; msg[i] != '\0'; i++) {
        CF_UART_sendChar(UART0, msg[i]);
    }
    
    vgpio_write_output(8);  // System test complete

    while (1) {}
}
