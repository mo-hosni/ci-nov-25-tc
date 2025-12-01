#include <firmware_apis.h>
#include <CF_SPI.h>

#define SPI_BASE 0x30140000

void main(void)
{
    enableHkSpi(false);

    // SPI0: SCK=37, MOSI=36, MISO=35, SS=34
    GPIOs_configure(36, GPIO_MODE_USER_STD_OUTPUT);  // MOSI
    GPIOs_configure(35, GPIO_MODE_USER_STD_INPUT_NOPULL);  // MISO
    GPIOs_configure(37, GPIO_MODE_USER_STD_OUTPUT);  // SCK
    GPIOs_configure(34, GPIO_MODE_USER_STD_OUTPUT);  // SS
    GPIOs_loadConfigs();

    User_enableIF();

    vgpio_write_output(1);

    CF_SPI_setGclkEnable(SPI_BASE, 1);
    CF_SPI_enable(SPI_BASE);
    CF_SPI_writePhase(SPI_BASE, false);
    CF_SPI_writepolarity(SPI_BASE, false);
    CF_SPI_setPrescaler(SPI_BASE, 4);
    CF_SPI_enableRx(SPI_BASE);
    CF_SPI_assertCs(SPI_BASE);

    vgpio_write_output(2);

    uint8_t test_data[8] = {0x55, 0xAA, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC};

    for (int i = 0; i < 8; i++) {
        CF_SPI_writeData(SPI_BASE, test_data[i]);
    }

    CF_SPI_waitTxFifoEmpty(SPI_BASE);
    CF_SPI_FifoRxFlush(SPI_BASE);
    vgpio_write_output(3);

    uint8_t rx_data[8];
    for (int i = 0; i < 8; i++) {
        CF_SPI_writeData(SPI_BASE, 0x0);
        CF_SPI_waitRxFifoNotEmpty(SPI_BASE);
        rx_data[i] = CF_SPI_readData(SPI_BASE);
        vgpio_write_output(rx_data[i]);
    }
    uint8_t test_rxdata[8] = {0x66, 0xBB, 0x23, 0x42, 0x78, 0xab, 0xbb, 0xCF};
    int pass = 1;
    for (int i = 0; i < 8; i++) {
        if (rx_data[i] != test_rxdata[i]) {
            vgpio_write_output(0XEEEE);
            break;
        }
    }


    CF_SPI_deassertCs(SPI_BASE);
    CF_SPI_disable(SPI_BASE);

    vgpio_write_output(6);
}
