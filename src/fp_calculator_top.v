// ============================================================
// fp_calculator_top.v
// Calculadora FP16 - 6 operaciones
// FP16: wE=5, wF=10 (IEEE 754 half precision)
// Formato FloPoCo: [12:11]=exc, [10]=signo, [9:5]=exp, [4:0]=mantisa
// ============================================================
// OP[2:0]:
//   000 = ADD  (A + B)
//   001 = SUB  (A - B)
//   010 = MUL  (A * B)
//   011 = DIV  (A / B)
//   100 = SQRT (√A)
//   101 = POW  (A^N, N=B[4:0])
// ============================================================

module fp_calculator_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] A,        // IEEE 754 FP16
    input  wire [15:0] B,        // IEEE 754 FP16
    input  wire [2:0]  OP,
    input  wire        start,
    output reg  [15:0] result,   // IEEE 754 FP16
    output reg         valid,
    output reg         overflow,
    output reg         zero_flag,
    output reg         nan_flag,
    output reg         cmp_gt,
    output reg         cmp_lt,
    output reg         cmp_eq
);

// ============================================================
// Conversión IEEE 754 FP16 ↔ FloPoCo (13 bits)
// IEEE FP16: [15]=sign [14:10]=exp(5) [9:0]=mantisa(10)
// FloPoCo:   [12:11]=exc [10]=sign [9:5]=exp [4:0]=mantisa
// ============================================================
function [12:0] ieee_to_fp16;
    input [15:0] ieee;
    reg [1:0] exc;
    begin
        if      (ieee[14:10]==5'h1F && ieee[9:0]!=0) exc=2'b10; // NaN
        else if (ieee[14:10]==5'h1F && ieee[9:0]==0) exc=2'b01; // Inf
        else if (ieee[14:10]==5'h00 && ieee[9:0]==0) exc=2'b11; // Zero
        else                                          exc=2'b00; // Normal
        ieee_to_fp16 = {exc, ieee[15], ieee[14:0]};
    end
endfunction

function [15:0] fp16_to_ieee;
    input [12:0] fp;
    begin
        case (fp[12:11])
            2'b00:   fp16_to_ieee = {fp[10], fp[9:0], 5'b0}; // bug fix below
            2'b01:   fp16_to_ieee = {fp[10], 5'h1F, 10'h000};
            2'b10:   fp16_to_ieee = 16'h7E00; // NaN canonico
            2'b11:   fp16_to_ieee = {fp[10], 15'h0};
            default: fp16_to_ieee = 16'h7E00;
        endcase
    end
endfunction

// Correccion: FloPoCo guarda los 15 bits de ieee en [14:0]
function [15:0] flopoco_to_ieee;
    input [12:0] fp;
    begin
        case (fp[12:11])
            2'b00:   flopoco_to_ieee = {fp[10], fp[9:0], 5'b0};
            2'b01:   flopoco_to_ieee = {fp[10], 5'h1F, 10'h000};
            2'b10:   flopoco_to_ieee = 16'h7E00;
            2'b11:   flopoco_to_ieee = {fp[10], 15'h0};
            default: flopoco_to_ieee = 16'h7E00;
        endcase
    end
endfunction

// ============================================================
// Señales FloPoCo (13 bits)
// ============================================================
wire [12:0] fp_A     = ieee_to_fp16(A);
wire [12:0] fp_B     = ieee_to_fp16(B);
wire [12:0] fp_B_neg = {fp_B[12:11], ~fp_B[10], fp_B[9:0]};

wire [12:0] add_result, sub_result, mul_result;
wire [12:0] div_result, sqrt_result;

// ============================================================
// Instancias FloPoCo FP16
// ============================================================
FPAdd_5_10_F400_uid2 u_add (
    .clk(clk), .rst(rst),
    .X(fp_A), .Y(fp_B),
    .R(add_result)
);

FPAdd_5_10_F400_uid2 u_sub (
    .clk(clk), .rst(rst),
    .X(fp_A), .Y(fp_B_neg),
    .R(sub_result)
);

FPMult_5_10_5_10_5_10_F400_uid2 u_mul (
    .clk(clk), .rst(rst),
    .X(fp_A), .Y(fp_B),
    .R(mul_result)
);

FPDiv_5_10_F400_uid2 u_div (
    .clk(clk), .rst(rst),
    .X(fp_A), .Y(fp_B),
    .R(div_result)
);

FPSqrt_5_10 u_sqrt (
    .clk(clk), .rst(rst),
    .X(fp_A),
    .R(sqrt_result)
);

// ============================================================
// POW: A^N usando FSM con multiplicador dedicado
// N = B[4:0] como entero (maximo 31)
// ============================================================
localparam [12:0] FP16_ONE = {2'b00, 1'b0, 5'h0F, 10'h000}; // 1.0 en FP16

