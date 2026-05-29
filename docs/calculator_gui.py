#!/usr/bin/env python3
# ============================================================
# calculator_gui.py
# Calculadora FP16 - GUI con Tkinter
# Operaciones: +, -, *, /, sqrt, pow
# Comunicacion UART con el chip ASIC
# pip install pyserial
# ============================================================

import tkinter as tk
from tkinter import ttk, messagebox
import struct
import serial
import serial.tools.list_ports
import threading
import math

# ============================================================
# Protocolo UART FP16
# ============================================================
HEADER_TX = 0xAA
FOOTER_TX = 0x55
HEADER_RX = 0xBB
FOOTER_RX = 0x66

OP_ADD  = 0x0
OP_SUB  = 0x1
OP_MUL  = 0x2
OP_DIV  = 0x3
OP_SQRT = 0x4
OP_POW  = 0x5

def float_to_fp16_bytes(f):
    """Convierte float Python a 2 bytes FP16 big-endian"""
    import struct
    f32 = struct.pack('>f', f)
    val = struct.unpack('>I', f32)[0]
    sign = (val >> 31) & 0x1
    exp  = ((val >> 23) & 0xFF) - 127 + 15
    mant = (val >> 13) & 0x3FF
    if exp <= 0:
        fp16 = (sign << 15)
    elif exp >= 31:
        fp16 = (sign << 15) | (0x1F << 10)
    else:
        fp16 = (sign << 15) | (exp << 10) | mant
    return struct.pack('>H', fp16)

def fp16_bytes_to_float(b):
    """Convierte 2 bytes FP16 big-endian a float Python"""
    import struct
    val  = struct.unpack('>H', b)[0]
    sign = (val >> 15) & 0x1
    exp  = (val >> 10) & 0x1F
    mant = val & 0x3FF
    if exp == 0:
        result = ((-1)**sign) * (mant / 1024.0) * (2**(-14))
    elif exp == 31:
        result = float('inf') if mant == 0 else float('nan')
    else:
        result = ((-1)**sign) * (1 + mant/1024.0) * (2**(exp-15))
    return result

def send_operation(ser, op, a, b=0.0):
    pkt = bytes([HEADER_TX, op]) + float_to_fp16_bytes(a) + float_to_fp16_bytes(b) + bytes([FOOTER_TX])
    ser.write(pkt)
    ser.flush()
    resp = ser.read(5)
    if len(resp) != 5 or resp[0] != HEADER_RX or resp[4] != FOOTER_RX:
        raise ValueError("Respuesta invalida del chip")
    result = fp16_bytes_to_float(resp[1:3])
    flags  = resp[3]
    return (result,
            bool(flags & 0x80), bool(flags & 0x40), bool(flags & 0x20),
            bool(flags & 0x10), bool(flags & 0x08), bool(flags & 0x04))

def simulate_operation(op, a, b=0.0):
    try:
        if   op == OP_ADD:  return a+b,  False, False, (a+b)==0,  False, False, False
        elif op == OP_SUB:  return a-b,  False, False, (a-b)==0,  False, False, False
        elif op == OP_MUL:  return a*b,  False, False, (a*b)==0,  False, False, False
        elif op == OP_DIV:
            if b == 0:      return float('inf'), False, True, False, False, False, False
            return a/b, False, False, False, False, False, False
        elif op == OP_SQRT:
            if a < 0:       return float('nan'), True, False, False, False, False, False
            return math.sqrt(a), False, False, a==0, False, False, False
        elif op == OP_POW:  return a**int(b), False, False, False, False, False, False
    except:
        return float('nan'), True, False, False, False, False, False

