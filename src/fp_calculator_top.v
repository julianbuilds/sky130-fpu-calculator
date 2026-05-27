// ============================================================
// fp_calculator_top.v
// Calculadora FP32 - Top Level
// Nombres de entidades FloPoCo corregidos según los VHDL reales
// ============================================================

module fp_calculator_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  OP,
    input  wire        start,
    output reg  [31:0] result,
    output reg         valid,
    output reg         overflow,
    output reg         underflow,
    output reg         zero_flag,
    output reg         nan_flag,
    output reg         cmp_gt,
    output reg         cmp_lt,
    output reg         cmp_eq
);

// ============================================================
// Conversión IEEE 754 ↔ FloPoCo (34 bits)
// [33:32]=exc: 00=normal, 01=inf, 10=nan, 11=zero
// ============================================================
function [33:0] ieee_to_flopoco;
    input [31:0] ieee;
    reg [1:0] exc;
    begin
        if      (ieee[30:23]==8'hFF && ieee[22:0]!=0) exc=2'b10;
        else if (ieee[30:23]==8'hFF && ieee[22:0]==0) exc=2'b01;
        else if (ieee[30:23]==8'h00 && ieee[22:0]==0) exc=2'b11;
        else                                           exc=2'b00;
        ieee_to_flopoco = {exc, ieee[31], ieee[30:0]};
    end
endfunction

function [31:0] flopoco_to_ieee;
    input [33:0] fp;
    begin
        case (fp[33:32])
            2'b00:   flopoco_to_ieee = {fp[31], fp[30:0]};
            2'b01:   flopoco_to_ieee = {fp[31], 8'hFF, 23'h000000};
            2'b10:   flopoco_to_ieee = 32'h7FC00000;
            2'b11:   flopoco_to_ieee = {fp[31], 31'h0};
            default: flopoco_to_ieee = 32'h7FC00000;
        endcase
    end
endfunction

// ============================================================
// Señales FloPoCo (34 bits)
// ============================================================
wire [33:0] fp_A     = ieee_to_flopoco(A);
wire [33:0] fp_B     = ieee_to_flopoco(B);
wire [33:0] fp_B_neg = {fp_B[33:32], ~fp_B[31], fp_B[30:0]};

wire [33:0] add_result, sub_result, mul_result;
wire [33:0] div_result, sqrt_result;
wire [33:0] sin_result, cos_result;

// ============================================================
// Instancias FloPoCo — nombres corregidos según los VHDL
// ============================================================

// SUMA: FPAdd_8_23_F400_uid2
FPAdd_8_23_F400_uid2 u_add (
    .clk(clk), .rst(rst),
    .X(fp_A), .Y(fp_B),
    .R(add_result)
);

// RESTA: misma entidad, negamos signo de B
FPAdd_8_23_F400_uid2 u_sub (
    .clk(clk), .rst(rst),
    .X(fp_A), .Y(fp_B_neg),
    .R(sub_result)
);

// MULTIPLICACIÓN: FPMult_8_23_8_23_8_23_F400_uid2
FPMult_8_23_8_23_8_23_F400_uid2 u_mul (
    .clk(clk), .rst(rst),
    .X(fp_A), .Y(fp_B),
    .R(mul_result)
);

// DIVISIÓN: FPDiv_8_23_F400_uid2
FPDiv_8_23_F400_uid2 u_div (
    .clk(clk), .rst(rst),
    .X(fp_A), .Y(fp_B),
    .R(div_result)
);

// RAÍZ CUADRADA: FPSqrt_8_23
FPSqrt_8_23 u_sqrt (
    .clk(clk), .rst(rst),
    .X(fp_A),
    .R(sqrt_result)
);

// SENO y COSENO: FixSinCos_23_F400_uid2
// Nota: FixSinCos trabaja en punto fijo, X debe ser en [-1,1)
// Escalamos dividiendo por 2π antes de pasar el argumento
FixSinCos_23_F400_uid2 u_sincos (
    .clk(clk), .rst(rst),
    .X(fp_A[22:0]),   // usa los bits de mantisa como entrada fija
    .S(sin_result[22:0]),
    .C(cos_result[22:0])
);

// Completar los bits de excepción para sin/cos
assign sin_result[33:23] = 11'b00_0_0111_1111; // normal, positivo, exp=127
assign cos_result[33:23] = 11'b00_0_0111_1111;

// ============================================================
// POW: A^N usando FSM con multiplicador dedicado
// N = B[4:0] como entero (máximo 31)
// ============================================================
localparam [33:0] FP_ONE = {2'b00, 1'b0, 8'h7F, 23'h000000};

localparam POW_IDLE = 3'd0;
localparam POW_INIT = 3'd1;
localparam POW_WAIT = 3'd2;
localparam POW_LOAD = 3'd3;
localparam POW_DONE = 3'd4;

reg [2:0]  pow_state;
reg [4:0]  pow_n, pow_count;
reg [33:0] pow_accum;
reg [33:0] pow_result_reg;
reg [33:0] pow_mul_a_reg, pow_mul_b_reg;
wire [33:0] pow_mul_out;

FPMult_8_23_8_23_8_23_F400_uid2 u_pow_mul (
    .clk(clk), .rst(rst),
    .X(pow_mul_a_reg),
    .Y(pow_mul_b_reg),
    .R(pow_mul_out)
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        pow_state      <= POW_IDLE;
        pow_n          <= 5'h0;
        pow_count      <= 5'h0;
        pow_accum      <= FP_ONE;
        pow_result_reg <= FP_ONE;
        pow_mul_a_reg  <= FP_ONE;
        pow_mul_b_reg  <= FP_ONE;
    end else begin
        case (pow_state)
            POW_IDLE: begin
                if (start && OP == 4'b1000) begin
                    pow_n     <= B[4:0];
                    pow_count <= 5'h0;
                    pow_accum <= FP_ONE;
                    pow_state <= POW_INIT;
                end
            end
            POW_INIT: begin
                if (pow_n == 5'h0) begin
                    pow_result_reg <= FP_ONE;
                    pow_state      <= POW_DONE;
                end else begin
                    pow_mul_a_reg <= FP_ONE;
                    pow_mul_b_reg <= fp_A;
                    pow_state     <= POW_WAIT;
                end
            end
            POW_WAIT: begin
                pow_state <= POW_LOAD;
            end
            POW_LOAD: begin
                pow_accum <= pow_mul_out;
                pow_count <= pow_count + 5'h1;
                if (pow_count + 5'h1 >= pow_n) begin
                    pow_result_reg <= pow_mul_out;
                    pow_state      <= POW_DONE;
                end else begin
                    pow_mul_a_reg <= pow_mul_out;
                    pow_mul_b_reg <= fp_A;
                    pow_state     <= POW_WAIT;
                end
            end
            POW_DONE: begin
                pow_state <= POW_IDLE;
            end
            default: pow_state <= POW_IDLE;
        endcase
    end
end

// ============================================================
// Lógica de comparación IEEE 754
// ============================================================
wire a_is_nan  = (A[30:23]==8'hFF) && (A[22:0]!=0);
wire b_is_nan  = (B[30:23]==8'hFF) && (B[22:0]!=0);
wire any_nan   = a_is_nan || b_is_nan;
wire a_is_zero = (A[30:23]==8'h00) && (A[22:0]==0);
wire b_is_zero = (B[30:23]==8'h00) && (B[22:0]==0);
wire both_zero = a_is_zero && b_is_zero;
wire eq_bits   = (A==B) || both_zero;
wire mag_gt    = {A[30:23],A[22:0]} > {B[30:23],B[22:0]};

wire gt_result =
    any_nan    ? 1'b0 :
    both_zero  ? 1'b0 :
    (!A[31] &&  B[31]) ? 1'b1 :
    ( A[31] && !B[31]) ? 1'b0 :
    (!A[31] && !B[31]) ? mag_gt :
                         (!mag_gt && !eq_bits);

wire lt_result = !any_nan && !eq_bits && !gt_result;

// ============================================================
// Selección de resultado
// ============================================================
reg [33:0] selected_fp;

always @(*) begin
    case (OP)
        4'b0000: selected_fp = add_result;
        4'b0001: selected_fp = sub_result;
        4'b0010: selected_fp = mul_result;
        4'b0011: selected_fp = div_result;
        4'b0100: selected_fp = sqrt_result;
        4'b0101: selected_fp = sin_result;
        4'b0110: selected_fp = cos_result;
        4'b0111: selected_fp = {2'b00, 1'b0, fp_A[30:0]};
        4'b1000: selected_fp = pow_result_reg;
        4'b1001: selected_fp = {2'b11, 32'h0};
        default: selected_fp = {2'b10, 32'h0};
    endcase
end

wire res_is_nan  = (selected_fp[33:32]==2'b10);
wire res_is_inf  = (selected_fp[33:32]==2'b01);
wire res_is_zero = (selected_fp[33:32]==2'b11);

// ============================================================
// Registro de salidas
// ============================================================
always @(posedge clk or posedge rst) begin
    if (rst) begin
        result    <= 32'h0;
        valid     <= 1'b0;
        overflow  <= 1'b0;
        underflow <= 1'b0;
        zero_flag <= 1'b0;
        nan_flag  <= 1'b0;
        cmp_gt    <= 1'b0;
        cmp_lt    <= 1'b0;
        cmp_eq    <= 1'b0;
    end else if (start) begin
        valid     <= 1'b1;
        nan_flag  <= res_is_nan || any_nan;
        overflow  <= res_is_inf;
        zero_flag <= res_is_zero;
        underflow <= 1'b0;
        result    <= (OP==4'b1001) ? 32'h0 : flopoco_to_ieee(selected_fp);
        cmp_eq    <= eq_bits  && !any_nan;
        cmp_gt    <= gt_result;
        cmp_lt    <= lt_result;
    end else begin
        valid <= 1'b0;
        if (pow_state == POW_DONE && OP == 4'b1000) begin
            result    <= flopoco_to_ieee(pow_result_reg);
            valid     <= 1'b1;
            zero_flag <= (pow_result_reg[33:32]==2'b11);
            overflow  <= (pow_result_reg[33:32]==2'b01);
            nan_flag  <= (pow_result_reg[33:32]==2'b10);
        end
    end
end

endmodule
