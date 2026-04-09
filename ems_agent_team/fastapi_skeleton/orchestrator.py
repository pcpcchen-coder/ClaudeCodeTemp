"""ORCH 主循環：snapshot → 並行諮詢執行層 → TWIN → GUARD → 落地。"""
import asyncio
import uuid
from datetime import datetime, timezone

from agents import (
    call_orch,
    call_price, call_batt, call_disp, call_grid, call_app,
    call_twin,
    call_guard,
)
from safety_hardcoded import enforce_red_lines, ENABLE_REAL_DISPATCH
from shadow_log import save_decision, fetch_decision, fetch_recent
from settings import settings


async def fetch_state_snapshot() -> dict:
    """從 MQTT / InfluxDB 拉一個窗口的 state。

    這裡用假資料佔位。實際接線時換成你的 MQTT client + Influx query。
    """
    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "site_id": "ZHUBEI-01",
        "batteries": [
            {"id": f"BATT-{i:02d}", "soc": 0.62, "soh": 0.97, "temp_c": 28.5}
            for i in range(1, 21)
        ],
        "pcs": [
            {"id": f"PCS-{i:02d}", "loading": 0.55, "online": True}
            for i in range(1, 8)
        ],
        "grid": {"frequency_hz": 50.02, "voltage_pu": 1.01, "tariff_cny_kwh": 0.42},
        "queue": {"vehicles_waiting": 2, "predicted_demand_4h": 18},
    }


async def run_tick() -> dict:
    tick_id = str(uuid.uuid4())
    print(f"[orch] tick {tick_id[:8]}... start")

    snapshot = await fetch_state_snapshot()

    # 1. 並行諮詢執行層
    price, batt, disp, grid, app_resp = await asyncio.gather(
        call_price(snapshot),
        call_batt(snapshot),
        call_disp(snapshot),
        call_grid(snapshot),
        call_app(snapshot),
        return_exceptions=True,
    )
    sub_responses = {
        "PRICE": price, "BATT": batt, "DISP": disp,
        "GRID": grid, "APP": app_resp,
    }

    # 2. ORCH 整合為 proposal
    proposal = await call_orch(tick_id, snapshot, sub_responses)
    print(f"[orch]   state={proposal.get('state_class')} actions={len(proposal.get('actions', []))}")

    # 3. TWIN 預演
    sim = await call_twin(proposal)
    print(f"[twin]   feasible={sim.get('feasible')} confidence={sim.get('confidence')}")

    # 4. GUARD 守門
    verdict = await call_guard(proposal, sim)
    print(f"[guard]  status={verdict.get('status')}")

    # 5. 硬編碼紅線（不信任 prompt）
    hardcoded_ok, hardcoded_reason = enforce_red_lines(proposal, sim, verdict)

    # 6. 落地
    record = {
        "tick_id": tick_id,
        "snapshot": snapshot,
        "sub_responses": sub_responses,
        "proposal": proposal,
        "twin_result": sim,
        "guard_verdict": verdict,
        "hardcoded_ok": hardcoded_ok,
        "hardcoded_reason": hardcoded_reason,
        "executed": False,
        "shadow_mode": settings.shadow_mode,
    }

    # 7. 真實下發只有在三個閘門都過時才會發生
    will_dispatch = (
        not settings.shadow_mode
        and ENABLE_REAL_DISPATCH
        and verdict.get("status") == "approved"
        and hardcoded_ok
    )
    if will_dispatch:
        await dispatch_for_real(proposal)
        record["executed"] = True
    else:
        print(f"[shadow] would dispatch {len(proposal.get('actions', []))} actions (NOT EXECUTED)")

    await save_decision(record)
    return record


async def dispatch_for_real(proposal: dict):
    """真實下發到 PCS / DCDC。預設禁用。"""
    raise NotImplementedError("真實下發在影子模式驗證完成前禁止使用")


async def get_tick_record(tick_id: str) -> dict | None:
    return await fetch_decision(tick_id)


async def list_recent_ticks(limit: int) -> list[dict]:
    return await fetch_recent(limit)
