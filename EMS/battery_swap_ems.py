#!/usr/bin/env python3
"""
換電站 EMS 模擬工具 (Battery Swap Station EMS Simulation)
=========================================================
模擬換電站中 PCS → DCDC → 電池 的充電過程，
自動計算最佳 DCDC 分配策略並以圖表呈現結果。

使用方式:
    python battery_swap_ems.py                     # 使用預設參數
    python battery_swap_ems.py --duration 240      # 模擬 240 分鐘
    python battery_swap_ems.py --swap-interval 80  # 每 80 秒換一顆電池
    python battery_swap_ems.py --soc-threshold 95  # 充到 95% 才能換出
"""

import argparse
import random
import numpy as np
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend for saving
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
from matplotlib.lines import Line2D
from matplotlib import font_manager

# 設定中文字型
_font_path = '/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc'
import os
if os.path.exists(_font_path):
    font_manager.fontManager.addfont(_font_path)
    _fp = font_manager.FontProperties(fname=_font_path)
    plt.rcParams['font.family'] = _fp.get_name()
else:
    for _f in ['WenQuanYi Zen Hei', 'Noto Sans CJK TC', 'Microsoft JhengHei', 'SimHei']:
        try:
            font_manager.findfont(_f, fallback_to_default=False)
            plt.rcParams['font.sans-serif'] = [_f] + plt.rcParams.get('font.sans-serif', [])
            break
        except Exception:
            continue
plt.rcParams['axes.unicode_minus'] = False
from dataclasses import dataclass, field
from typing import List, Tuple, Optional

# ========== CONFIGURATION ==========
@dataclass
class Config:
    sim_duration_min: float = 120       # 模擬時長 (分鐘)
    time_step_s: float = 10            # 時間步進 (秒)
    swap_interval_s: float = 100       # 換電間隔 (秒)
    soc_threshold: float = 90          # 充電門檻 SOC (%)
    incoming_soc_max: float = 30       # 入站最高 SOC (%)
    batt_capacity_kwh: float = 50      # 電池容量 (kWh)
    dcdc_max_power_kw: float = 50      # 單顆 DCDC 最大功率 (kW)
    pcs_max_power_kw: float = 125      # 單台 PCS 最大功率 (kW)
    num_pcs: int = 7                   # PCS 數量 (並聯於 800Vdc 母線)
    num_batteries: int = 14
    num_groups: int = 7
    dcdcs_per_group: int = 3
    battery_pairs: list = field(default_factory=lambda: [
        (0, 7), (1, 8), (2, 9), (3, 10), (4, 11), (5, 12), (6, 13)
    ])

# ========== DATA TABLES ==========
# CATL 25# 電池充電曲線
BATTERY_TABLE = [
    {'soc': 0,   'crate': 2.74, 'time': 0,     'power': 138.32},
    {'soc': 5,   'crate': 2.74, 'time': 1.09,  'power': 140.17},
    {'soc': 10,  'crate': 2.56, 'time': 2.27,  'power': 132.56},
    {'soc': 15,  'crate': 2.42, 'time': 3.5,   'power': 127.09},
    {'soc': 20,  'crate': 2.29, 'time': 4.82,  'power': 121.44},
    {'soc': 25,  'crate': 2.19, 'time': 6.18,  'power': 118.07},
    {'soc': 30,  'crate': 2.01, 'time': 7.68,  'power': 109.59},
    {'soc': 35,  'crate': 1.83, 'time': 9.32,  'power': 100.86},
    {'soc': 40,  'crate': 1.69, 'time': 11.09, 'power': 94.44},
    {'soc': 45,  'crate': 1.55, 'time': 13.02, 'power': 87.83},
    {'soc': 50,  'crate': 1.46, 'time': 15.07, 'power': 83.65},
    {'soc': 55,  'crate': 1.37, 'time': 17.26, 'power': 79.35},
    {'soc': 60,  'crate': 1.33, 'time': 19.52, 'power': 77.6},
    {'soc': 65,  'crate': 1.14, 'time': 22.15, 'power': 67.67},
    {'soc': 70,  'crate': 1.05, 'time': 25,    'power': 62.96},
    {'soc': 75,  'crate': 0.87, 'time': 28.46, 'power': 53.38},
    {'soc': 80,  'crate': 0.73, 'time': 32.56, 'power': 46.11},
    {'soc': 85,  'crate': 0.59, 'time': 37.61, 'power': 37.73},
    {'soc': 90,  'crate': 0.5,  'time': 43.57, 'power': 32.15},
    {'soc': 95,  'crate': 0.41, 'time': 50.86, 'power': 26.49},
    {'soc': 97,  'crate': 0.37, 'time': 54.15, 'power': 24.04},
    {'soc': 99,  'crate': 0.37, 'time': 57.43, 'power': 24.37},
    {'soc': 100, 'crate': 0.18, 'time': 60.71, 'power': 12.51},
]

# DCDC 效率曲線 (負載% → 效率)
DCDC_EFF_TABLE = [
    {'load': 5,   'eff': 0.9265},
    {'load': 10,  'eff': 0.9573},
    {'load': 20,  'eff': 0.9700},
    {'load': 30,  'eff': 0.9744},
    {'load': 40,  'eff': 0.9773},
    {'load': 50,  'eff': 0.9783},
    {'load': 60,  'eff': 0.9788},
    {'load': 70,  'eff': 0.9784},
    {'load': 80,  'eff': 0.9780},
    {'load': 90,  'eff': 0.9777},
    {'load': 100, 'eff': 0.9774},
]

