// ============================================================
// project.v
// Wrapper TinyTapeout para la calculadora FP16
// Interfaz estándar tt_um_*
// ============================================================
// Pinout:
//   ui[0]   = uart_rx  (entrada serial desde PC)
//   uo[0]   = uart_tx  (salida serial hacia PC)
//   ena     = enable
//   clk     = reloj
//   rst_n   = reset activo bajo
// ============================================================

`default_nettype none

module tt_um_digital_asic_fp_calculator (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Señales internas
    wire uart_rx = ui_in[0];
    wire uart_tx;
    wire rst     = !rst_n;

    // Salidas no usadas
    assign uo_out[7:1] = 7'b0;
    assign uo_out[0]   = uart_tx;
    assign uio_out     = 8'b0;
    assign uio_oe      = 8'b0;

    // Suprimir warning de unused
    wire _unused = &{ena, ui_in[7:1], uio_in};

    // Instancia chip_top
    chip_top u_chip (
        .clk     (clk),
        .rst     (rst),
        .uart_rx (uart_rx),
        .uart_tx (uart_tx)
    );

endmodule
