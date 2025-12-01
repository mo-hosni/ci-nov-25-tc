#include <firmware_apis.h>
#include "CF_UART.h"

// -------------------------------
// UART base and helpers
// -------------------------------
#define UART_BASE 0x300C0000
#define UART ((CF_UART_TYPE_PTR)UART_BASE)

// Helper to set baud rate prescaler using 45MHz clock
static inline void CF_UART_setBaudRate_Hz(CF_UART_TYPE_PTR uart, uint32_t baud_rate, uint32_t clock_freq_hz)
{
    // prescaler = (clk / (baud * 8)) - 1
    uint32_t prescaler = (clock_freq_hz / (baud_rate * 8)) - 1;
    CF_UART_setPrescaler(uart, prescaler);
}

void main(void)
{
    // Disable housekeeping SPI and prep pads
    enableHkSpi(false);

    // Configure the pads that the IP touches (UART0 TX=18, RX=19)
    GPIOs_configure(18, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(19, GPIO_MODE_USER_STD_INPUT_PULLUP);
    GPIOs_loadConfigs();

    // Enable Wishbone access for user project
    User_enableIF();

    // -------------------------------------------
    // 1) Signal: start of configuration
    // -------------------------------------------
    vgpio_write_output(1);

    // -------------------------------------------
    // 2) Enable UART peripheral
    // -------------------------------------------
    CF_UART_setGclkEnable(UART, 1);
    CF_UART_enable(UART);
    CF_UART_setTxFIFOThreshold(UART, 3);
    CF_UART_enableTx(UART);
    CF_UART_enableRx(UART);
    CF_UART_setBaudRate_Hz(UART, 115200, 45000000);
    vgpio_write_output(2);

    // -------------------------------------------
    // 3) Use UART to transmit data over GPIO
    // -------------------------------------------
    // Send "Hello UART\n"
    CF_UART_writeChar(UART, 'H');
    CF_UART_writeChar(UART, 'e');
    CF_UART_writeChar(UART, 'l');
    CF_UART_writeChar(UART, 'l');
    CF_UART_writeChar(UART, 'o');
    CF_UART_writeChar(UART, ' ');
    CF_UART_writeChar(UART, 'U');
    CF_UART_writeChar(UART, 'A');
    CF_UART_writeChar(UART, 'R');
    CF_UART_writeChar(UART, 'T');
    CF_UART_writeChar(UART, '\n');

    vgpio_write_output(3);

    // -------------------------------------------
    // 4) Disable UART peripheral
    // -------------------------------------------
    CF_UART_disable(UART);
    vgpio_write_output(4);

    // -------------------------------------------
    // 5) Try using peripheral again (should not respond)
    //    (No-op/attempt after disable; still pulse VGPIO)
    // -------------------------------------------
    // CF_UART_writeChar(UART, 'X'); // intentionally after disable
    vgpio_write_output(5);

    // -------------------------------------------
    // 6) Optional cross-peripheral interaction marker
    // -------------------------------------------
    vgpio_write_output(6);

    return;
}
