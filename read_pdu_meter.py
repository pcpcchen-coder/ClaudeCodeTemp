#!/usr/bin/env python3
"""
PDU / Meter Modbus TCP Scanner
===============================
掃描 Modbus TCP 設備，自動探測可讀暫存器並嘗試解碼為電力參數。
適用於未知暫存器表的 PDU 櫃、電表等設備。

Usage:
    python3 read_pdu_meter.py
    python3 read_pdu_meter.py --ip 10.156.90.121 --port 502 --quick
    python3 read_pdu_meter.py --csv pdu_scan.csv --verbose
"""

import argparse
import csv
import struct
import sys
import time
from datetime import datetime

try:
    from pymodbus.client import ModbusTcpClient
    from pymodbus.exceptions import ModbusIOException, ConnectionException
except ImportError:
    print("錯誤: 缺少 pymodbus 套件，請先安裝:")
    print("  pip install pymodbus")
    sys.exit(1)

# ── 預設設定 ──────────────────────────────────────────────────────────
DEFAULT_IP = "10.156.90.121"
DEFAULT_PORT = 502
DEFAULT_TIMEOUT = 3
DEFAULT_SLAVE_IDS = [1, 2, 3, 100, 247]
BATCH_SIZE = 50
REQUEST_DELAY = 0.1  # 100ms between requests

# 掃描範圍: (起始位址, 結束位址, 說明)
SCAN_RANGES = [
    (0, 100, "通用預設範圍"),
    (100, 200, "Schneider/ABB 次要範圍"),
    (200, 300, "溢位/設定暫存器"),
    (999, 1100, "中國製 PDU 常用 1000 基底"),
    (2999, 3100, "Schneider PM5xxx 輸入暫存器"),
    (3899, 4000, "Schneider PM 擴展範圍"),
    (3999, 4100, "Eastron SDM 系列"),
    (29999, 30100, "30001 偏移慣例 (Input Registers)"),
    (39999, 40100, "40001 偏移慣例 (Holding Registers)"),
]

QUICK_SCAN_RANGES = [
    (0, 100, "通用預設範圍"),
    (999, 1100, "中國製 PDU 常用 1000 基底"),
    (2999, 3100, "Schneider PM5xxx"),
    (3999, 4100, "Eastron SDM 系列"),
]


# ── 資料解碼 ──────────────────────────────────────────────────────────

def decode_uint16(val):
    return val


def decode_int16(val):
    return struct.unpack(">h", struct.pack(">H", val))[0]


def decode_uint32_be(hi, lo):
    """Big-endian: high word first"""
    return (hi << 16) | lo


def decode_uint32_le(hi, lo):
    """Word-swapped: low word first"""
    return (lo << 16) | hi


def decode_int32_be(hi, lo):
    raw = (hi << 16) | lo
    return struct.unpack(">i", struct.pack(">I", raw))[0]


def decode_int32_le(hi, lo):
    raw = (lo << 16) | hi
    return struct.unpack(">i", struct.pack(">I", raw))[0]


def decode_float32_be(hi, lo):
    """Big-endian float: high word first"""
    try:
        raw = struct.pack(">HH", hi, lo)
        val = struct.unpack(">f", raw)[0]
        if val != val:  # NaN check
            return None
        if abs(val) > 1e10 or (val != 0 and abs(val) < 1e-10):
            return None
        return val
    except (struct.error, OverflowError):
        return None


def decode_float32_le(hi, lo):
    """Word-swapped float: low word first"""
    try:
        raw = struct.pack(">HH", lo, hi)
        val = struct.unpack(">f", raw)[0]
        if val != val:  # NaN check
            return None
        if abs(val) > 1e10 or (val != 0 and abs(val) < 1e-10):
            return None
        return val
    except (struct.error, OverflowError):
        return None


def guess_meaning(val, scale_options=None):
    """根據數值範圍猜測可能的物理量"""
    hints = []

    if scale_options is None:
        scale_options = [1, 10, 100, 1000]

    for scale in scale_options:
        scaled = val / scale
        if 100 <= scaled <= 500:
            hints.append(f"電壓? ({scaled:.1f}V, /{scale})")
        if 180 <= scaled <= 420:
            hints.append(f"線電壓? ({scaled:.1f}V, /{scale})")
        if 0.1 <= scaled <= 2000:
            if 0.1 <= scaled <= 5:
                pass  # too ambiguous
            elif 45 <= scaled <= 65:
                hints.append(f"頻率? ({scaled:.2f}Hz, /{scale})")
        if 0.5 <= scaled <= 1.05 and scale >= 100:
            hints.append(f"功率因數? ({scaled:.3f}, /{scale})")
        if 1 <= scaled <= 800:
            if scale >= 10:
                hints.append(f"功率? ({scaled:.1f}kW, /{scale})")
        if 0.1 <= scaled <= 2000 and scale <= 100:
            if 10 <= scaled <= 2000:
                hints.append(f"電流? ({scaled:.1f}A, /{scale})")

    return "; ".join(hints[:3]) if hints else ""