localparam POW_IDLE = 3'd0;
localparam POW_INIT = 3'd1;
localparam POW_WAIT = 3'd2;
localparam POW_LOAD = 3'd3;
localparam POW_DONE = 3'd4;

reg [2:0]  pow_state;
reg [4:0]  pow_n, pow_count;
reg [12:0] pow_accum, pow_result_reg;
reg [12:0] pow_mul_a_reg, pow_mul_b_reg;
wire [12:0] pow_mul_out;

FPMult_5_10_5_10_5_10_F400_uid2 u_pow_mul (
    .clk(clk), .rst(rst),
    .X(pow_mul_a_reg),
    .Y(pow_mul_b_reg),
    .R(pow_mul_out)
);

always @(posedge clk) begin
    if (rst) begin
        pow_state      <= POW_IDLE;
        pow_n          <= 5'h0;
        pow_count      <= 5'h0;
        pow_accum      <= FP16_ONE;
        pow_result_reg <= FP16_ONE;
        pow_mul_a_reg  <= FP16_ONE;
        pow_mul_b_reg  <= FP16_ONE;
    end else begin
        case (pow_state)
            POW_IDLE: begin
                if (start && OP == 3'b101) begin
                    pow_n     <= B[4:0];
                    pow_count <= 5'h0;
                    pow_accum <= FP16_ONE;
                    pow_state <= POW_INIT;
                end
            end
            POW_INIT: begin
                if (pow_n == 5'h0) begin
                    pow_result_reg <= FP16_ONE;
                    pow_state      <= POW_DONE;
                end else begin
                    pow_mul_a_reg <= FP16_ONE;
                    pow_mul_b_reg <= fp_A;
                    pow_state     <= POW_WAIT;
                end
            end
            POW_WAIT: pow_state <= POW_LOAD;
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
            POW_DONE: pow_state <= POW_IDLE;
            default:  pow_state <= POW_IDLE;
        endcase
    end
end

// ============================================================
// Comparacion FP16
// ============================================================
wire a_nan  = (A[14:10]==5'h1F) && (A[9:0]!=0);
wire b_nan  = (B[14:10]==5'h1F) && (B[9:0]!=0);
wire any_nan   = a_nan || b_nan;
wire a_zero = (A[14:10]==5'h00) && (A[9:0]==0);
wire b_zero = (B[14:10]==5'h00) && (B[9:0]==0);
wire both_zero = a_zero && b_zero;
wire eq_bits   = (A==B) || both_zero;
wire mag_gt    = {A[14:10],A[9:0]} > {B[14:10],B[9:0]};

wire gt_res =
    any_nan    ? 1'b0 :
    both_zero  ? 1'b0 :
    (!A[15] &&  B[15]) ? 1'b1 :
    ( A[15] && !B[15]) ? 1'b0 :
    (!A[15] && !B[15]) ? mag_gt :
                         (!mag_gt && !eq_bits);
wire lt_res = !any_nan && !eq_bits && !gt_res;

// ============================================================
// Seleccion de resultado
// ============================================================
reg [12:0] selected_fp;

always @(*) begin
    case (OP)
        3'b000: selected_fp = add_result;
        3'b001: selected_fp = sub_result;
        3'b010: selected_fp = mul_result;
        3'b011: selected_fp = div_result;
        3'b100: selected_fp = sqrt_result;
        3'b101: selected_fp = pow_result_reg;
        default: selected_fp = {2'b10, 11'h0}; // NaN
    endcase
end

wire res_nan  = (selected_fp[12:11]==2'b10);
wire res_inf  = (selected_fp[12:11]==2'b01);
wire res_zero = (selected_fp[12:11]==2'b11);

// ============================================================
// Registro de salidas
// ============================================================
always @(posedge clk) begin
    if (rst) begin
        result    <= 16'h0;
        valid     <= 1'b0;
        overflow  <= 1'b0;
        zero_flag <= 1'b0;
        nan_flag  <= 1'b0;
        cmp_gt    <= 1'b0;
        cmp_lt    <= 1'b0;
        cmp_eq    <= 1'b0;
    end else if (start) begin
        valid     <= 1'b1;
        nan_flag  <= res_nan || any_nan;
        overflow  <= res_inf;
        zero_flag <= res_zero;
        result    <= flopoco_to_ieee(selected_fp);
        cmp_eq    <= eq_bits && !any_nan;
        cmp_gt    <= gt_res;
        cmp_lt    <= lt_res;
    end else begin
        valid <= 1'b0;
        if (pow_state == POW_DONE && OP == 3'b101) begin
            result    <= flopoco_to_ieee(pow_result_reg);
            valid     <= 1'b1;
            zero_flag <= (pow_result_reg[12:11]==2'b11);
            overflow  <= (pow_result_reg[12:11]==2'b01);
            nan_flag  <= (pow_result_reg[12:11]==2'b10);
        end
    end
end

endmodule
