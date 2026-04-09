"""硬編碼紅線檢查 — 不信任任何 LLM 輸出。

GUARD prompt 是第一道（軟），這檔是第二道（硬）。
任何一條紅線觸發 → 整個 proposal 整批拒絕，不允許部分下發。
"""

# 雙閘設計：影子模式關閉與此值同時為 True 才會真實下發
ENABLE_REAL_DISPATCH = False

# 站點硬限制
MAX_PCS_POWER_KW = 250.0
MIN_SOC = 0.05
MAX_SOC = 0.98
MAX_RAMP_RATE_KW_PER_S = 50.0
MAX_BATTERY_TEMP_C = 45.0
MIN_TWIN_CONFIDENCE = 0.70

ALLOWED_ACTION_TYPES = {
    "charge", "discharge", "idle",
    "switch_pcs_dcdc", "ac_setpoint",
    "respond_dr", "publish_app_notice",
}


def enforce_red_lines(proposal: dict, sim: dict, verdict: dict) -> tuple[bool, str | None]:
    """回傳 (是否通過, 失敗原因)。失敗時應整批拒絕下發。"""

    # 基本一致性
    if not isinstance(proposal, dict) or "actions" not in proposal:
        return False, "proposal 結構無效"

    # GUARD 必須說 approved
    if verdict.get("status") != "approved":
        return False, f"GUARD status={verdict.get('status')}"

    # TWIN 必須說 feasible 且信心夠
    if not sim.get("feasible"):
        return False, "TWIN 判定不可行"
    if sim.get("confidence", 0) < MIN_TWIN_CONFIDENCE:
        return False, f"TWIN 信心度 {sim.get('confidence')} < {MIN_TWIN_CONFIDENCE}"

    # TWIN 預估的最高溫不可超紅線
    kpi = sim.get("expected_kpi", {})
    if kpi.get("max_battery_temp_c", 0) > MAX_BATTERY_TEMP_C:
        return False, f"預估溫度 {kpi.get('max_battery_temp_c')}°C 超紅線"
    if kpi.get("max_pcs_loading", 0) > 1.0:
        return False, f"預估 PCS 負載 {kpi.get('max_pcs_loading')} > 1.0"

    # 逐個 action 檢查
    for i, action in enumerate(proposal["actions"]):
        atype = action.get("action_type")
        if atype not in ALLOWED_ACTION_TYPES:
            return False, f"action[{i}]: 未知 action_type={atype}"

        power = abs(action.get("target_power_kw", 0))
        if power > MAX_PCS_POWER_KW:
            return False, f"action[{i}]: 功率 {power}kW 超 PCS 上限"

        soc_min = action.get("target_soc_min")
        if soc_min is not None and soc_min < MIN_SOC:
            return False, f"action[{i}]: SOC 下限 {soc_min} < {MIN_SOC}"

        soc_max = action.get("target_soc_max")
        if soc_max is not None and soc_max > MAX_SOC:
            return False, f"action[{i}]: SOC 上限 {soc_max} > {MAX_SOC}"

    return True, None
