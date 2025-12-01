`default_nettype none
`timescale 1ns/1ps

module user_project (
`ifdef USE_POWER_PINS
    inout vccd2,
    inout vssd2,
    inout AVPWR,
    inout AVGND,
`endif

    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [31:0] wbs_adr_i,
    output wire wbs_ack_o,
    output wire [31:0] wbs_dat_o,

    output wire [2:0] user_irq,

    output wire [11:0] pwm_out,
    output wire [7:0] uart_tx,
    input wire [7:0] uart_rx,
    output wire spi_sck,
    output wire spi_mosi,
    input wire spi_miso,
    output wire spi_ss,
    output wire i2c_scl_out,
    input wire i2c_scl_in,
    output wire i2c_scl_oe,
    output wire i2c_sda_out,
    input wire i2c_sda_in,
    output wire i2c_sda_oe,
    input wire adc_in
);

    localparam NUM_PERIPHERALS = 27;

    wire [NUM_PERIPHERALS-1:0] s_wb_cyc;
    wire [NUM_PERIPHERALS-1:0] s_wb_stb;
    wire [NUM_PERIPHERALS-1:0] s_wb_we;
    wire [NUM_PERIPHERALS*4-1:0] s_wb_sel;
    wire [NUM_PERIPHERALS*32-1:0] s_wb_adr;
    wire [NUM_PERIPHERALS*32-1:0] s_wb_dat_o;
    wire [NUM_PERIPHERALS*32-1:0] s_wb_dat_i;
    wire [NUM_PERIPHERALS-1:0] s_wb_ack;
    wire [NUM_PERIPHERALS-1:0] s_wb_err;

    wishbone_bus_splitter #(
        .NUM_PERIPHERALS(NUM_PERIPHERALS),
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .SEL_WIDTH(4),
        .ADDR_SEL_LOW_BIT(16)
    ) bus_splitter (
        .m_wb_clk_i(wb_clk_i),
        .m_wb_rst_i(wb_rst_i),
        .m_wb_adr_i(wbs_adr_i),
        .m_wb_dat_i(wbs_dat_i),
        .m_wb_dat_o(wbs_dat_o),
        .m_wb_sel_i(wbs_sel_i),
        .m_wb_cyc_i(wbs_cyc_i),
        .m_wb_stb_i(wbs_stb_i),
        .m_wb_we_i(wbs_we_i),
        .m_wb_ack_o(wbs_ack_o),
        .m_wb_err_o(),

        .s_wb_cyc_o(s_wb_cyc),
        .s_wb_stb_o(s_wb_stb),
        .s_wb_we_o(s_wb_we),
        .s_wb_sel_o(s_wb_sel),
        .s_wb_adr_o(s_wb_adr),
        .s_wb_dat_o(s_wb_dat_o),
        .s_wb_dat_i(s_wb_dat_i),
        .s_wb_ack_i(s_wb_ack),
        .s_wb_err_i(s_wb_err)
    );

    wire [22:0] peripheral_irqs;

    genvar i;
    generate
        for (i = 0; i < 12; i = i + 1) begin : pwm_gen
            CF_TMR32_WB pwm_inst (
`ifdef USE_POWER_PINS
                .VPWR(vccd2),
                .VGND(vssd2),
`endif
                .clk(wb_clk_i),
                .rst_n(~wb_rst_i),
                .wb_adr_i(s_wb_adr[i*32 +: 32]),
                .wb_dat_i(s_wb_dat_o[i*32 +: 32]),
                .wb_dat_o(s_wb_dat_i[i*32 +: 32]),
                .wb_sel_i(s_wb_sel[i*4 +: 4]),
                .wb_cyc_i(s_wb_cyc[i]),
                .wb_stb_i(s_wb_stb[i]),
                .wb_we_i(s_wb_we[i]),
                .wb_ack_o(s_wb_ack[i]),
                .pwm_out(pwm_out[i]),
                .pwm1_out(),
                .trig_in(1'b0),
                .irq(peripheral_irqs[i])
            );
            assign s_wb_err[i] = 1'b0;
        end

        for (i = 12; i < 20; i = i + 1) begin : uart_gen
            CF_UART_WB uart_inst (
`ifdef USE_POWER_PINS
                .VPWR(vccd2),
                .VGND(vssd2),
`endif
                .clk(wb_clk_i),
                .rst_n(~wb_rst_i),
                .wb_adr_i(s_wb_adr[i*32 +: 32]),
                .wb_dat_i(s_wb_dat_o[i*32 +: 32]),
                .wb_dat_o(s_wb_dat_i[i*32 +: 32]),
                .wb_sel_i(s_wb_sel[i*4 +: 4]),
                .wb_cyc_i(s_wb_cyc[i]),
                .wb_stb_i(s_wb_stb[i]),
                .wb_we_i(s_wb_we[i]),
                .wb_ack_o(s_wb_ack[i]),
                .tx(uart_tx[i-12]),
                .rx(uart_rx[i-12]),
                .irq(peripheral_irqs[i])
            );
            assign s_wb_err[i] = 1'b0;
        end
    endgenerate

    CF_SPI_WB spi_inst (
`ifdef USE_POWER_PINS
        .VPWR(vccd2),
        .VGND(vssd2),
`endif
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .wb_adr_i(s_wb_adr[20*32 +: 32]),
        .wb_dat_i(s_wb_dat_o[20*32 +: 32]),
        .wb_dat_o(s_wb_dat_i[20*32 +: 32]),
        .wb_sel_i(s_wb_sel[20*4 +: 4]),
        .wb_cyc_i(s_wb_cyc[20]),
        .wb_stb_i(s_wb_stb[20]),
        .wb_we_i(s_wb_we[20]),
        .wb_ack_o(s_wb_ack[20]),
        .sck(spi_sck),
        .mosi(spi_mosi),
        .miso(spi_miso),
        .ss(spi_ss),
        .irq(peripheral_irqs[20])
    );
    assign s_wb_err[20] = 1'b0;

    CF_I2C_WB i2c_inst (
`ifdef USE_POWER_PINS
        .VPWR(vccd2),
        .VGND(vssd2),
`endif
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .wb_adr_i(s_wb_adr[21*32 +: 32]),
        .wb_dat_i(s_wb_dat_o[21*32 +: 32]),
        .wb_dat_o(s_wb_dat_i[21*32 +: 32]),
        .wb_sel_i(s_wb_sel[21*4 +: 4]),
        .wb_cyc_i(s_wb_cyc[21]),
        .wb_stb_i(s_wb_stb[21]),
        .wb_we_i(s_wb_we[21]),
        .wb_ack_o(s_wb_ack[21]),
        .scl_i(i2c_scl_in),
        .scl_o(i2c_scl_out),
        .scl_oen_o(i2c_scl_oe),
        .sda_i(i2c_sda_in),
        .sda_o(i2c_sda_out),
        .sda_oen_o(i2c_sda_oe),
        .irq(peripheral_irqs[21])
    );
    assign s_wb_err[21] = 1'b0;

    CF_SRAM_1024x32_WB sram0_inst (
`ifdef USE_POWER_PINS
        .VPWR(vccd2),
        .VGND(vssd2),
`endif
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wb_adr_i(s_wb_adr[22*32 +: 32]),
        .wb_dat_i(s_wb_dat_o[22*32 +: 32]),
        .wb_dat_o(s_wb_dat_i[22*32 +: 32]),
        .wb_sel_i(s_wb_sel[22*4 +: 4]),
        .wb_cyc_i(s_wb_cyc[22]),
        .wb_stb_i(s_wb_stb[22]),
        .wb_we_i(s_wb_we[22]),
        .wb_ack_o(s_wb_ack[22])
    );
    assign s_wb_err[22] = 1'b0;

    CF_SRAM_1024x32_WB sram1_inst (
`ifdef USE_POWER_PINS
        .VPWR(vccd2),
        .VGND(vssd2),
`endif
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wb_adr_i(s_wb_adr[23*32 +: 32]),
        .wb_dat_i(s_wb_dat_o[23*32 +: 32]),
        .wb_dat_o(s_wb_dat_i[23*32 +: 32]),
        .wb_sel_i(s_wb_sel[23*4 +: 4]),
        .wb_cyc_i(s_wb_cyc[23]),
        .wb_stb_i(s_wb_stb[23]),
        .wb_we_i(s_wb_we[23]),
        .wb_ack_o(s_wb_ack[23])
    );
    assign s_wb_err[23] = 1'b0;

    adc_wb_wrapper adc_inst (
`ifdef USE_POWER_PINS
        .VPWR(vccd2),
        .VGND(vssd2),
        .AVPWR(AVPWR),
        .AVGND(AVGND),
`endif
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_adr_i(s_wb_adr[24*32 +: 32]),
        .wbs_dat_i(s_wb_dat_o[24*32 +: 32]),
        .wbs_dat_o(s_wb_dat_i[24*32 +: 32]),
        .wbs_sel_i(s_wb_sel[24*4 +: 4]),
        .wbs_cyc_i(s_wb_cyc[24]),
        .wbs_stb_i(s_wb_stb[24]),
        .wbs_we_i(s_wb_we[24]),
        .wbs_ack_o(s_wb_ack[24]),
        .adc_in(adc_in),
        .irq(peripheral_irqs[22])
    );
    assign s_wb_err[24] = 1'b0;

    wire pic_irq_out;

    WB_PIC pic_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .irq_lines({7'b0000000, peripheral_irqs[22:14], peripheral_irqs[12:0]}),
        .irq_out(pic_irq_out),
        .wb_adr_i(s_wb_adr[25*32 +: 32]),
        .wb_dat_i(s_wb_dat_o[25*32 +: 32]),
        .wb_dat_o(s_wb_dat_i[25*32 +: 32]),
        .wb_sel_i(s_wb_sel[25*4 +: 4]),
        .wb_cyc_i(s_wb_cyc[25]),
        .wb_stb_i(s_wb_stb[25]),
        .wb_we_i(s_wb_we[25]),
        .wb_ack_o(s_wb_ack[25])
    );
    assign s_wb_err[25] = 1'b0;

    assign s_wb_dat_i[26*32 +: 32] = 32'hDEADBEEF;
    assign s_wb_ack[26] = s_wb_cyc[26] && s_wb_stb[26];
    assign s_wb_err[26] = 1'b0;

    assign user_irq[2] = pic_irq_out;
    assign user_irq[1] = 1'b0;
    assign user_irq[0] = 1'b0;

endmodule

`default_nettype wire