# PCS 效率曲線 (負載% → 效率)
PCS_EFF_TABLE = [
    {'load': 10,  'eff': 0.980186},
    {'load': 20,  'eff': 0.982810},
    {'load': 30,  'eff': 0.984732},
    {'load': 40,  'eff': 0.984834},
    {'load': 50,  'eff': 0.983669},
    {'load': 60,  'eff': 0.983029},
    {'load': 70,  'eff': 0.982105},
    {'load': 80,  'eff': 0.980972},
    {'load': 90,  'eff': 0.979730},
    {'load': 100, 'eff': 0.978308},
]


# ========== UTILITY FUNCTIONS ==========
def interpolate(table: list, x_val: float, x_key: str, y_key: str) -> float:
    """線性內插"""
    if x_val <= table[0][x_key]:
        return table[0][y_key]
    if x_val >= table[-1][x_key]:
        return table[-1][y_key]
    for i in range(len(table) - 1):
        if table[i][x_key] <= x_val <= table[i + 1][x_key]:
            t = (x_val - table[i][x_key]) / (table[i + 1][x_key] - table[i][x_key])
            return table[i][y_key] + t * (table[i + 1][y_key] - table[i][y_key])
    return table[-1][y_key]


def get_max_charge_power(soc_pct: float) -> float:
    """根據 SOC 查表取得最大充電功率 (kW)"""
    return interpolate(BATTERY_TABLE, soc_pct, 'soc', 'power')


def get_dcdc_eff(load_pct: float) -> float:
    """根據 DCDC 負載率取得效率"""
    if load_pct <= 0:
        return 0
    return interpolate(DCDC_EFF_TABLE, max(load_pct, DCDC_EFF_TABLE[0]['load']), 'load', 'eff')


def get_pcs_eff(load_pct: float) -> float:
    """根據 PCS 負載率取得效率"""
    if load_pct <= 0:
        return 0
    return interpolate(PCS_EFF_TABLE, max(load_pct, PCS_EFF_TABLE[0]['load']), 'load', 'eff')


# ========== BATTERY MODEL ==========
class Battery:
    def __init__(self, bat_id: int, initial_soc: float = None):
        self.id = bat_id  # 1-based
        self.soc = initial_soc if initial_soc is not None else (50 + random.random() * 40)
        self.present = True
        self.charge_power_kw = 0.0

    def max_charge_power(self) -> float:
        return get_max_charge_power(self.soc)

    def needs_charging(self, threshold: float) -> bool:
        return self.present and self.soc < threshold

    def charge(self, power_kw: float, dt_s: float, capacity_kwh: float):
        if not self.present or power_kw <= 0:
            self.charge_power_kw = 0
            return
        max_p = self.max_charge_power()
        actual_p = min(power_kw, max_p)
        self.charge_power_kw = actual_p
        energy_kwh = actual_p * dt_s / 3600
        self.soc = min(100, self.soc + (energy_kwh / capacity_kwh) * 100)

    def swap_out(self) -> float:
        old_soc = self.soc
        self.present = False
        self.soc = 0
        self.charge_power_kw = 0
        return old_soc

    def swap_in(self, new_soc: float):
        self.soc = new_soc
        self.present = True
        self.charge_power_kw = 0