def guess_meaning_float(val):
    """對 float32 解碼值猜測物理量"""
    if val is None:
        return ""
    hints = []
    abs_val = abs(val)

    if 100 <= abs_val <= 500:
        hints.append(f"電壓? ({val:.1f}V)")
    if 180 <= abs_val <= 420:
        hints.append(f"線電壓? ({val:.1f}V)")
    if 45 <= abs_val <= 65:
        hints.append(f"頻率? ({val:.2f}Hz)")
    if 0.5 <= abs_val <= 1.05:
        hints.append(f"功率因數? ({val:.3f})")
    if 1 <= abs_val <= 1000:
        hints.append(f"功率? ({val:.1f}kW)")
    if 0.1 <= abs_val <= 2000:
        hints.append(f"電流? ({val:.1f}A)")
    if abs_val > 1000:
        hints.append(f"能量? ({val:.1f}kWh)")

    return "; ".join(hints[:3]) if hints else ""


# ── 已知設備模式 ──────────────────────────────────────────────────────

KNOWN_PATTERNS = [
    {
        "name": "Schneider PM5xxx",
        "description": "施耐德 PM5xxx 系列電表 (float32 @ 3000+)",
        "fc": 3,
        "checks": [
            (3000, "float32", "Ia (A相電流)"),
            (3002, "float32", "Ib (B相電流)"),
            (3004, "float32", "Ic (C相電流)"),
            (3028, "float32", "頻率"),
        ],
    },
    {
        "name": "Eastron SDM / Chint DTSU666",
        "description": "Eastron SDM 或 正泰 DTSU666 (float32 @ 0+, Input Registers)",
        "fc": 4,
        "checks": [
            (0, "float32", "A相電壓"),
            (2, "float32", "B相電壓"),
            (4, "float32", "C相電壓"),
            (6, "float32", "A相電流"),
        ],
    },
    {
        "name": "Eastron SDM (Holding)",
        "description": "Eastron SDM 系列 (float32 @ 0+, Holding Registers)",
        "fc": 3,
        "checks": [
            (0, "float32", "A相電壓"),
            (2, "float32", "B相電壓"),
            (4, "float32", "C相電壓"),
            (6, "float32", "A相電流"),
        ],
    },
    {
        "name": "安科瑞 ACR / Acrel",
        "description": "安科瑞 ACR 系列 (uint16 /10 @ 0+)",
        "fc": 3,
        "checks": [
            (0, "uint16_d10", "Ua (A相電壓)"),
            (1, "uint16_d10", "Ub (B相電壓)"),
            (2, "uint16_d10", "Uc (C相電壓)"),
        ],
    },
]


# ── 掃描核心 ──────────────────────────────────────────────────────────

def read_registers_safe(client, slave_id, func_code, start, count):
    """安全讀取暫存器，回傳 registers list 或 None"""
    try:
        if func_code == 3:
            resp = client.read_holding_registers(start, count, slave=slave_id)
        elif func_code == 4:
            resp = client.read_input_registers(start, count, slave=slave_id)
        else:
            return None

        if resp is None or resp.isError():
            return None
        return resp.registers
    except (ModbusIOException, ConnectionException, Exception):
        return None


def scan_range(client, slave_id, func_code, start, end, batch_size=BATCH_SIZE):
    """掃描一個位址範圍，回傳 {address: raw_value} dict"""
    results = {}
    addr = start
    while addr < end:
        count = min(batch_size, end - addr)
        regs = read_registers_safe(client, slave_id, func_code, addr, count)

        if regs is None and count > 10:
            # 批次失敗，降至每次讀 10 個
            for sub_start in range(addr, addr + count, 10):
                sub_count = min(10, end - sub_start)
                sub_regs = read_registers_safe(client, slave_id, func_code, sub_start, sub_count)
                if sub_regs:
                    for i, val in enumerate(sub_regs):
                        results[sub_start + i] = val
                time.sleep(REQUEST_DELAY)
        elif regs is not None:
            for i, val in enumerate(regs):
                results[addr + i] = val

        addr += count
        time.sleep(REQUEST_DELAY)

    return results


