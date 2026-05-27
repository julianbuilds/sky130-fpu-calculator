// ============================================================
// uart_tx.v - Transmisor UART 8N1
// Reescrito para evitar celdas dfstp en síntesis
// ============================================================
module uart_tx #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 115_200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data_in,
    input  wire       send,
    output reg        tx,
    output reg        busy
);

localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

/* verilator lint_off WIDTHEXPAND */
reg [15:0] clk_count;
/* verilator lint_on WIDTHEXPAND */

reg [3:0]  bit_index;
reg [9:0]  shift_reg;
reg        transmitting;

always @(posedge clk) begin
    if (rst) begin
        tx           <= 1'b1;
        busy         <= 1'b0;
        clk_count    <= 16'h0000;
        bit_index    <= 4'h0;
        shift_reg    <= 10'h3FF;
        transmitting <= 1'b0;
    end else begin
        if (!transmitting && send) begin
            shift_reg    <= {1'b1, data_in, 1'b0};
            clk_count    <= 16'h0000;
            bit_index    <= 4'h0;
            transmitting <= 1'b1;
            busy         <= 1'b1;
            tx           <= 1'b0;
        end else if (transmitting) begin
            /* verilator lint_off WIDTHEXPAND */
            if (clk_count < CLKS_PER_BIT - 1) begin
            /* verilator lint_on WIDTHEXPAND */
                clk_count <= clk_count + 16'h0001;
            end else begin
                clk_count <= 16'h0000;
                if (bit_index < 4'd9) begin
                    bit_index <= bit_index + 4'h1;
                    tx        <= shift_reg[bit_index + 1];
                end else begin
                    tx           <= 1'b1;
                    transmitting <= 1'b0;
                    busy         <= 1'b0;
                end
            end
        end
    end
end

endmodule
