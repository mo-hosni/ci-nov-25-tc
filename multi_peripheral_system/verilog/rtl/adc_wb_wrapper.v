`default_nettype none
`timescale 1ns/1ps

module adc_wb_wrapper (
`ifdef USE_POWER_PINS
    inout VPWR,
    inout VGND,
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
    output reg [31:0] wbs_dat_o,

    input wire adc_in,
    output wire irq
);

    localparam ADDR_DATA      = 8'h00;
    localparam ADDR_CTRL      = 8'h04;
    localparam ADDR_STATUS    = 8'h08;
    localparam ADDR_CFG       = 8'h0C;
    localparam ADDR_THRESHOLD = 8'h10;
    localparam ADDR_IM        = 8'hFC;
    localparam ADDR_RIS       = 9'h100;
    localparam ADDR_MIS       = 9'h104;
    localparam ADDR_IC        = 9'h108;

    wire valid;
    wire write_enable;
    reg wbs_ack_o_reg;

    assign valid = wbs_cyc_i && wbs_stb_i;
    assign write_enable = wbs_we_i && valid;

    reg [11:0] adc_data;
    reg [2:0] ctrl_reg;
    reg [1:0] status_reg;
    reg [3:0] cfg_swidth;
    reg [11:0] threshold_reg;
    reg irq_mask;
    reg irq_raw;

    wire adc_start;
    wire adc_continuous;
    wire adc_enable;

    assign adc_start = ctrl_reg[0];
    assign adc_continuous = ctrl_reg[1];
    assign adc_enable = ctrl_reg[2];

    wire adc_done;
    wire adc_busy;

    wire [11:0] sar_data;
    wire sar_eoc;
    wire sar_sample_n;
    wire sar_dac_rst;
    wire adc_cmp;

    reg soc_trigger;
    reg soc_prev;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            soc_prev <= 1'b0;
            soc_trigger <= 1'b0;
        end else begin
            soc_prev <= adc_start;
            soc_trigger <= adc_start && !soc_prev;
        end
    end

    sar_ctrl #(
        .SIZE(12)
    ) sar_ctrl_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .soc(soc_trigger || (adc_continuous && sar_eoc)),
        .cmp(adc_cmp),
        .en(adc_enable),
        .swidth(cfg_swidth),
        .sample_n(sar_sample_n),
        .data(sar_data),
        .eoc(sar_eoc),
        .dac_rst(sar_dac_rst)
    );

    ADC_TOP adc_top_inst (
        .AVPWR(
`ifdef USE_POWER_PINS
            AVPWR
`else
            1'b1
`endif
        ),
        .AVGND(
`ifdef USE_POWER_PINS
            AVGND
`else
            1'b0
`endif
        ),
        .DVPWR(
`ifdef USE_POWER_PINS
            VPWR
`else
            1'b1
`endif
        ),
        .DVGND(
`ifdef USE_POWER_PINS
            VGND
`else
            1'b0
`endif
        ),
        .adc_in(adc_in),
        .ena_follower_amp(adc_enable),
        .ena_adc(adc_enable),
        .adc_reset(sar_dac_rst),
        .adc_hold(sar_sample_n),
        .adc_dac_val(sar_data),
        .adc_cmp(adc_cmp)
    );

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            adc_data <= 12'h000;
            status_reg <= 2'b00;
        end else begin
            if (sar_eoc) begin
                adc_data <= sar_data;
                status_reg[0] <= 1'b1;
                status_reg[1] <= 1'b0;
            end else if (adc_enable && soc_trigger) begin
                status_reg[0] <= 1'b0;
                status_reg[1] <= 1'b1;
            end
        end
    end

    assign adc_done = status_reg[0];
    assign adc_busy = status_reg[1];

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            irq_raw <= 1'b0;
        end else begin
            if (write_enable && (wbs_adr_i[8:2] == (ADDR_IC >> 2)) && wbs_dat_i[0])
                irq_raw <= 1'b0;
            else if (sar_eoc)
                irq_raw <= 1'b1;
        end
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ctrl_reg <= 3'b000;
            cfg_swidth <= 4'h4;
            threshold_reg <= 12'h000;
            irq_mask <= 1'b0;
        end else if (write_enable) begin
            case (wbs_adr_i[8:2])
                (ADDR_CTRL >> 2): ctrl_reg <= wbs_dat_i[2:0];
                (ADDR_CFG >> 2): cfg_swidth <= wbs_dat_i[3:0];
                (ADDR_THRESHOLD >> 2): threshold_reg <= wbs_dat_i[11:0];
                (ADDR_IM >> 2): irq_mask <= wbs_dat_i[0];
            endcase
        end
    end

    always @(*) begin
        case (wbs_adr_i[8:2])
            (ADDR_DATA >> 2): wbs_dat_o = {20'h00000, adc_data};
            (ADDR_CTRL >> 2): wbs_dat_o = {29'h00000000, ctrl_reg};
            (ADDR_STATUS >> 2): wbs_dat_o = {30'h00000000, status_reg};
            (ADDR_CFG >> 2): wbs_dat_o = {28'h0000000, cfg_swidth};
            (ADDR_THRESHOLD >> 2): wbs_dat_o = {20'h00000, threshold_reg};
            (ADDR_IM >> 2): wbs_dat_o = {31'h00000000, irq_mask};
            (ADDR_RIS >> 2): wbs_dat_o = {31'h00000000, irq_raw};
            (ADDR_MIS >> 2): wbs_dat_o = {31'h00000000, irq_raw & irq_mask};
            (ADDR_IC >> 2): wbs_dat_o = 32'h00000000;
            default: wbs_dat_o = 32'hDEADBEEF;
        endcase
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            wbs_ack_o_reg <= 1'b0;
        else if (wbs_cyc_i && wbs_stb_i && ~wbs_ack_o_reg)
            wbs_ack_o_reg <= 1'b1;
        else
            wbs_ack_o_reg <= 1'b0;
    end

    assign wbs_ack_o = wbs_ack_o_reg;
    assign irq = irq_raw & irq_mask;

endmodule

`default_nettype wire