def check_slave_alive(client, slave_id):
    """快速檢查 slave ID 是否回應"""
    r3 = read_registers_safe(client, slave_id, 3, 0, 1)
    r4 = read_registers_safe(client, slave_id, 4, 0, 1)
    return r3 is not None or r4 is not None


def run_scan(client, slave_ids, scan_ranges, verbose=False):
    """
    主掃描邏輯。回傳結構化結果:
    {
        slave_id: {
            fc: {
                "range_label": str,
                "registers": {addr: raw_value, ...}
            }
        }
    }
    """
    all_results = {}
    responsive_slaves = []

    for sid in slave_ids:
        print(f"\n  測試 Slave ID {sid}...", end=" ", flush=True)
        if not check_slave_alive(client, sid):
            print("無回應，跳過")
            continue

        print("有回應!")
        responsive_slaves.append(sid)
        all_results[sid] = {}

        for fc in [3, 4]:
            fc_label = "FC03 (Holding)" if fc == 3 else "FC04 (Input)"
            all_results[sid][fc] = []

            for start, end, label in scan_ranges:
                print(f"    掃描 {fc_label} [{start}-{end}] {label}...", end=" ", flush=True)
                regs = scan_range(client, sid, fc, start, end)
                non_zero = {a: v for a, v in regs.items() if v != 0}

                if non_zero:
                    print(f"找到 {len(non_zero)} 個非零暫存器")
                    all_results[sid][fc].append({
                        "range_label": label,
                        "start": start,
                        "end": end,
                        "registers": regs,
                        "non_zero": non_zero,
                    })
                elif regs and verbose:
                    print(f"全部為零 ({len(regs)} 個暫存器)")
                else:
                    print("無資料")

    return all_results, responsive_slaves


# ── 模式匹配 ──────────────────────────────────────────────────────────

def try_pattern_match(client, slave_id, patterns):
    """嘗試匹配已知設備模式"""
    matches = []

    for pattern in patterns:
        fc = pattern["fc"]
        score = 0
        total = len(pattern["checks"])
        details = []

        for addr, dtype, desc in pattern["checks"]:
            if dtype == "float32":
                regs = read_registers_safe(client, slave_id, fc, addr, 2)
                if regs and len(regs) == 2:
                    val_be = decode_float32_be(regs[0], regs[1])
                    val_le = decode_float32_le(regs[0], regs[1])
                    val = val_be if val_be is not None else val_le
                    if val is not None and 0.01 <= abs(val) <= 100000:
                        score += 1
                        details.append(f"  {desc}: {val:.2f} (addr={addr})")
            elif dtype == "uint16_d10":
                regs = read_registers_safe(client, slave_id, fc, addr, 1)
                if regs and len(regs) == 1:
                    val = regs[0] / 10.0
                    if 10 <= val <= 500:
                        score += 1
                        details.append(f"  {desc}: {val:.1f} (addr={addr})")
            time.sleep(REQUEST_DELAY)

        if score > 0:
            matches.append({
                "name": pattern["name"],
                "description": pattern["description"],
                "score": f"{score}/{total}",
                "details": details,
            })

    return matches


# ── 輸出格式化 ────────────────────────────────────────────────────────

def format_register_table(registers, start_addr=0):
    """格式化暫存器表格"""
    lines = []
    sorted_addrs = sorted(registers.keys())

    lines.append(f"  {'位址':>6}  {'原始(hex)':>10}  {'uint16':>8}  {'int16':>8}  "
                 f"{'float32_BE':>12}  {'float32_LE':>12}  {'可能含義'}")
    lines.append("  " + "-" * 100)

    for i, addr in enumerate(sorted_addrs):
        val = registers[addr]
        u16 = decode_uint16(val)
        i16 = decode_int16(val)

        # float32 needs next register
        f32_be_str = ""
        f32_le_str = ""
        if i + 1 < len(sorted_addrs):
            next_addr = sorted_addrs[i + 1]
            if next_addr == addr + 1:
                next_val = registers[next_addr]
                f32_be = decode_float32_be(val, next_val)
                f32_le = decode_float32_le(val, next_val)
                if f32_be is not None:
                    f32_be_str = f"{f32_be:.4f}"
                if f32_le is not None:
                    f32_le_str = f"{f32_le:.4f}"

        # Heuristic guess
        hint_parts = []
        hint_u16 = guess_meaning(u16)
        if hint_u16:
            hint_parts.append(hint_u16)
        if f32_be_str:
            hint_f = guess_meaning_float(decode_float32_be(val, registers.get(addr + 1, 0)))
            if hint_f:
                hint_parts.append(f"[f32] {hint_f}")
        hint = " | ".join(hint_parts) if hint_parts else ""

        lines.append(
            f"  {addr:>6}  0x{val:04X}      {u16:>8}  {i16:>8}  "
            f"{f32_be_str:>12}  {f32_le_str:>12}  {hint}"
        )

    return "\n".join(lines)


