// ============================================================
// uart_rx.v - Receptor UART 8N1
// Reescrito para evitar celdas dfstp en síntesis
// ============================================================
module uart_rx #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115_200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data_out,
    output reg        data_valid
);

localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

/* verilator lint_off WIDTHEXPAND */
reg [15:0] clk_count;
/* verilator lint_on WIDTHEXPAND */

reg [3:0]  bit_index;
reg [7:0]  shift_reg;
reg        receiving;
reg        rx_sync1, rx_sync2;

always @(posedge clk) begin
    if (rst) begin
        rx_sync1   <= 1'b1;
        rx_sync2   <= 1'b1;
        receiving  <= 1'b0;
        data_valid <= 1'b0;
        clk_count  <= 16'h0000;
        bit_index  <= 4'h0;
        data_out   <= 8'h00;
        shift_reg  <= 8'h00;
    end else begin
        rx_sync1   <= rx;
        rx_sync2   <= rx_sync1;
        data_valid <= 1'b0;

        if (!receiving) begin
            if (!rx_sync2) begin
                receiving <= 1'b1;
                clk_count <= 16'h0000;
                bit_index <= 4'h0;
            end
        end else begin
            /* verilator lint_off WIDTHEXPAND */
            if (clk_count < CLKS_PER_BIT - 1) begin
            /* verilator lint_on WIDTHEXPAND */
                clk_count <= clk_count + 16'h0001;
            end else begin
                clk_count <= 16'h0000;
                if (bit_index < 4'd8) begin
                    /* verilator lint_off WIDTHTRUNC */
                    shift_reg[bit_index[2:0]] <= rx_sync2;
                    /* verilator lint_on WIDTHTRUNC */
                    bit_index <= bit_index + 4'h1;
                end else begin
                    if (rx_sync2) begin
                        data_out   <= shift_reg;
                        data_valid <= 1'b1;
                    end
                    receiving <= 1'b0;
                end
            end
        end
    end
end

endmodule