# ========== DCDC GROUP MODEL ==========
class DCDCGroup:
    def __init__(self, group_id: int, batt_a: Battery, batt_b: Battery):
        self.group_id = group_id
        self.batt_a = batt_a
        self.batt_b = batt_b
        self.alloc_a = 0
        self.alloc_b = 0
        self.power_a = 0.0
        self.power_b = 0.0
        self.dcdc_load_a = 0.0
        self.dcdc_load_b = 0.0
        self.dcdc_eff_a = 0.0
        self.dcdc_eff_b = 0.0
        self.dc_bus_power = 0.0   # 該組從 800V 母線取用的功率

    def optimize(self, cfg: Config):
        """列舉所有 DCDC 分配組合，選出最佳方案
        注意：PCS 限制在 Station 層級處理（並聯共用母線），
        此處僅考慮 DCDC 容量與電池充電需求。
        """
        threshold = cfg.soc_threshold
        dcdc_max = cfg.dcdc_max_power_kw
        needs_a = self.batt_a.needs_charging(threshold)
        needs_b = self.batt_b.needs_charging(threshold)

        best_score = -1
        best_na, best_nb = 0, 0

        for na in range(4):
            for nb in range(4 - na):
                if na > 0 and not needs_a:
                    continue
                if nb > 0 and not needs_b:
                    continue

                pa, pb, dc_bus = 0.0, 0.0, 0.0
                ea, eb = 1.0, 1.0

                if na > 0 and needs_a:
                    pa = min(na * dcdc_max, self.batt_a.max_charge_power())
                    load_a = (pa / na) / dcdc_max * 100
                    ea = get_dcdc_eff(load_a)
                    if ea > 0:
                        dc_bus += pa / ea

                if nb > 0 and needs_b:
                    pb = min(nb * dcdc_max, self.batt_b.max_charge_power())
                    load_b = (pb / nb) / dcdc_max * 100
                    eb = get_dcdc_eff(load_b)
                    if eb > 0:
                        dc_bus += pb / eb

                total_p = pa + pb
                # DCDC 層效率 (不含 PCS，PCS 在 Station 層統一計算)
                dcdc_eff = total_p / dc_bus if dc_bus > 0 else 0
                score = total_p * 10000 + dcdc_eff * 100

                if score > best_score:
                    best_score = score
                    best_na, best_nb = na, nb

        self.alloc_a = best_na
        self.alloc_b = best_nb

    def compute_power_flow(self, cfg: Config):
        """計算該組的 DCDC 功率流 (不含 PCS，PCS 在 Station 層統一計算)"""
        dcdc_max = cfg.dcdc_max_power_kw
        threshold = cfg.soc_threshold

        self.power_a = self.power_b = 0
        self.dcdc_load_a = self.dcdc_load_b = 0
        self.dcdc_eff_a = self.dcdc_eff_b = 0
        self.dc_bus_power = 0

        if self.alloc_a > 0 and self.batt_a.needs_charging(threshold):
            self.power_a = min(self.alloc_a * dcdc_max, self.batt_a.max_charge_power())
            self.dcdc_load_a = (self.power_a / self.alloc_a) / dcdc_max * 100
            self.dcdc_eff_a = get_dcdc_eff(self.dcdc_load_a)
            if self.dcdc_eff_a > 0:
                self.dc_bus_power += self.power_a / self.dcdc_eff_a

        if self.alloc_b > 0 and self.batt_b.needs_charging(threshold):
            self.power_b = min(self.alloc_b * dcdc_max, self.batt_b.max_charge_power())
            self.dcdc_load_b = (self.power_b / self.alloc_b) / dcdc_max * 100
            self.dcdc_eff_b = get_dcdc_eff(self.dcdc_load_b)
            if self.dcdc_eff_b > 0:
                self.dc_bus_power += self.power_b / self.dcdc_eff_b

    def step(self, cfg: Config):
        self.optimize(cfg)
        self.compute_power_flow(cfg)
        self.batt_a.charge(self.power_a, cfg.time_step_s, cfg.batt_capacity_kwh)
        self.batt_b.charge(self.power_b, cfg.time_step_s, cfg.batt_capacity_kwh)



# ========== STATION MODEL ==========
class Station:
    def __init__(self, cfg: Config):
        self.cfg = cfg
        self.batteries = [Battery(i + 1) for i in range(cfg.num_batteries)]
        self.groups = []
        for g in range(cfg.num_groups):
            a_idx, b_idx = cfg.battery_pairs[g]
            self.groups.append(DCDCGroup(g, self.batteries[a_idx], self.batteries[b_idx]))
        self.swap_index = 0
        self.swap_accum = 0.0
        self.swap_count = 0
        self.total_energy_kwh = 0.0
        self.events: List[dict] = []
        # PCS 並聯狀態
        self.active_pcs = cfg.num_pcs      # 目前啟用的 PCS 數量
        self.pcs_total_load = 0.0          # 母線總負載 (kW)
        self.pcs_load_per_unit = 0.0       # 每台 PCS 分攤負載 (kW)
        self.pcs_load_pct = 0.0            # 每台 PCS 負載率 (%)
        self.pcs_eff = 0.0                 # PCS 轉換效率
        self.grid_power = 0.0              # 電網總功率 (kW)

    def step(self):
        cfg = self.cfg
        self.swap_accum += cfg.time_step_s
        while self.swap_accum >= cfg.swap_interval_s:
            self.swap_accum -= cfg.swap_interval_s
            self._perform_swap()

        # 1. 各組 DCDC 獨立最佳化分配並計算功率流
        for g in self.groups:
            g.step(cfg)

        # 2. 計算 800V 母線總負載 (所有 DCDC 組的 DC bus 功率總和)
        self.pcs_total_load = sum(g.dc_bus_power for g in self.groups)

        # 3. PCS 並聯最佳化：決定啟用幾台 PCS 以達最佳效率
        self._optimize_pcs(cfg)

        batt_power = sum(g.power_a + g.power_b for g in self.groups)
        self.total_energy_kwh += batt_power * cfg.time_step_s / 3600

    def _optimize_pcs(self, cfg: Config):
        """最佳化 PCS 並聯數量，使每台 PCS 運行在最佳效率區間"""
        total_load = self.pcs_total_load
        if total_load <= 0:
            self.active_pcs = 0
            self.pcs_load_per_unit = 0
            self.pcs_load_pct = 0
            self.pcs_eff = 0
            self.grid_power = 0
            return

        pcs_max = cfg.pcs_max_power_kw
        best_eff = 0
        best_n = 1

        for n in range(1, cfg.num_pcs + 1):
            # 檢查 n 台 PCS 是否能承載總負載
            if total_load > n * pcs_max:
                continue
            # 每台 PCS 分攤的負載
            load_per_unit = total_load / n
            load_pct = load_per_unit / pcs_max * 100
            eff = get_pcs_eff(load_pct)
            if eff > best_eff:
                best_eff = eff
                best_n = n

        self.active_pcs = best_n
        self.pcs_load_per_unit = total_load / best_n
        self.pcs_load_pct = self.pcs_load_per_unit / pcs_max * 100
        self.pcs_eff = best_eff
        self.grid_power = total_load / best_eff if best_eff > 0 else total_load

    def _perform_swap(self):
        cfg = self.cfg
        batt = self.batteries[self.swap_index]
        bat_id = self.swap_index + 1

        if batt.present and batt.soc >= cfg.soc_threshold:
            old_soc = batt.swap_out()
            new_soc = random.random() * cfg.incoming_soc_max
            batt.swap_in(new_soc)
            self.swap_count += 1
            self.events.append({
                'type': 'swap',
                'msg': f'電池 #{bat_id} 換出 (SOC {old_soc:.1f}%) → 換入 (SOC {new_soc:.1f}%)'
            })
        elif not batt.present:
            new_soc = random.random() * cfg.incoming_soc_max
            batt.swap_in(new_soc)
            self.swap_count += 1
            self.events.append({
                'type': 'swap',
                'msg': f'電池槽 #{bat_id} 補入電池 (SOC {new_soc:.1f}%)'
            })
        else:
            self.events.append({
                'type': 'wait',
                'msg': f'電池 #{bat_id} SOC {batt.soc:.1f}% < {cfg.soc_threshold}%，等待充電'
            })

        self.swap_index = (self.swap_index + 1) % cfg.num_batteries

    def get_metrics(self) -> dict:
        batt_p = sum(g.power_a + g.power_b for g in self.groups)
        eff = batt_p / self.grid_power * 100 if self.grid_power > 0 else 0
        return {
            'grid_power': self.grid_power,
            'batt_power': batt_p,
            'efficiency': eff,
            'bus_power': self.pcs_total_load,
            'active_pcs': self.active_pcs,
            'pcs_load_pct': self.pcs_load_pct,
            'pcs_eff': self.pcs_eff,
        }