def print_results(all_results, responsive_slaves):
    """印出完整結果報告"""
    print("\n")
    print("=" * 80)
    print("  PDU Modbus TCP 掃描結果報告")
    print("=" * 80)
    print(f"  掃描時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"  有回應的 Slave ID: {responsive_slaves if responsive_slaves else '(無)'}")

    if not responsive_slaves:
        print("\n  [!] 未偵測到任何回應的 Slave ID。")
        print("  疑難排解建議:")
        print("    1. 確認 IP 位址與 Port 正確")
        print("    2. 確認設備已開機且網路可達 (ping)")
        print("    3. 確認防火牆未阻擋 port 502")
        print("    4. 嘗試其他 Slave ID: --slave-ids 0,1,2,...,10")
        print("    5. 確認設備是否需要 RTU-to-TCP 閘道器")
        return

    total_found = 0

    for sid in responsive_slaves:
        print(f"\n{'─' * 80}")
        print(f"  Slave ID: {sid}")
        print(f"{'─' * 80}")

        for fc in [3, 4]:
            fc_label = "FC03 Holding Registers" if fc == 3 else "FC04 Input Registers"
            range_results = all_results.get(sid, {}).get(fc, [])

            if not range_results:
                continue

            print(f"\n  [{fc_label}]")

            for rr in range_results:
                non_zero = rr["non_zero"]
                if not non_zero:
                    continue

                total_found += len(non_zero)
                print(f"\n  --- {rr['range_label']} (addr {rr['start']}-{rr['end']}) "
                      f"--- {len(non_zero)} 個非零暫存器 ---")
                print(format_register_table(non_zero))

    print(f"\n{'=' * 80}")
    print(f"  共找到 {total_found} 個非零暫存器")
    print("=" * 80)


def export_csv(all_results, filename):
    """匯出結果為 CSV"""
    with open(filename, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow([
            "slave_id", "function_code", "range_label",
            "address", "raw_hex", "uint16", "int16",
            "float32_be", "float32_le", "hint"
        ])

        for sid, fc_data in all_results.items():
            for fc, range_results in fc_data.items():
                for rr in range_results:
                    sorted_addrs = sorted(rr["non_zero"].keys())
                    for i, addr in enumerate(sorted_addrs):
                        val = rr["non_zero"][addr]
                        u16 = decode_uint16(val)
                        i16 = decode_int16(val)

                        f32_be = ""
                        f32_le = ""
                        if addr + 1 in rr.get("registers", {}):
                            nv = rr["registers"][addr + 1]
                            fb = decode_float32_be(val, nv)
                            fl = decode_float32_le(val, nv)
                            if fb is not None:
                                f32_be = f"{fb:.6f}"
                            if fl is not None:
                                f32_le = f"{fl:.6f}"

                        hint = guess_meaning(u16)

                        writer.writerow([
                            sid, f"FC{fc:02d}", rr["range_label"],
                            addr, f"0x{val:04X}", u16, i16,
                            f32_be, f32_le, hint
                        ])

    print(f"\n  結果已匯出至: {filename}")


# ── 主程式 ────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="PDU / Meter Modbus TCP 掃描器 - 自動探測暫存器並解碼電力參數",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
範例:
  python3 read_pdu_meter.py                           # 預設掃描
  python3 read_pdu_meter.py --quick                   # 快速掃描
  python3 read_pdu_meter.py --slave-ids 1,2,3         # 指定 Slave ID
  python3 read_pdu_meter.py --csv pdu_scan.csv        # 匯出 CSV
  python3 read_pdu_meter.py --verbose                  # 顯示零值暫存器
  python3 read_pdu_meter.py --port-scan                # 先掃描開放端口
        """
    )
    parser.add_argument("--ip", default=DEFAULT_IP, help=f"目標 IP (預設: {DEFAULT_IP})")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help=f"目標 Port (預設: {DEFAULT_PORT})")
    parser.add_argument("--slave-ids", default=None,
                        help=f"Slave ID 清單，逗號分隔 (預設: {','.join(map(str, DEFAULT_SLAVE_IDS))})")
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT, help=f"連線逾時秒數 (預設: {DEFAULT_TIMEOUT})")
    parser.add_argument("--csv", default=None, metavar="FILE", help="匯出結果至 CSV 檔案")
    parser.add_argument("--verbose", action="store_true", help="顯示所有暫存器（包含零值）")
    parser.add_argument("--quick", action="store_true", help="快速掃描：僅掃描常用範圍")
    parser.add_argument("--port-scan", action="store_true", help="先掃描常見 Modbus 相關端口")

    args = parser.parse_args()

    slave_ids = DEFAULT_SLAVE_IDS
    if args.slave_ids:
        slave_ids = [int(x.strip()) for x in args.slave_ids.split(",")]

    ranges = QUICK_SCAN_RANGES if args.quick else SCAN_RANGES

    # ── 端口掃描 ──
    if args.port_scan:
        import socket
        print("=" * 80)
        print("  端口掃描 (Modbus 常見端口)")
        print("=" * 80)
        modbus_ports = [80, 502, 503, 504, 1502, 4196, 5020, 8899, 9600, 10502, 20000, 23, 2404]
        open_ports = []
        for p in modbus_ports:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(args.timeout)
            try:
                result = s.connect_ex((args.ip, p))
                status = "OPEN" if result == 0 else "CLOSED"
                if result == 0:
                    open_ports.append(p)
                print(f"  Port {p:>6}: {status}")
            except Exception as e:
                print(f"  Port {p:>6}: ERROR ({e})")
            finally:
                s.close()
        print(f"\n  開放端口: {open_ports if open_ports else '(無)'}")
        if 502 not in open_ports:
            print("  [!] Port 502 未開放，Modbus TCP 可能無法使用。")
            if open_ports:
                print(f"  提示: 嘗試使用 --port {open_ports[0]} 指定其他端口")
        print()

    # ── 連線 ──
    print("=" * 80)
    print("  PDU / Meter Modbus TCP 掃描器")
    print("=" * 80)
    print(f"  目標: {args.ip}:{args.port}")
    print(f"  Slave IDs: {slave_ids}")
    print(f"  掃描範圍: {'快速模式' if args.quick else '完整模式'} ({len(ranges)} 個範圍)")
    print(f"  開始時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

    print("  正在連線...", end=" ", flush=True)
    client = ModbusTcpClient(host=args.ip, port=args.port, timeout=args.timeout)

    try:
        connected = client.connect()
    except Exception as e:
        print(f"連線失敗!")
        print(f"\n  錯誤: {e}")
        print(f"\n  疑難排解:")
        print(f"    1. 確認設備 IP ({args.ip}) 可 ping 通")
        print(f"    2. 確認 port {args.port} 未被防火牆阻擋")
        print(f"    3. 確認 PDU 櫃已開機且 Modbus TCP 功能已啟用")
        sys.exit(1)

    if not connected:
        print("連線失敗!")
        print(f"\n  無法建立 TCP 連線至 {args.ip}:{args.port}")
        print(f"\n  疑難排解:")
        print(f"    1. 確認設備 IP ({args.ip}) 可 ping 通")
        print(f"    2. 確認 port {args.port} 未被防火牆阻擋")
        print(f"    3. 確認 PDU 櫃已開機且 Modbus TCP 功能已啟用")
        sys.exit(1)

    print("連線成功!")

    # ── 掃描 ──
    print("\n  開始掃描暫存器...")
    all_results, responsive_slaves = run_scan(client, slave_ids, ranges, args.verbose)

    # ── 模式匹配 ──
    if responsive_slaves:
        print("\n  正在比對已知設備模式...")
        for sid in responsive_slaves:
            matches = try_pattern_match(client, sid, KNOWN_PATTERNS)
            if matches:
                print(f"\n  Slave ID {sid} 可能的設備型號:")
                for m in matches:
                    print(f"    [{m['score']}] {m['name']} - {m['description']}")
                    for d in m["details"]:
                        print(f"      {d}")

    # ── 輸出 ──
    print_results(all_results, responsive_slaves)

    if args.csv:
        export_csv(all_results, args.csv)

    # ── 清理 ──
    client.close()
    print(f"\n  掃描完成，連線已關閉。")


if __name__ == "__main__":
    main()
