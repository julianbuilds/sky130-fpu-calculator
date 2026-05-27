`default_nettype none

module tt_um_digital_asic_fp_calculator (
    input  wire [7:0] ui_in,    // Entradas digitales dedicadas
    output wire [7:0] uo_out,   // Salidas digitales dedicadas
    input  wire [7:0] uio_in,   // Pines bidireccionales - Entrada
    output wire [7:0] uio_out,  // Pines bidireccionales - Salida
    output wire [7:0] uio_oe,   // Pines bidireccionales - Habilitación de Salida
    input  wire       ena,      // Activo en alto si el diseño está seleccionado
    input  wire       clk,      // Reloj maestro del sistema
    input  wire       rst_n     // Reset global - ¡ACTIVO EN BAJO!
);

    // Tiny Tapeout usa reset activo en BAJO (rst_n), 
    // pero tu chip_top usa reset activo en ALTO (rst).
    // Invertimos la señal para mantener la compatibilidad:
    wire rst_high = ~rst_n;

    // Instancia de tu chip FPU de 4 pines
    chip_top u_my_chip (
        .clk    (clk),
        .rst    (rst_high),
        .uart_rx(ui_in[0]),     // Asignamos el pin ui_in[0] para recibir datos (RX)
        .uart_tx(uo_out[0])     // Asignamos el pin uo_out[0] para transmitir datos (TX)
    );

    // Apagamos o ponemos en cero el resto de pines que no usamos para evitar ruidos
    assign uo_out[7:1]  = 7'b0000000;
    assign uio_out      = 8'b0000000;
    assign uio_oe       = 8'b0000000;

endmodule