# ========== SIMULATION ENGINE ==========
@dataclass
class SimHistory:
    time_min: list = field(default_factory=list)
    grid_power: list = field(default_factory=list)
    batt_power: list = field(default_factory=list)
    bus_power: list = field(default_factory=list)
    efficiency: list = field(default_factory=list)
    active_pcs: list = field(default_factory=list)
    pcs_load_pct: list = field(default_factory=list)
    pcs_eff: list = field(default_factory=list)
    soc: list = field(default_factory=lambda: [[] for _ in range(14)])
    alloc_counts: dict = field(default_factory=lambda: {})
    swap_events: list = field(default_factory=list)
    group_allocs: list = field(default_factory=lambda: [[] for _ in range(7)])


def run_simulation(cfg: Config) -> Tuple['Station', SimHistory]:
    """執行完整模擬"""
    station = Station(cfg)
    history = SimHistory()
    duration_s = cfg.sim_duration_min * 60
    sim_time = 0.0
    step_count = 0

    print(f"開始模擬: 時長 {cfg.sim_duration_min} 分鐘, 步進 {cfg.time_step_s} 秒")
    print(f"換電間隔: {cfg.swap_interval_s} 秒, SOC 門檻: {cfg.soc_threshold}%")
    print(f"DCDC: {cfg.dcdc_max_power_kw} kW x3/組, PCS: {cfg.pcs_max_power_kw} kW x{cfg.num_pcs} (並聯)")
    print("-" * 60)

    while sim_time < duration_s:
        old_swap_count = station.swap_count
        station.step()
        sim_time += cfg.time_step_s
        step_count += 1

        # Record history
        t_min = sim_time / 60
        metrics = station.get_metrics()
        history.time_min.append(t_min)
        history.grid_power.append(metrics['grid_power'])
        history.batt_power.append(metrics['batt_power'])
        history.bus_power.append(metrics['bus_power'])
        history.efficiency.append(metrics['efficiency'] if metrics['efficiency'] > 0 else None)
        history.active_pcs.append(metrics['active_pcs'])
        history.pcs_load_pct.append(metrics['pcs_load_pct'])
        history.pcs_eff.append(metrics['pcs_eff'] * 100 if metrics['pcs_eff'] > 0 else None)

        for i in range(14):
            b = station.batteries[i]
            history.soc[i].append(b.soc if b.present else None)

        for g_idx, g in enumerate(station.groups):
            alloc_key = f"{g.alloc_a}:{g.alloc_b}"
            history.alloc_counts[alloc_key] = history.alloc_counts.get(alloc_key, 0) + 1
            history.group_allocs[g_idx].append((g.alloc_a, g.alloc_b))

        if station.swap_count > old_swap_count:
            history.swap_events.append(t_min)

        # Progress report
        if step_count % (300 // int(cfg.time_step_s)) == 0:
            print(f"  [{t_min:6.1f} 分] 電網: {metrics['grid_power']:7.1f} kW | "
                  f"母線: {metrics['bus_power']:7.1f} kW | "
                  f"充電: {metrics['batt_power']:7.1f} kW | "
                  f"PCS: {metrics['active_pcs']}/{cfg.num_pcs}台 {metrics['pcs_load_pct']:.0f}% | "
                  f"效率: {metrics['efficiency']:5.1f}% | "
                  f"換電: {station.swap_count} 次")

    print("-" * 60)
    print(f"模擬完成! 總換電 {station.swap_count} 次, "
          f"累計充電 {station.total_energy_kwh:.1f} kWh")

    return station, history



# ========== VISUALIZATION ==========
BATT_COLORS = [
    '#e6194b', '#3cb44b', '#4363d8', '#f58231', '#911eb4', '#42d4f4', '#f032e6',
    '#469990', '#dcbeff', '#9A6324', '#ffe119', '#800000', '#aaffc3', '#000075'
]


def plot_dashboard(station: Station, history: SimHistory, cfg: Config, output_path: str = 'ems_simulation_result.png'):
    """繪製完整儀表板"""
    fig = plt.figure(figsize=(24, 18))
    fig.suptitle('換電站 EMS 模擬結果 (Battery Swap Station EMS Simulation)',
                 fontsize=16, fontweight='bold', y=0.98)

    gs = gridspec.GridSpec(3, 3, hspace=0.35, wspace=0.3,
                           left=0.06, right=0.96, top=0.94, bottom=0.04)

    # --- Panel 1: SOC over time (large, top-left 2 cols) ---
    ax1 = fig.add_subplot(gs[0, :2])
    for i in range(14):
        soc_data = history.soc[i]
        ax1.plot(history.time_min, soc_data, color=BATT_COLORS[i],
                 linewidth=1.2, alpha=0.85, label=f'#{i+1}')
    # Mark swap events
    for t in history.swap_events:
        ax1.axvline(x=t, color='red', alpha=0.08, linewidth=0.5)
    ax1.axhline(y=cfg.soc_threshold, color='gray', linestyle='--', alpha=0.5, label=f'門檻 {cfg.soc_threshold}%')
    ax1.set_xlabel('時間 (分鐘)')
    ax1.set_ylabel('SOC (%)')
    ax1.set_title('14 顆電池 SOC 變化')
    ax1.set_ylim(-2, 105)
    ax1.legend(loc='center left', bbox_to_anchor=(1.01, 0.5), fontsize=8, ncol=1)
    ax1.grid(True, alpha=0.3)

    # --- Panel 2: DCDC Allocation Statistics (top-right) ---
    ax2 = fig.add_subplot(gs[0, 2])
    alloc_labels = sorted(history.alloc_counts.keys(),
                          key=lambda x: history.alloc_counts[x], reverse=True)
    alloc_vals = [history.alloc_counts[k] for k in alloc_labels]
    colors_alloc = ['#4caf50', '#ff9800', '#8bc34a', '#ffc107', '#29b6f6',
                    '#66bb6a', '#ffb74d', '#81c784', '#fff176', '#bdbdbd']
    bars = ax2.bar(alloc_labels, alloc_vals,
                   color=colors_alloc[:len(alloc_labels)], edgecolor='white')
    for bar, val in zip(bars, alloc_vals):
        ax2.text(bar.get_x() + bar.get_width()/2, bar.get_height() + max(alloc_vals)*0.01,
                 str(val), ha='center', va='bottom', fontsize=8)
    ax2.set_xlabel('DCDC 分配 (A:B)')
    ax2.set_ylabel('出現次數')
    ax2.set_title('DCDC 分配統計')
    ax2.grid(True, alpha=0.3, axis='y')

    # --- Panel 3: Power over time (middle-left) ---
    ax3 = fig.add_subplot(gs[1, 0])
    ax3.fill_between(history.time_min, history.grid_power,
                     alpha=0.3, color='#c62828', label='電網功率')
    ax3.plot(history.time_min, history.grid_power,
             color='#c62828', linewidth=1.5)
    ax3.fill_between(history.time_min, history.batt_power,
                     alpha=0.3, color='#2e7d32', label='充電功率')
    ax3.plot(history.time_min, history.batt_power,
             color='#2e7d32', linewidth=1.5)
    ax3.set_xlabel('時間 (分鐘)')
    ax3.set_ylabel('功率 (kW)')
    ax3.set_title('功率分佈')
    ax3.legend(fontsize=9)
    ax3.grid(True, alpha=0.3)

    # --- Panel 4: System & PCS Efficiency + Active PCS (middle-center) ---
    ax4 = fig.add_subplot(gs[1, 1])
    eff_clean = [e if e is not None else 0 for e in history.efficiency]
    pcs_eff_clean = [e if e is not None else 0 for e in history.pcs_eff]
    ax4.plot(history.time_min, eff_clean, color='#1565c0', linewidth=1.5, label='系統效率')
    ax4.plot(history.time_min, pcs_eff_clean, color='#ff9800', linewidth=1, alpha=0.7, label='PCS 效率')
    ax4.fill_between(history.time_min, eff_clean, alpha=0.1, color='#1565c0')
    if eff_clean:
        valid_eff = [e for e in eff_clean if e > 0]
        if valid_eff:
            avg_eff = np.mean(valid_eff)
            ax4.axhline(y=avg_eff, color='gray', linestyle='--', alpha=0.5,
                        label=f'平均系統效率 {avg_eff:.1f}%')
    # Secondary axis for active PCS count
    ax4b = ax4.twinx()
    ax4b.plot(history.time_min, history.active_pcs, color='#4caf50',
              linewidth=1, alpha=0.6, linestyle='-', drawstyle='steps-post')
    ax4b.set_ylabel('啟用 PCS 台數', color='#4caf50', fontsize=9)
    ax4b.set_ylim(0, cfg.num_pcs + 1)
    ax4b.tick_params(axis='y', labelcolor='#4caf50')
    ax4.set_xlabel('時間 (分鐘)')
    ax4.set_ylabel('效率 (%)')
    ax4.set_title(f'系統效率 & PCS 並聯控制 ({cfg.num_pcs} 台)')
    ax4.set_ylim(85, 100)
    ax4.legend(fontsize=8, loc='lower left')
    ax4.grid(True, alpha=0.3)

    # --- Panel 5: Group allocation timeline (middle-right) ---
    ax5 = fig.add_subplot(gs[1, 2])
    alloc_to_num = {'0:0': 0, '0:1': 1, '1:0': 2, '0:2': 3, '2:0': 4,
                    '1:1': 5, '0:3': 6, '3:0': 7, '1:2': 8, '2:1': 9}
    alloc_labels_map = ['0:0', '0:1', '1:0', '0:2', '2:0', '1:1', '0:3', '3:0', '1:2', '2:1']
    for g_idx in range(7):
        allocs = history.group_allocs[g_idx]
        alloc_nums = [alloc_to_num.get(f"{a}:{b}", 0) for a, b in allocs]
        # Downsample for readability
        step = max(1, len(alloc_nums) // 200)
        t_ds = [history.time_min[i] for i in range(0, len(alloc_nums), step)]
        a_ds = [alloc_nums[i] for i in range(0, len(alloc_nums), step)]
        ax5.scatter(t_ds, [g_idx] * len(t_ds), c=a_ds, cmap='tab10',
                    vmin=0, vmax=9, s=4, marker='s', alpha=0.8)
    ax5.set_yticks(range(7))
    ax5.set_yticklabels([f'G{i+1}' for i in range(7)])
    ax5.set_xlabel('時間 (分鐘)')
    ax5.set_title('各組 DCDC 分配時序 (顏色=分配方式)')
    ax5.grid(True, alpha=0.3)

    # --- Panel 6: Topology Diagram (bottom-left 2 cols) ---
    ax6 = fig.add_subplot(gs[2, :2])
    ax6.set_xlim(0, 100)
    ax6.set_ylim(-2, 9)
    ax6.set_aspect('auto')
    ax6.axis('off')
    ax6.set_title('站體拓撲與最終開關狀態', fontsize=12, fontweight='bold')

    # Draw PCS parallel bank (shared, at top)
    pcs_y = 8.3
    ax6.add_patch(FancyBboxPatch((1, pcs_y-0.35), 18, 0.7, boxstyle="round,pad=0.1",
                                 facecolor='#e3f2fd', edgecolor='#1565c0', linewidth=1.5))
    ax6.text(10, pcs_y, f'PCS x{station.active_pcs}/{cfg.num_pcs} 並聯 | '
             f'負載 {station.pcs_load_pct:.0f}% | '
             f'效率 {station.pcs_eff*100:.1f}% | '
             f'電網 {station.grid_power:.0f}kW',
             fontsize=8, ha='center', va='center', color='#0d47a1', fontweight='bold')

    # 800V DC Bus (shared horizontal bar)
    bus_y = 7.5
    ax6.add_patch(FancyBboxPatch((1, bus_y-0.15), 18, 0.3, boxstyle="round,pad=0.02",
                                 facecolor='#fff3e0', edgecolor='#e65100', linewidth=1.5))
    ax6.text(10, bus_y, f'800Vdc 共用母線 | {station.pcs_total_load:.0f} kW',
             fontsize=7, ha='center', va='center', color='#e65100', fontweight='bold')

    # Draw topology for each DCDC group
    for g_idx in range(7):
        y = 6.5 - g_idx
        grp = station.groups[g_idx]

        # Group label
        ax6.text(1, y, f'G{g_idx+1}', fontsize=9, fontweight='bold',
                 ha='center', va='center')

        # Bus tap line
        ax6.plot([10, 10, 20, 20], [bus_y - 0.15, y, y, y], color='#e65100',
                 linewidth=0.5, alpha=0.3)

        # Arrow from bus
        ax6.annotate('', xy=(22.5, y), xytext=(20, y),
                     arrowprops=dict(arrowstyle='->', color='#bbb', lw=1.2))

        # 3 DCDC boxes
        for d in range(3):
            dx = 23 + d * 8
            if d < grp.alloc_a:
                dc_color, dc_edge, dc_label = '#e8f5e9', '#4caf50', f'DC→A'
            elif d < grp.alloc_a + grp.alloc_b:
                dc_color, dc_edge, dc_label = '#fff8e1', '#ff9800', f'DC→B'
            else:
                dc_color, dc_edge, dc_label = '#eeeeee', '#bdbdbd', 'OFF'
            ax6.add_patch(FancyBboxPatch((dx, y-0.3), 6, 0.6, boxstyle="round,pad=0.05",
                                         facecolor=dc_color, edgecolor=dc_edge, linewidth=1))
            ax6.text(dx+3, y, dc_label, fontsize=6, ha='center', va='center')

        # Arrow
        ax6.annotate('', xy=(49, y), xytext=(47.5, y),
                     arrowprops=dict(arrowstyle='->', color='#bbb', lw=1.2))

        # Battery A
        ba = grp.batt_a
        ba_color = '#e8f5e9' if ba.present and ba.soc < cfg.soc_threshold else '#e3f2fd' if ba.present else '#ffebee'
        ba_edge = '#4caf50' if ba.present and ba.soc < cfg.soc_threshold else '#1565c0' if ba.present else '#ef5350'
        ax6.add_patch(FancyBboxPatch((50, y-0.35), 14, 0.7, boxstyle="round,pad=0.1",
                                     facecolor=ba_color, edgecolor=ba_edge, linewidth=1.5))
        ba_text = f'#{ba.id} {ba.soc:.1f}%' if ba.present else f'#{ba.id} 缺席'
        ax6.text(57, y, ba_text, fontsize=7, ha='center', va='center', fontweight='bold')

        # Battery B
        bb = grp.batt_b
        bb_color = '#e8f5e9' if bb.present and bb.soc < cfg.soc_threshold else '#e3f2fd' if bb.present else '#ffebee'
        bb_edge = '#4caf50' if bb.present and bb.soc < cfg.soc_threshold else '#1565c0' if bb.present else '#ef5350'
        ax6.add_patch(FancyBboxPatch((66, y-0.35), 14, 0.7, boxstyle="round,pad=0.1",
                                     facecolor=bb_color, edgecolor=bb_edge, linewidth=1.5))
        bb_text = f'#{bb.id} {bb.soc:.1f}%' if bb.present else f'#{bb.id} 缺席'
        ax6.text(73, y, bb_text, fontsize=7, ha='center', va='center', fontweight='bold')

        # Allocation label
        ax6.text(84, y, f'[{grp.alloc_a}:{grp.alloc_b}]', fontsize=8,
                 ha='center', va='center', fontweight='bold',
                 color='#1565c0',
                 bbox=dict(boxstyle='round,pad=0.2', facecolor='#e3f2fd', edgecolor='#90caf9'))

        # Efficiency
        total_batt_g = grp.power_a + grp.power_b
        dcdc_eff_g = total_batt_g / grp.dc_bus_power * 100 if grp.dc_bus_power > 0 else 0
        eff_str = f'{dcdc_eff_g:.1f}%' if dcdc_eff_g > 0 else '--'
        ax6.text(92, y, f'η={eff_str}', fontsize=7, ha='center', va='center', color='#555')

    # Legend for topology
    legend_elements = [
        Line2D([0],[0], marker='s', color='w', markerfacecolor='#e8f5e9', markeredgecolor='#4caf50', markersize=10, label='充電中'),
        Line2D([0],[0], marker='s', color='w', markerfacecolor='#e3f2fd', markeredgecolor='#1565c0', markersize=10, label='已充滿'),
        Line2D([0],[0], marker='s', color='w', markerfacecolor='#ffebee', markeredgecolor='#ef5350', markersize=10, label='缺席'),
        Line2D([0],[0], marker='s', color='w', markerfacecolor='#fff8e1', markeredgecolor='#ff9800', markersize=10, label='DCDC→B'),
        Line2D([0],[0], marker='s', color='w', markerfacecolor='#eeeeee', markeredgecolor='#bdbdbd', markersize=10, label='DCDC OFF'),
    ]
    ax6.legend(handles=legend_elements, loc='lower center', ncol=5, fontsize=8,
               bbox_to_anchor=(0.5, -0.15))

    # --- Panel 7: Summary Statistics (bottom-right) ---
    ax7 = fig.add_subplot(gs[2, 2])
    ax7.axis('off')
    ax7.set_title('模擬統計摘要', fontsize=12, fontweight='bold')

    metrics = station.get_metrics()
    valid_eff = [e for e in history.efficiency if e is not None and e > 0]
    avg_eff = np.mean(valid_eff) if valid_eff else 0
    avg_grid = np.mean(history.grid_power)
    avg_batt = np.mean(history.batt_power)

    stats_text = (
        f"模擬時長:   {cfg.sim_duration_min} 分鐘\n"
        f"換電間隔:   {cfg.swap_interval_s} 秒\n"
        f"SOC 門檻:   {cfg.soc_threshold}%\n"
        f"入站 SOC:   0~{cfg.incoming_soc_max}%\n"
        f"{'─'*30}\n"
        f"總換電次數: {station.swap_count} 次\n"
        f"累計充電量: {station.total_energy_kwh:.1f} kWh\n"
        f"平均電網功率: {avg_grid:.1f} kW\n"
        f"平均充電功率: {avg_batt:.1f} kW\n"
        f"平均系統效率: {avg_eff:.1f}%\n"
        f"{'─'*30}\n"
        f"電池容量:   {cfg.batt_capacity_kwh} kWh\n"
        f"DCDC 容量:  {cfg.dcdc_max_power_kw} kW x3/組\n"
        f"PCS 容量:   {cfg.pcs_max_power_kw} kW x{cfg.num_pcs} (並聯)\n"
        f"PCS 最終狀態: {station.active_pcs}/{cfg.num_pcs} 台\n"
        f"{'─'*30}\n"
        f"DCDC 分配統計:\n"
    )
    for k in sorted(history.alloc_counts.keys(),
                    key=lambda x: history.alloc_counts[x], reverse=True)[:6]:
        pct = history.alloc_counts[k] / sum(history.alloc_counts.values()) * 100
        stats_text += f"  {k}: {history.alloc_counts[k]} 次 ({pct:.1f}%)\n"

    ax7.text(0.05, 0.95, stats_text, transform=ax7.transAxes,
             fontsize=10, verticalalignment='top',
             bbox=dict(boxstyle='round', facecolor='#f5f5f5', alpha=0.8))

    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    print(f"\n圖表已儲存至: {output_path}")
    plt.close()


# ========== SWITCH STATE REPORT ==========
def print_switch_table(station: Station, cfg: Config):
    """印出各組 DCDC 分配詳情 + PCS 並聯狀態"""
    print("\n" + "=" * 105)
    print(f"PCS 並聯狀態: {station.active_pcs}/{cfg.num_pcs} 台啟用 | "
          f"每台負載: {station.pcs_load_per_unit:.1f} kW ({station.pcs_load_pct:.1f}%) | "
          f"PCS 效率: {station.pcs_eff*100:.1f}% | "
          f"母線總負載: {station.pcs_total_load:.1f} kW | "
          f"電網總功率: {station.grid_power:.1f} kW")
    print("=" * 105)
    print("各組 DCDC 開關分配詳情")
    print("-" * 105)
    header = f"{'組別':^6}|{'電池A (ID/SOC)':^18}|{'電池B (ID/SOC)':^18}|{'分配(A:B)':^10}|" \
             f"{'功率A(kW)':^10}|{'功率B(kW)':^10}|{'DCDC負載%':^10}|{'母線取用kW':^12}|{'DCDC效率':^10}"
    print(header)
    print("-" * 105)

    for g in station.groups:
        ba_str = f"#{g.batt_a.id} / {g.batt_a.soc:.1f}%" if g.batt_a.present else f"#{g.batt_a.id} / 缺席"
        bb_str = f"#{g.batt_b.id} / {g.batt_b.soc:.1f}%" if g.batt_b.present else f"#{g.batt_b.id} / 缺席"
        alloc_str = f"{g.alloc_a}:{g.alloc_b}"
        total_dcdc = g.alloc_a + g.alloc_b
        avg_dcdc_load = (g.dcdc_load_a * g.alloc_a + g.dcdc_load_b * g.alloc_b) / max(1, total_dcdc)
        total_batt = g.power_a + g.power_b
        dcdc_eff = total_batt / g.dc_bus_power * 100 if g.dc_bus_power > 0 else 0
        eff_str = f"{dcdc_eff:.1f}%" if dcdc_eff > 0 else "--"

        print(f"  G{g.group_id+1}  |{ba_str:^18}|{bb_str:^18}|{alloc_str:^10}|"
              f"{g.power_a:^10.1f}|{g.power_b:^10.1f}|{avg_dcdc_load:^10.1f}|{g.dc_bus_power:^12.1f}|{eff_str:^10}")
    print("=" * 105)


# ========== MAIN ==========
def main():
    parser = argparse.ArgumentParser(description='換電站 EMS 模擬工具')
    parser.add_argument('--duration', type=float, default=120, help='模擬時長 (分鐘), 預設 120')
    parser.add_argument('--time-step', type=float, default=10, help='時間步進 (秒), 預設 10')
    parser.add_argument('--swap-interval', type=float, default=100, help='換電間隔 (秒), 預設 100')
    parser.add_argument('--soc-threshold', type=float, default=90, help='充電門檻 SOC%%, 預設 90')
    parser.add_argument('--incoming-soc-max', type=float, default=30, help='入站最高 SOC%%, 預設 30')
    parser.add_argument('--batt-capacity', type=float, default=50, help='電池容量 (kWh), 預設 50')
    parser.add_argument('--dcdc-power', type=float, default=50, help='DCDC 容量 (kW), 預設 50')
    parser.add_argument('--pcs-power', type=float, default=125, help='PCS 容量 (kW), 預設 125')
    parser.add_argument('--output', type=str, default='ems_simulation_result.png', help='輸出圖檔路徑')
    parser.add_argument('--seed', type=int, default=None, help='隨機種子 (可重複結果)')
    args = parser.parse_args()

    if args.seed is not None:
        random.seed(args.seed)
        np.random.seed(args.seed)

    cfg = Config(
        sim_duration_min=args.duration,
        time_step_s=args.time_step,
        swap_interval_s=args.swap_interval,
        soc_threshold=args.soc_threshold,
        incoming_soc_max=args.incoming_soc_max,
        batt_capacity_kwh=args.batt_capacity,
        dcdc_max_power_kw=args.dcdc_power,
        pcs_max_power_kw=args.pcs_power,
    )

    station, history = run_simulation(cfg)
    print_switch_table(station, cfg)
    plot_dashboard(station, history, cfg, args.output)


if __name__ == '__main__':
    main()

