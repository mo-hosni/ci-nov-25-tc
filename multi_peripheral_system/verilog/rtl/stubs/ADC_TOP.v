`default_nettype none

// Stub module for linting only - ADC is a hard macro
module ADC_TOP (
    inout AVPWR,
    inout AVGND,
    inout DVPWR,
    inout DVGND,
    input adc_in,
    input ena_follower_amp,
    input ena_adc,
    input adc_reset,
    input adc_hold,
    input [11:0] adc_dac_val,
    output adc_cmp
);

    assign adc_cmp = 1'b0;

endmodule

`default_nettype wire
