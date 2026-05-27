// ============================================================
// flopoco_stubs.v — Stubs combinacionales para simulación
// Sin pipeline: resultado disponible inmediatamente
// Solo para Icarus Verilog. OpenLane usa los .vhdl reales.
// ============================================================
`timescale 1ns/1ps

// Función compartida de conversión (declarada como macro)
// FloPoCo FP34 [33:32]=exc [31]=sign [30:0]=ieee_body

// ---- FPAdd ------------------------------------------------
module FPAdd_8_23_uid2 (
    input  wire        clk,
    input  wire        rst,
    input  wire [33:0] X,
    input  wire [33:0] Y,
    output wire [33:0] R
);
    // Extraer IEEE 754 de 32 bits desde formato FloPoCo
    wire [31:0] x_ieee = {X[31], X[30:0]};
    wire [31:0] y_ieee = {Y[31], Y[30:0]};

    wire x_nan  = (X[33:32] == 2'b10);
    wire y_nan  = (Y[33:32] == 2'b10);
    wire x_inf  = (X[33:32] == 2'b01);
    wire y_inf  = (Y[33:32] == 2'b01);
    wire x_zero = (X[33:32] == 2'b11);
    wire y_zero = (Y[33:32] == 2'b11);

    // Casos especiales
    wire result_nan = x_nan || y_nan ||
                      (x_inf && y_inf && (X[31] != Y[31]));
    wire result_inf = (x_inf || y_inf) && !result_nan;

    // Suma usando real (solo simulación)
    real xr, yr, rr;
    reg [31:0] r_bits;
    reg [33:0] r_fp;

    always @(*) begin
        if (result_nan) begin
            r_fp = {2'b10, 32'h7FC00000};
        end else if (result_inf) begin
            r_fp = x_inf ? {2'b01, X[31], 31'h7F800000} :
                           {2'b01, Y[31], 31'h7F800000};
        end else if (x_zero && y_zero) begin
            r_fp = {2'b11, 32'h0};
        end else begin
            xr    = $bitstoshortreal(x_zero ? 32'h0 : x_ieee);
            yr    = $bitstoshortreal(y_zero ? 32'h0 : y_ieee);
            rr    = xr + yr;
            r_bits = $shortrealtobits(rr);
            if (r_bits[30:23] == 8'hFF && r_bits[22:0] != 0)
                r_fp = {2'b10, r_bits};
            else if (r_bits[30:23] == 8'hFF)
                r_fp = {2'b01, r_bits};
            else if (r_bits == 32'h0 || r_bits == 32'h80000000)
                r_fp = {2'b11, r_bits};
            else
                r_fp = {2'b00, r_bits};
        end
    end

    assign R = r_fp;
endmodule

// ---- FPMult -----------------------------------------------
module FPMult_8_23_8_23_8_23_F400_uid2 (
    input  wire        clk,
    input  wire        rst,
    input  wire [33:0] X,
    input  wire [33:0] Y,
    output wire [33:0] R
);
    wire [31:0] x_ieee = {X[31], X[30:0]};
    wire [31:0] y_ieee = {Y[31], Y[30:0]};

    wire x_nan  = (X[33:32] == 2'b10);
    wire y_nan  = (Y[33:32] == 2'b10);
    wire x_inf  = (X[33:32] == 2'b01);
    wire y_inf  = (Y[33:32] == 2'b01);
    wire x_zero = (X[33:32] == 2'b11);
    wire y_zero = (Y[33:32] == 2'b11);

    wire result_nan = x_nan || y_nan ||
                      (x_inf && y_zero) || (x_zero && y_inf);
    wire result_inf = (x_inf || y_inf) && !result_nan;
    wire result_zero = (x_zero || y_zero) && !result_nan;
    wire res_sign = X[31] ^ Y[31];

    real xr, yr, rr;
    reg [31:0] r_bits;
    reg [33:0] r_fp;

    always @(*) begin
        if (result_nan)
            r_fp = {2'b10, 32'h7FC00000};
        else if (result_inf)
            r_fp = {2'b01, res_sign, 31'h7F800000};
        else if (result_zero)
            r_fp = {2'b11, res_sign, 31'h0};
        else begin
            xr     = $bitstoshortreal(x_ieee);
            yr     = $bitstoshortreal(y_ieee);
            rr     = xr * yr;
            r_bits = $shortrealtobits(rr);
            if (r_bits[30:23] == 8'hFF && r_bits[22:0] != 0)
                r_fp = {2'b10, r_bits};
            else if (r_bits[30:23] == 8'hFF)
                r_fp = {2'b01, r_bits};
            else if (r_bits[30:23] == 8'h00 && r_bits[22:0] == 0)
                r_fp = {2'b11, r_bits};
            else
                r_fp = {2'b00, r_bits};
        end
    end

    assign R = r_fp;
endmodule

// ---- FPDiv ------------------------------------------------
module FPDiv_8_23_uid2 (
    input  wire        clk,
    input  wire        rst,
    input  wire [33:0] X,
    input  wire [33:0] Y,
    output wire [33:0] R
);
    wire [31:0] x_ieee = {X[31], X[30:0]};
    wire [31:0] y_ieee = {Y[31], Y[30:0]};

    wire x_nan  = (X[33:32] == 2'b10);
    wire y_nan  = (Y[33:32] == 2'b10);
    wire x_zero = (X[33:32] == 2'b11);
    wire y_zero = (Y[33:32] == 2'b11);
    wire x_inf  = (X[33:32] == 2'b01);
    wire y_inf  = (Y[33:32] == 2'b01);
    wire res_sign = X[31] ^ Y[31];

    wire result_nan  = x_nan || y_nan || (x_zero && y_zero) || (x_inf && y_inf);
    wire result_inf  = (y_zero && !x_zero) || (x_inf && !y_inf);
    wire result_zero = (x_zero && !y_zero) || (y_inf && !x_inf);

    real xr, yr, rr;
    reg [31:0] r_bits;
    reg [33:0] r_fp;

    always @(*) begin
        if (result_nan)
            r_fp = {2'b10, 32'h7FC00000};
        else if (result_inf)
            r_fp = {2'b01, res_sign, 31'h7F800000};
        else if (result_zero)
            r_fp = {2'b11, res_sign, 31'h0};
        else begin
            xr     = $bitstoshortreal(x_ieee);
            yr     = $bitstoshortreal(y_ieee);
            rr     = xr / yr;
            r_bits = $shortrealtobits(rr);
            if (r_bits[30:23] == 8'hFF && r_bits[22:0] != 0)
                r_fp = {2'b10, r_bits};
            else if (r_bits[30:23] == 8'hFF)
                r_fp = {2'b01, r_bits};
            else if (r_bits[30:23] == 8'h00 && r_bits[22:0] == 0)
                r_fp = {2'b11, r_bits};
            else
                r_fp = {2'b00, r_bits};
        end
    end

    assign R = r_fp;
endmodule

// ---- FPSqrt -----------------------------------------------
module FPSqrt_8_23_uid2 (
    input  wire        clk,
    input  wire        rst,
    input  wire [33:0] X,
    output wire [33:0] R
);
    wire [31:0] x_ieee = {X[31], X[30:0]};
    wire x_nan  = (X[33:32] == 2'b10);
    wire x_zero = (X[33:32] == 2'b11);
    wire x_inf  = (X[33:32] == 2'b01);
    wire x_neg  = X[31] && (X[33:32] == 2'b00);

    real xr, rr;
    reg [31:0] r_bits;
    reg [33:0] r_fp;

    always @(*) begin
        if (x_nan || x_neg)
            r_fp = {2'b10, 32'h7FC00000};
        else if (x_zero)
            r_fp = {2'b11, 32'h0};
        else if (x_inf)
            r_fp = {2'b01, 32'h7F800000};
        else begin
            xr     = $bitstoshortreal(x_ieee);
            rr     = $sqrt(xr);
            r_bits = $shortrealtobits(rr);
            r_fp   = {2'b00, r_bits};
        end
    end

    assign R = r_fp;
endmodule

// ---- FPSinCos ---------------------------------------------
module FPSinCos_8_23_uid2 (
    input  wire        clk,
    input  wire        rst,
    input  wire [33:0] X,
    output wire [33:0] S,
    output wire [33:0] C
);
    wire [31:0] x_ieee = {X[31], X[30:0]};
    wire x_nan  = (X[33:32] == 2'b10);
    wire x_zero = (X[33:32] == 2'b11);

    real xr, sr, cr;
    reg [31:0] s_bits, c_bits;
    reg [33:0] s_fp, c_fp;

    always @(*) begin
        if (x_nan) begin
            s_fp = {2'b10, 32'h7FC00000};
            c_fp = {2'b10, 32'h7FC00000};
        end else if (x_zero) begin
            s_fp = {2'b11, 32'h00000000}; // sin(0)=0
            c_fp = {2'b00, 32'h3F800000}; // cos(0)=1
        end else begin
            xr     = $bitstoshortreal(x_ieee);
            sr     = $sin(xr);
            cr     = $cos(xr);
            s_bits = $shortrealtobits(sr);
            c_bits = $shortrealtobits(cr);
            // sin
            if      (s_bits[30:23]==8'hFF && s_bits[22:0]!=0) s_fp={2'b10,s_bits};
            else if (s_bits[30:23]==8'h00 && s_bits[22:0]==0) s_fp={2'b11,s_bits};
            else                                               s_fp={2'b00,s_bits};
            // cos
            if      (c_bits[30:23]==8'hFF && c_bits[22:0]!=0) c_fp={2'b10,c_bits};
            else if (c_bits[30:23]==8'h00 && c_bits[22:0]==0) c_fp={2'b11,c_bits};
            else                                               c_fp={2'b00,c_bits};
        end
    end

    assign S = s_fp;
    assign C = c_fp;
endmodule
