// ============================================================
// chip_top.v
// Módulo top del chip ASIC
// Integra: fp_calculator_top + uart_controller
// Pines físicos del chip
// ============================================================

module chip_top (
    input  wire clk,        // reloj principal (50MHz)
    input  wire rst,        // reset activo alto
    input  wire uart_rx,    // pin RX serial (entrada desde PC)
    output wire uart_tx     // pin TX serial (salida hacia PC)
);

// ============================================================
// Señales internas entre UART controller y calculadora
// ============================================================
wire [31:0] calc_A, calc_B;
wire [3:0]  calc_op;
wire        calc_start;
wire [31:0] calc_result;
wire        calc_valid;
wire        calc_overflow;
wire        calc_underflow;
wire        calc_zero;
wire        calc_nan;
wire        calc_cmp_gt;
wire        calc_cmp_lt;
wire        calc_cmp_eq;

// ============================================================
// Instancia: Calculadora FP32
// ============================================================
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
    .underflow(calc_underflow),
    .zero_flag(calc_zero),
    .nan_flag (calc_nan),
    .cmp_gt   (calc_cmp_gt),
    .cmp_lt   (calc_cmp_lt),
    .cmp_eq   (calc_cmp_eq)
);

// ============================================================
// Instancia: Controlador UART
// ============================================================
uart_controller #(
    .CLK_FREQ (50_000_000),
    .BAUD_RATE(115_200)
) u_uart (
    .clk          (clk),
    .rst          (rst),
    .uart_rx_pin  (uart_rx),
    .uart_tx_pin  (uart_tx),
    .calc_A       (calc_A),
    .calc_B       (calc_B),
    .calc_op      (calc_op),
    .calc_start   (calc_start),
    .calc_result  (calc_result),
    .calc_valid   (calc_valid),
    .calc_overflow(calc_overflow),
    .calc_underflow(calc_underflow),
    .calc_zero    (calc_zero),
    .calc_nan     (calc_nan),
    .calc_cmp_gt  (calc_cmp_gt),
    .calc_cmp_lt  (calc_cmp_lt),
    .calc_cmp_eq  (calc_cmp_eq)
);

endmodule
