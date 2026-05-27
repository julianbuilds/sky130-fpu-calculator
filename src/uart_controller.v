// ============================================================
// uart_controller.v
// Protocolo de comunicación PC ↔ Calculadora
// ============================================================
// Protocolo de paquetes (PC → Chip):
//   Byte 0:     0xAA (header)
//   Byte 1:     OP[3:0] (operación)
//   Bytes 2-5:  A[31:0] big-endian (FP32)
//   Bytes 6-9:  B[31:0] big-endian (FP32)
//   Byte 10:    0x55 (footer)
//
// Protocolo de respuesta (Chip → PC):
//   Byte 0:     0xBB (header respuesta)
//   Bytes 1-4:  Result[31:0] big-endian
//   Byte 5:     flags {nan, overflow, zero, cmp_eq, cmp_gt, cmp_lt, 0, 0}
//   Byte 6:     0x66 (footer respuesta)
// ============================================================

module uart_controller #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115_200
)(
    input  wire        clk,
    input  wire        rst,

    // Pines físicos UART
    input  wire        uart_rx_pin,
    output wire        uart_tx_pin,

    // Interfaz con calculadora
    output reg  [31:0] calc_A,
    output reg  [31:0] calc_B,
    output reg  [3:0]  calc_op,
    output reg         calc_start,

    input  wire [31:0] calc_result,
    input  wire        calc_valid,
    input  wire        calc_overflow,
    input  wire        calc_underflow,
    input  wire        calc_zero,
    input  wire        calc_nan,
    input  wire        calc_cmp_gt,
    input  wire        calc_cmp_lt,
    input  wire        calc_cmp_eq
);

// ============================================================
// Instancias UART RX/TX
// ============================================================
wire [7:0] rx_byte;
wire       rx_valid;

uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_rx (
    .clk       (clk),
    .rst       (rst),
    .rx        (uart_rx_pin),
    .data_out  (rx_byte),
    .data_valid(rx_valid)
);

reg  [7:0] tx_byte;
reg        tx_send;
wire       tx_busy;

uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_tx (
    .clk     (clk),
    .rst     (rst),
    .data_in (tx_byte),
    .send    (tx_send),
    .tx      (uart_tx_pin),
    .busy    (tx_busy)
);

// ============================================================
// FSM de recepción
// ============================================================
localparam RX_IDLE    = 4'd0;
localparam RX_HEADER  = 4'd1;
localparam RX_OP      = 4'd2;
localparam RX_A       = 4'd3;
localparam RX_B       = 4'd4;
localparam RX_FOOTER  = 4'd5;
localparam RX_PROCESS = 4'd6;

reg [3:0]  rx_state;
reg [2:0]  byte_count;
reg [31:0] reg_A, reg_B;
reg [3:0]  reg_op;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        rx_state   <= RX_IDLE;
        byte_count <= 0;
        reg_A      <= 32'h0;
        reg_B      <= 32'h0;
        reg_op     <= 4'h0;
        calc_start <= 0;
        calc_A     <= 32'h0;
        calc_B     <= 32'h0;
        calc_op    <= 4'h0;
    end else begin
        calc_start <= 0;

        if (rx_valid) begin
            case (rx_state)
                RX_IDLE: begin
                    if (rx_byte == 8'hAA)
                        rx_state <= RX_OP;
                end

                RX_OP: begin
                    reg_op     <= rx_byte[3:0];
                    byte_count <= 0;
                    rx_state   <= RX_A;
                end

                RX_A: begin
                    case (byte_count)
                        0: reg_A[31:24] <= rx_byte;
                        1: reg_A[23:16] <= rx_byte;
                        2: reg_A[15:8]  <= rx_byte;
                        3: reg_A[7:0]   <= rx_byte;
                    endcase
                    if (byte_count == 3) begin
                        byte_count <= 0;
                        rx_state   <= RX_B;
                    end else begin
                        byte_count <= byte_count + 1;
                    end
                end

                RX_B: begin
                    case (byte_count)
                        0: reg_B[31:24] <= rx_byte;
                        1: reg_B[23:16] <= rx_byte;
                        2: reg_B[15:8]  <= rx_byte;
                        3: reg_B[7:0]   <= rx_byte;
                    endcase
                    if (byte_count == 3) begin
                        byte_count <= 0;
                        rx_state   <= RX_FOOTER;
                    end else begin
                        byte_count <= byte_count + 1;
                    end
                end

                RX_FOOTER: begin
                    if (rx_byte == 8'h55) begin
                        calc_A     <= reg_A;
                        calc_B     <= reg_B;
                        calc_op    <= reg_op;
                        calc_start <= 1;
                    end
                    rx_state <= RX_IDLE;
                end

                default: rx_state <= RX_IDLE;
            endcase
        end
    end
end

// ============================================================
// FSM de transmisión de respuesta
// ============================================================
localparam TX_IDLE    = 3'd0;
localparam TX_HEADER  = 3'd1;
localparam TX_RESULT  = 3'd2;
localparam TX_FLAGS   = 3'd3;
localparam TX_FOOTER  = 3'd4;
localparam TX_WAIT    = 3'd5;

reg [2:0]  tx_state;
reg [2:0]  tx_byte_idx;
reg [31:0] tx_result_buf;
reg [7:0]  tx_flags_buf;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        tx_state      <= TX_IDLE;
        tx_byte_idx   <= 0;
        tx_send       <= 0;
        tx_byte       <= 8'h00;
        tx_result_buf <= 32'h0;
        tx_flags_buf  <= 8'h00;
    end else begin
        tx_send <= 0;

        case (tx_state)
            TX_IDLE: begin
                if (calc_valid) begin
                    tx_result_buf <= calc_result;
                    tx_flags_buf  <= {calc_nan, calc_overflow, calc_zero,
                                      calc_cmp_eq, calc_cmp_gt, calc_cmp_lt,
                                      2'b00};
                    tx_state      <= TX_HEADER;
                end
            end

            TX_HEADER: begin
                if (!tx_busy) begin
                    tx_byte  <= 8'hBB;
                    tx_send  <= 1;
                    tx_byte_idx <= 0;
                    tx_state <= TX_RESULT;
                end
            end

            TX_RESULT: begin
                if (!tx_busy && !tx_send) begin
                    case (tx_byte_idx)
                        0: tx_byte <= tx_result_buf[31:24];
                        1: tx_byte <= tx_result_buf[23:16];
                        2: tx_byte <= tx_result_buf[15:8];
                        3: tx_byte <= tx_result_buf[7:0];
                    endcase
                    tx_send <= 1;
                    if (tx_byte_idx == 3) begin
                        tx_state <= TX_FLAGS;
                    end else begin
                        tx_byte_idx <= tx_byte_idx + 1;
                    end
                end
            end

            TX_FLAGS: begin
                if (!tx_busy && !tx_send) begin
                    tx_byte  <= tx_flags_buf;
                    tx_send  <= 1;
                    tx_state <= TX_FOOTER;
                end
            end

            TX_FOOTER: begin
                if (!tx_busy && !tx_send) begin
                    tx_byte  <= 8'h66;
                    tx_send  <= 1;
                    tx_state <= TX_IDLE;
                end
            end

            default: tx_state <= TX_IDLE;
        endcase
    end
end

endmodule
