// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/

    wire [11:0] pwm_out;
    wire [7:0] uart_tx;
    wire [7:0] uart_rx;
    wire spi_sck;
    wire spi_mosi;
    wire spi_miso;
    wire spi_ss;
    wire i2c_scl_out;
    wire i2c_scl_in;
    wire i2c_scl_oe;
    wire i2c_sda_out;
    wire i2c_sda_in;
    wire i2c_sda_oe;

    user_project mprj (
`ifdef USE_POWER_PINS
        .vccd2(vccd2),
        .vssd2(vssd2),
        .AVPWR(vdda2),
        .AVGND(vssa2),
`endif
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_stb_i(wbs_stb_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o),
        .user_irq(user_irq),
        .pwm_out(pwm_out),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx),
        .spi_sck(spi_sck),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_ss(spi_ss),
        .i2c_scl_out(i2c_scl_out),
        .i2c_scl_in(i2c_scl_in),
        .i2c_scl_oe(i2c_scl_oe),
        .i2c_sda_out(i2c_sda_out),
        .i2c_sda_in(i2c_sda_in),
        .i2c_sda_oe(i2c_sda_oe),
        .adc_in(analog_io[16])
    );

    assign io_out[17:6] = pwm_out;
    assign io_oeb[17:6] = 12'b0;

    assign uart_rx = io_in[25:18];
    assign io_out[25:18] = 8'b0;
    assign io_oeb[25:18] = 8'hFF;

    assign io_out[33:26] = uart_tx;
    assign io_oeb[33:26] = 8'b0;

    assign io_out[34] = spi_sck;
    assign io_oeb[34] = 1'b0;

    assign io_out[35] = spi_mosi;
    assign io_oeb[35] = 1'b0;

    assign spi_miso = io_in[36];
    assign io_out[36] = 1'b0;
    assign io_oeb[36] = 1'b1;

    assign io_out[37] = spi_ss;
    assign io_oeb[37] = 1'b0;

    assign io_out[5] = i2c_scl_oe ? 1'b0 : i2c_scl_out;
    assign i2c_scl_in = io_in[5];
    assign io_oeb[5] = ~i2c_scl_oe;

    assign io_out[4] = i2c_sda_oe ? 1'b0 : i2c_sda_out;
    assign i2c_sda_in = io_in[4];
    assign io_oeb[4] = ~i2c_sda_oe;

    assign io_out[3:0] = 4'b0;
    assign io_oeb[3:0] = 4'b1111;

    assign la_data_out = 128'b0;

endmodule	// user_project_wrapper

`default_nettype wire
