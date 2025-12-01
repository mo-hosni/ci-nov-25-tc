#include <firmware_apis.h>

#define ERROR_CODE 0xEEEE

#define SRAM_BASE 0x30160000
#define SRAM_SIZE 1024

#define ADDR_FIRST 0
#define ADDR_LAST 1023
#define ADDR_MID_LOW 511
#define ADDR_MID_HIGH 512
#define ADDR_Q1_LOW 255
#define ADDR_Q1_HIGH 256
#define ADDR_Q3_LOW 767
#define ADDR_Q3_HIGH 768


static inline void report_error(void) {
    vgpio_write_output(ERROR_CODE);
    while(1);
}

static inline void small_delay(void) {
    for (volatile int i = 0; i < 50; i++) {}
}

uint32_t simple_rand(uint32_t *seed) {
    *seed = (*seed * 1103515245 + 12345) & 0x7FFFFFFF;
    return *seed;
}

void main(void) {
    enableHkSpi(false);
    GPIOs_loadConfigs();
    User_enableIF();

    volatile uint32_t *sram = (volatile uint32_t *)SRAM_BASE;
    uint32_t read_val;

    vgpio_write_output(1);


    vgpio_write_output(2);
    sram[ADDR_FIRST] = 0xDEADBEEF;
    sram[ADDR_LAST] = 0xCAFEBABE;

    if (sram[ADDR_FIRST] != 0xDEADBEEF) report_error();
    if (sram[ADDR_LAST] != 0xCAFEBABE) report_error();


    vgpio_write_output(3);
    sram[ADDR_MID_LOW] = 0x11111111;
    sram[ADDR_MID_HIGH] = 0x22222222;
    sram[ADDR_Q1_LOW] = 0x33333333;
    sram[ADDR_Q1_HIGH] = 0x44444444;
    sram[ADDR_Q3_LOW] = 0x55555555;
    sram[ADDR_Q3_HIGH] = 0x66666666;

    if (sram[ADDR_MID_LOW] != 0x11111111) report_error();
    if (sram[ADDR_MID_HIGH] != 0x22222222) report_error();
    if (sram[ADDR_Q1_LOW] != 0x33333333) report_error();
    if (sram[ADDR_Q1_HIGH] != 0x44444444) report_error();
    if (sram[ADDR_Q3_LOW] != 0x55555555) report_error();
    if (sram[ADDR_Q3_HIGH] != 0x66666666) report_error();


    vgpio_write_output(4);
    for (int bit = 0; bit < 32; bit++) {
        uint32_t pattern = 1 << bit;
        sram[32 + bit] = pattern;

    }
    for (int bit = 0; bit < 32; bit++) {
        uint32_t expected = 1 << bit;
        if (sram[32 + bit] != expected) report_error();

    }

    vgpio_write_output(5);
    for (int bit = 0; bit < 32; bit++) {
        uint32_t pattern = ~(1 << bit);
        sram[64 + bit] = pattern;

    }
    for (int bit = 0; bit < 32; bit++) {
        uint32_t expected = ~(1 << bit);
        if (sram[64 + bit] != expected) report_error();

    }

    vgpio_write_output(6);
    for (int i = 128; i < 128+20; i++) {
        sram[i] = (i & 1) ? 0x55555555 : 0xAAAAAAAA;

    }
    for (int i = 128; i < 128+20; i++) {
        uint32_t expected = (i & 1) ? 0x55555555 : 0xAAAAAAAA;
        if (sram[i] != expected) report_error();

    }

    vgpio_write_output(7);
    uint32_t byte_patterns[] = {0x12345678, 0x9ABCDEF0, 0xFEDCBA98, 0x76543210};
    for (int i = 0; i < 4; i++) {
        sram[300 + i] = byte_patterns[i];
    }

    for (int i = 0; i < 4; i++) {
        if (sram[300 + i] != byte_patterns[i]) report_error();
    }


    vgpio_write_output(8);
    uint32_t nibble_patterns[] = {0xF0F0F0F0, 0x0F0F0F0F, 0xCCCCCCCC, 0x33333333};
    for (int i = 0; i < 4; i++) {
        sram[310 + i] = nibble_patterns[i];
    }

    for (int i = 0; i < 4; i++) {
        if (sram[310 + i] != nibble_patterns[i]) report_error();
    }


    vgpio_write_output(9);
    sram[400] = 0x00000000;

    volatile uint8_t *sram_byte = (volatile uint8_t *)&sram[400];
    sram_byte[3] = 0x12;
    sram_byte[2] = 0x34;
    sram_byte[1] = 0x56;
    sram_byte[0] = 0x78;

    read_val = sram[400];
    if (read_val != 0x12345678) report_error();


    vgpio_write_output(10);
    for (int i = 0; i < SRAM_SIZE; i++) {
        sram[i] = 0x00000000;

    }
    for (int i = 0; i < SRAM_SIZE; i++) {
        if (sram[i] != 0x00000000) report_error();

    }

    vgpio_write_output(11);
    for (int i = 0; i < SRAM_SIZE; i++) {
        sram[i] = 0xFFFFFFFF;

    }
    for (int i = 0; i < SRAM_SIZE; i++) {
        if (sram[i] != 0xFFFFFFFF) report_error();

    }

    vgpio_write_output(15);
    sram[ADDR_FIRST] = 0xFEEDFACE;
    sram[ADDR_LAST] = 0xDEADC0DE;
    sram[ADDR_MID_LOW] = 0xBEEFF00D;
    sram[ADDR_MID_HIGH] = 0xCAFED00D;

    if (sram[ADDR_FIRST] != 0xFEEDFACE) report_error();
    if (sram[ADDR_LAST] != 0xDEADC0DE) report_error();
    if (sram[ADDR_MID_LOW] != 0xBEEFF00D) report_error();
    if (sram[ADDR_MID_HIGH] != 0xCAFED00D) report_error();


    vgpio_write_output(17);
    volatile uint16_t *sram_halfword = (volatile uint16_t *)&sram[150];
    sram[150] = 0x00000000;

    sram_halfword[0] = 0x5678;
    sram_halfword[1] = 0x1234;

    read_val = sram[150];
    if (read_val != 0x12345678) report_error();

    vgpio_write_output(18);

    return;
}
