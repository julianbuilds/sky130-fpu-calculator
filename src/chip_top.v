// ============================================================
// chip_top.v
// Integra fp_calculator_top (FP16) + uart_controller
// ============================================================

module chip_top (
    input  wire clk,
    input  wire rst,
    input  wire uart_rx,
    output wire uart_tx
);

wire [15:0] calc_A, calc_B;
wire [2:0]  calc_op;
wire        calc_start;
wire [15:0] calc_result;
wire        calc_valid, calc_overflow;
wire        calc_zero, calc_nan;
wire        calc_cmp_gt, calc_cmp_lt, calc_cmp_eq;

fp_calculator_top u_calculator (
    .clk      (clk),
    .rst      (rst),
    .A        (calc_A),
    .B        (calc_B),
    .OP       (calc_op),
    .start    (calc_start),
    .result   (calc_result),
    .valid    (calc_valid),
    .overflow (calc_overflow),
    .zero_flag(calc_zero),
    .nan_flag (calc_nan),
    .cmp_gt   (calc_cmp_gt),
    .cmp_lt   (calc_cmp_lt),
    .cmp_eq   (calc_cmp_eq)
);

uart_controller #(
    .CLK_FREQ (50_000_000),
    .BAUD_RATE(115_200)
) u_uart (
    .clk           (clk),
    .rst           (rst),
    .uart_rx_pin   (uart_rx),
    .uart_tx_pin   (uart_tx),
    .calc_A        (calc_A),
    .calc_B        (calc_B),
    .calc_op       (calc_op),
    .calc_start    (calc_start),
    .calc_result   (calc_result),
    .calc_valid    (calc_valid),
    .calc_overflow (calc_overflow),
    .calc_underflow(1'b0),
    .calc_zero     (calc_zero),
    .calc_nan      (calc_nan),
    .calc_cmp_gt   (calc_cmp_gt),
    .calc_cmp_lt   (calc_cmp_lt),
    .calc_cmp_eq   (calc_cmp_eq)
);

endmodule
