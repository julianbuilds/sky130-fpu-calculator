// ============================================================
// uart_controller.v
// Protocolo PC ↔ Calculadora FP16
// ============================================================
// Paquete TX (PC → Chip):
//   Byte 0:   0xAA (header)
//   Byte 1:   {5'b0, OP[2:0]}
//   Byte 2-3: A[15:0] big-endian
//   Byte 4-5: B[15:0] big-endian
//   Byte 6:   0x55 (footer)
//
// Paquete RX (Chip → PC):
//   Byte 0:   0xBB (header)
//   Byte 1-2: Result[15:0] big-endian
//   Byte 3:   flags {nan,ovf,zero,cmp_eq,cmp_gt,cmp_lt,0,0}
//   Byte 4:   0x66 (footer)
// ============================================================

module uart_controller #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115_200
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        uart_rx_pin,
    output wire        uart_tx_pin,
    output reg  [15:0] calc_A,
    output reg  [15:0] calc_B,
    output reg  [2:0]  calc_op,
    output reg         calc_start,
    input  wire [15:0] calc_result,
    input  wire        calc_valid,
    input  wire        calc_overflow,
    input  wire        calc_underflow,
    input  wire        calc_zero,
    input  wire        calc_nan,
    input  wire        calc_cmp_gt,
    input  wire        calc_cmp_lt,
    input  wire        calc_cmp_eq
);

wire [7:0] rx_byte;
wire       rx_valid;

uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_rx (
    .clk(clk), .rst(rst),
    .rx(uart_rx_pin),
    .data_out(rx_byte),
    .data_valid(rx_valid)
);

reg  [7:0] tx_byte;
reg        tx_send;
wire       tx_busy;

uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_tx (
    .clk(clk), .rst(rst),
    .data_in(tx_byte),
    .send(tx_send),
    .tx(uart_tx_pin),
    .busy(tx_busy)
);

// ============================================================
// FSM RX
// ============================================================
localparam RX_IDLE   = 3'd0;
localparam RX_OP     = 3'd1;
localparam RX_A      = 3'd2;
localparam RX_B      = 3'd3;
localparam RX_FOOTER = 3'd4;

reg [2:0] rx_state;
reg [1:0] rx_byte_cnt;
reg [15:0] reg_A, reg_B;
reg [2:0]  reg_op;

always @(posedge clk) begin
    if (rst) begin
        rx_state   <= RX_IDLE;
        rx_byte_cnt<= 2'h0;
        reg_A      <= 16'h0;
        reg_B      <= 16'h0;
        reg_op     <= 3'h0;
        calc_start <= 1'b0;
        calc_A     <= 16'h0;
        calc_B     <= 16'h0;
        calc_op    <= 3'h0;
    end else begin
        calc_start <= 1'b0;
        if (rx_valid) begin
            case (rx_state)
                RX_IDLE: begin
                    if (rx_byte == 8'hAA)
                        rx_state <= RX_OP;
                end
                RX_OP: begin
                    reg_op      <= rx_byte[2:0];
                    rx_byte_cnt <= 2'h0;
                    rx_state    <= RX_A;
                end
                RX_A: begin
                    if (rx_byte_cnt == 2'h0) reg_A[15:8] <= rx_byte;
                    else                      reg_A[7:0]  <= rx_byte;
                    if (rx_byte_cnt == 2'h1) begin
                        rx_byte_cnt <= 2'h0;
                        rx_state    <= RX_B;
                    end else
                        rx_byte_cnt <= rx_byte_cnt + 2'h1;
                end
                RX_B: begin
                    if (rx_byte_cnt == 2'h0) reg_B[15:8] <= rx_byte;
                    else                      reg_B[7:0]  <= rx_byte;
                    if (rx_byte_cnt == 2'h1) begin
                        rx_byte_cnt <= 2'h0;
                        rx_state    <= RX_FOOTER;
                    end else
                        rx_byte_cnt <= rx_byte_cnt + 2'h1;
                end
                RX_FOOTER: begin
                    if (rx_byte == 8'h55) begin
                        calc_A     <= reg_A;
                        calc_B     <= reg_B;
                        calc_op    <= reg_op;
                        calc_start <= 1'b1;
                    end
                    rx_state <= RX_IDLE;
                end
                default: rx_state <= RX_IDLE;
            endcase
        end
    end
end

// ============================================================
// FSM TX
// ============================================================
localparam TX_IDLE   = 3'd0;
localparam TX_HEADER = 3'd1;
localparam TX_RESULT = 3'd2;
localparam TX_FLAGS  = 3'd3;
localparam TX_FOOTER = 3'd4;

reg [2:0]  tx_state;
reg [1:0]  tx_byte_idx;
reg [15:0] tx_result_buf;
reg [7:0]  tx_flags_buf;

always @(posedge clk) begin
    if (rst) begin
        tx_state      <= TX_IDLE;
        tx_byte_idx   <= 2'h0;
        tx_send       <= 1'b0;
        tx_byte       <= 8'h00;
        tx_result_buf <= 16'h0;
        tx_flags_buf  <= 8'h00;
    end else begin
        tx_send <= 1'b0;
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
                    tx_byte     <= 8'hBB;
                    tx_send     <= 1'b1;
                    tx_byte_idx <= 2'h0;
                    tx_state    <= TX_RESULT;
                end
            end
            TX_RESULT: begin
                if (!tx_busy && !tx_send) begin
                    tx_byte <= (tx_byte_idx == 2'h0) ?
                                tx_result_buf[15:8] : tx_result_buf[7:0];
                    tx_send <= 1'b1;
                    if (tx_byte_idx == 2'h1)
                        tx_state <= TX_FLAGS;
                    else
                        tx_byte_idx <= tx_byte_idx + 2'h1;
                end
            end
            TX_FLAGS: begin
                if (!tx_busy && !tx_send) begin
                    tx_byte  <= tx_flags_buf;
                    tx_send  <= 1'b1;
                    tx_state <= TX_FOOTER;
                end
            end
            TX_FOOTER: begin
                if (!tx_busy && !tx_send) begin
                    tx_byte  <= 8'h66;
                    tx_send  <= 1'b1;
                    tx_state <= TX_IDLE;
                end
            end
            default: tx_state <= TX_IDLE;
        endcase
    end
end

endmodule