# ============================================================
# GUI
# ============================================================
class CalculatorApp:
    def __init__(self, root):
        self.root       = root
        self.root.title("FP16 ASIC Calculator")
        self.root.resizable(False, False)
        self.root.configure(bg="#1e1e2e")

        self.serial_conn = None
        self.sim_mode    = True
        self.operand_a   = None
        self.pending_op  = None
        self.new_number  = True

        self.COLORS = {
            "bg":      "#1e1e2e",
            "display": "#181825",
            "btn_num": "#313244",
            "btn_op":  "#89b4fa",
            "btn_fn":  "#a6e3a1",
            "btn_spec":"#f38ba8",
            "btn_eq":  "#fab387",
            "text":    "#cdd6f4",
            "dark":    "#1e1e2e",
            "accent":  "#cba6f7",
        }
        self._build_ui()

    def _build_ui(self):
        C = self.COLORS

        tk.Label(self.root, text="⚡ FP16 ASIC Calculator",
                 bg=C["bg"], fg=C["accent"],
                 font=("Consolas", 13, "bold")).pack(pady=(12,0))

        # Conexion serial
        cf = tk.Frame(self.root, bg=C["bg"])
        cf.pack(padx=15, pady=6, fill="x")
        tk.Label(cf, text="Puerto:", bg=C["bg"], fg=C["text"],
                 font=("Consolas", 9)).pack(side="left")
        self.port_var = tk.StringVar()
        self.port_cb  = ttk.Combobox(cf, textvariable=self.port_var,
                                      width=10, font=("Consolas", 9))
        self.port_cb.pack(side="left", padx=4)
        self._refresh_ports()
        tk.Button(cf, text="↺", command=self._refresh_ports,
                  bg=C["btn_num"], fg=C["text"],
                  font=("Consolas", 9), relief="flat", padx=4).pack(side="left")
        self.connect_btn = tk.Button(cf, text="Conectar",
                                      command=self._toggle_connection,
                                      bg=C["btn_op"], fg=C["dark"],
                                      font=("Consolas", 9, "bold"),
                                      relief="flat", padx=8)
        self.connect_btn.pack(side="left", padx=6)
        self.status_lbl = tk.Label(cf, text="● Simulado",
                                    bg=C["bg"], fg=C["btn_fn"],
                                    font=("Consolas", 9))
        self.status_lbl.pack(side="left")

        # Display
        df = tk.Frame(self.root, bg=C["display"])
        df.pack(padx=15, pady=6, fill="x")
        self.expr_lbl = tk.Label(df, text="", bg=C["display"], fg="#585b70",
                                  font=("Consolas", 11), anchor="e", width=26)
        self.expr_lbl.pack(padx=10, pady=(8,0), fill="x")
        self.main_display = tk.Label(df, text="0", bg=C["display"], fg=C["text"],
                                      font=("Consolas", 32, "bold"),
                                      anchor="e", width=26)
        self.main_display.pack(padx=10, pady=(0,4), fill="x")
        self.flag_lbl = tk.Label(df, text="FP16 Mode",
                                  bg=C["display"], fg="#585b70",
                                  font=("Consolas", 9), anchor="e")
        self.flag_lbl.pack(padx=10, pady=(0,6), fill="x")

        # Botones
        bf = tk.Frame(self.root, bg=C["bg"])
        bf.pack(padx=15, pady=4)

        buttons = [
            # Fila 0
            ("√",   "sqrt", "btn_fn",   0, 0, 1),
            ("xⁿ",  "pow",  "btn_fn",   1, 0, 1),
            ("AC",  "ac",   "btn_spec", 2, 0, 1),
            ("⌫",  "del",  "btn_spec", 3, 0, 1),
            # Fila 1
            ("7",   "7",    "btn_num",  0, 1, 1),
            ("8",   "8",    "btn_num",  1, 1, 1),
            ("9",   "9",    "btn_num",  2, 1, 1),
            ("÷",   "/",    "btn_op",   3, 1, 1),
            # Fila 2
            ("4",   "4",    "btn_num",  0, 2, 1),
            ("5",   "5",    "btn_num",  1, 2, 1),
            ("6",   "6",    "btn_num",  2, 2, 1),
            ("×",   "*",    "btn_op",   3, 2, 1),
            # Fila 3
            ("1",   "1",    "btn_num",  0, 3, 1),
            ("2",   "2",    "btn_num",  1, 3, 1),
            ("3",   "3",    "btn_num",  2, 3, 1),
            ("−",   "-",    "btn_op",   3, 3, 1),
            # Fila 4
            ("0",   "0",    "btn_num",  0, 4, 2),
            (".",   ".",    "btn_num",  2, 4, 1),
            ("+",   "+",    "btn_op",   3, 4, 1),
            # Fila 5
            ("=",   "=",    "btn_eq",   0, 5, 4),
        ]

        for (text, action, ck, col, row, span) in buttons:
            dark = ck in ("btn_op","btn_fn","btn_eq","btn_spec")
            btn = tk.Button(bf, text=text,
                            command=lambda a=action: self._on_button(a),
                            bg=C[ck], fg=C["dark"] if dark else C["text"],
                            font=("Consolas", 14, "bold"), relief="flat",
                            width=4*span, height=2, cursor="hand2",
                            activebackground=C["accent"],
                            activeforeground=C["dark"])
            btn.grid(row=row, column=col, columnspan=span, padx=3, pady=3)

        # Historial
        lf = tk.Frame(self.root, bg=C["bg"])
        lf.pack(padx=15, pady=(4,12), fill="x")
        tk.Label(lf, text="Historial:", bg=C["bg"], fg=C["accent"],
                 font=("Consolas", 9, "bold")).pack(anchor="w")
        self.log = tk.Text(lf, height=4, width=38,
                            bg=C["display"], fg=C["text"],
                            font=("Consolas", 9), relief="flat",
                            state="disabled")
        self.log.pack(fill="x")

        self.root.bind("<Key>", self._on_key)

    def _on_button(self, action):
        if action in "0123456789":  self._digit(action)
        elif action == ".":          self._dot()
        elif action in "+−-*/":      self._operator(action)
        elif action == "=":          self._calculate()
        elif action == "ac":         self._clear()
        elif action == "del":        self._delete()
        elif action == "sqrt":       self._unary(OP_SQRT, "√")
        elif action == "pow":        self._operator("^")

    def _on_key(self, e):
        k = e.char
        if k in "0123456789":   self._on_button(k)
        elif k == ".":           self._on_button(".")
        elif k in "+-*/":        self._on_button(k)
        elif k in ("\r","\n"):   self._on_button("=")
        elif e.keysym=="BackSpace": self._on_button("del")
        elif e.keysym=="Escape":    self._on_button("ac")

    def _get_val(self):
        try: return float(self.main_display.cget("text"))
        except: return 0.0

    def _set_val(self, v):
        if isinstance(v, float):
            t = str(int(v)) if v == int(v) and abs(v) < 1e6 else f"{v:.6g}"
        else:
            t = str(v)
        self.main_display.config(text=t, fg=self.COLORS["text"])

    def _digit(self, d):
        cur = self.main_display.cget("text")
        if self.new_number or cur == "0":
            self.main_display.config(text=d)
            self.new_number = False
        elif len(cur) < 14:
            self.main_display.config(text=cur+d)

    def _dot(self):
        cur = self.main_display.cget("text")
        if self.new_number:
            self.main_display.config(text="0.")
            self.new_number = False
        elif "." not in cur:
            self.main_display.config(text=cur+".")

    def _operator(self, op):
        self.operand_a  = self._get_val()
        self.pending_op = op
        self.new_number = True
        sym = {"+":"＋","-":"－","*":"×","/":"÷","^":"^"}
        self.expr_lbl.config(text=f"{self.operand_a} {sym.get(op,op)}")
        self.flag_lbl.config(text="FP16 Mode")

    def _calculate(self):
        if self.operand_a is None or self.pending_op is None: return
        b = self._get_val()
        a = self.operand_a
        op_map = {"+":OP_ADD,"-":OP_SUB,"*":OP_MUL,"/":OP_DIV,"^":OP_POW}
        op = op_map.get(self.pending_op)
        if op is None: return
        self._run(op, a, b)
        self.operand_a  = None
        self.pending_op = None

    def _unary(self, op, label):
        a = self._get_val()
        self.expr_lbl.config(text=f"{label}({a})")
        self._run(op, a, 0.0)

    def _clear(self):
        self.main_display.config(text="0")
        self.expr_lbl.config(text="")
        self.flag_lbl.config(text="FP16 Mode")
        self.operand_a  = None
        self.pending_op = None
        self.new_number = True

    def _delete(self):
        cur = self.main_display.cget("text")
        self.main_display.config(text=cur[:-1] if len(cur)>1 else "0")

    def _run(self, op, a, b):
        def task():
            try:
                if self.sim_mode or self.serial_conn is None:
                    res, nan_f, ovf_f, zero_f, eq_f, gt_f, lt_f = simulate_operation(op, a, b)
                else:
                    res, nan_f, ovf_f, zero_f, eq_f, gt_f, lt_f = send_operation(self.serial_conn, op, a, b)
                self.root.after(0, lambda: self._show(res, nan_f, ovf_f, zero_f, eq_f, gt_f, lt_f, op, a, b))
            except Exception as e:
                self.root.after(0, lambda: self._err(str(e)))
        threading.Thread(target=task, daemon=True).start()

    def _show(self, res, nan_f, ovf_f, zero_f, eq_f, gt_f, lt_f, op, a, b):
        C = self.COLORS
        if nan_f or (isinstance(res, float) and math.isnan(res)):
            self.main_display.config(text="NaN", fg=C["btn_spec"])
        elif ovf_f or (isinstance(res, float) and math.isinf(res)):
            self.main_display.config(text="∞", fg=C["btn_fn"])
        else:
            self._set_val(res)

        flags = ""
        if nan_f:  flags += "NaN "
        if ovf_f:  flags += "OVF "
        if zero_f: flags += "ZERO "
        self.flag_lbl.config(text=flags if flags else "FP16 Mode")
        self.new_number = True

        names = {OP_ADD:"ADD",OP_SUB:"SUB",OP_MUL:"MUL",
                 OP_DIV:"DIV",OP_SQRT:"SQRT",OP_POW:"POW"}
        entry = f"[{names.get(op,'?')}] {a}"
        if op not in (OP_SQRT,):
            entry += f" , {b}"
        entry += f" = {res}\n"
        self.log.config(state="normal")
        self.log.insert("end", entry)
        self.log.see("end")
        self.log.config(state="disabled")

    def _err(self, msg):
        self.main_display.config(text="ERR", fg=self.COLORS["btn_spec"])
        self.flag_lbl.config(text=msg[:35])
        self.new_number = True

    def _refresh_ports(self):
        ports = [p.device for p in serial.tools.list_ports.comports()]
        self.port_cb["values"] = ports
        if ports: self.port_var.set(ports[0])

    def _toggle_connection(self):
        if self.serial_conn is None:
            port = self.port_var.get()
            if not port:
                messagebox.showwarning("Puerto", "Selecciona un puerto COM")
                return
            try:
                self.serial_conn = serial.Serial(port, 115200, timeout=2)
                self.sim_mode    = False
                self.connect_btn.config(text="Desconectar")
                self.status_lbl.config(text=f"● {port}")
            except Exception as e:
                messagebox.showerror("Error", f"No se pudo conectar:\n{e}")
        else:
            self.serial_conn.close()
            self.serial_conn = None
            self.sim_mode    = True
            self.connect_btn.config(text="Conectar")
            self.status_lbl.config(text="● Simulado")

if __name__ == "__main__":
    root = tk.Tk()
    CalculatorApp(root)
    root.mainloop()
