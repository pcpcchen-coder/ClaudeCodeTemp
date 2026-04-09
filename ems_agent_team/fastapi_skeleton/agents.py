"""各 Agent 的 LLM 呼叫封裝。

每個 call_xxx 函式做三件事：
1. 組 system prompt（從 prompts/ 載入或直接 inline）
2. 呼叫 Anthropic API，強制 tool use 輸出 JSON
3. 回 dict

注意：本檔示範用 stub 回應，方便你在沒有 API key 時也能 docker up 跑通。
真正接 API 時，把 _stub_response 內的內容換成 anthropic.Anthropic().messages.create 即可。
"""
import json
import os
from datetime import datetime, timezone

# from anthropic import AsyncAnthropic
# client = AsyncAnthropic(api_key=os.environ["ANTHROPIC_API_KEY"])

USE_STUB = os.environ.get("ANTHROPIC_API_KEY", "").startswith("sk-ant-") is False


# ---------------- Prompts（精簡版，正式版見總覽文件） ----------------

ORCH_PROMPT = """你是換電站 EMS 的最高決策 Agent，代號 ORCH。
依「安全 > 合規 > 收益 > 用戶體驗」順序整合下級 Agent 的回覆，
吐出符合 OrchProposal schema 的 JSON。"""

PRICE_PROMPT = """你是電價套利 Agent。給出未來 4h 的充放電建議。"""
BATT_PROMPT = """你是電池健康 Agent。給出每個電池的健康分級與本 tick 可用性。"""
DISP_PROMPT = """你是 PCS/DCDC 調度 Agent。給出三切二拓樸下的最佳通道組合。"""
GRID_PROMPT = """你是電網互動 Agent。處理 VPP / DR 訊號。"""
APP_PROMPT = """你是用戶 App 後台。預測未來 4h 換電需求。"""
TWIN_PROMPT = """你是 Digital Twin Agent。預演 OrchProposal 的物理可行性與 KPI。"""
GUARD_PROMPT = """你是 Safety & Compliance 守門員。對 proposal 做最終審核。"""


# ---------------- 共用 LLM 呼叫 ----------------

async def _call_llm(system: str, user_payload: dict, tool_schema: dict, tool_name: str) -> dict:
    if USE_STUB:
        return _stub_response(tool_name, user_payload)

    # 真實版本（取消註解並裝 anthropic）
    # response = await client.messages.create(
    #     model=os.environ.get("ANTHROPIC_MODEL", "claude-opus-4-6"),
    #     max_tokens=4096,
    #     system=system,
    #     tools=[{"name": tool_name, "description": "submit", "input_schema": tool_schema}],
    #     tool_choice={"type": "tool", "name": tool_name},
    #     messages=[{"role": "user", "content": json.dumps(user_payload, ensure_ascii=False)}],
    # )
    # for block in response.content:
    #     if block.type == "tool_use":
    #         return block.input
    # raise RuntimeError("LLM did not return tool_use block")


def _stub_response(tool_name: str, payload: dict) -> dict:
    """沒設 API key 時的假回應，讓 pipeline 跑得通。"""
    now = datetime.now(timezone.utc).isoformat()
    if tool_name == "orch_proposal":
        return {
            "tick_id": payload.get("tick_id", "stub"),
            "timestamp": now,
            "state_class": "normal",
            "actions": [
                {
                    "action_type": "charge",
                    "target_id": "BATT-01",
                    "target_power_kw": 30.0,
                    "target_soc_min": 0.2,
                    "target_soc_max": 0.85,
                    "duration_seconds": 300,
                    "priority": 5,
                }
            ],
            "rationale": "stub: off-peak charging on healthy battery",
            "consulted_agents": ["PRICE", "BATT", "DISP"],
            "estimated_revenue_cny": 12.5,
            "human_intervention_needed": False,
        }
    if tool_name == "twin_simulation_result":
        return {
            "tick_id": payload.get("tick_id", "stub"),
            "simulated_at": now,
            "feasible": True,
            "expected_kpi": {
                "efficiency": 0.93,
                "revenue_cny": 12.5,
                "soh_degradation_ppm": 1.2,
                "max_battery_temp_c": 31.0,
                "max_pcs_loading": 0.6,
            },
            "risks": [],
            "confidence": 0.88,
            "model_version": "stub-0.1",
        }
    if tool_name == "guard_verdict":
        return {
            "tick_id": payload.get("tick_id", "stub"),
            "checked_at": now,
            "status": "approved",
            "monitoring_points": [
                {"target_id": "BATT-01", "metric": "temperature", "threshold": 38.0, "duration_seconds": 300}
            ],
            "checked_by_rules": ["thermal_baseline", "soc_window", "pcs_loading"],
        }
    return {"stub": True, "tool_name": tool_name}


# ---------------- 對外 API ----------------

async def call_orch(tick_id: str, snapshot: dict, sub_responses: dict) -> dict:
    payload = {"tick_id": tick_id, "snapshot": snapshot, "sub": sub_responses}
    return await _call_llm(ORCH_PROMPT, payload, {}, "orch_proposal")


async def call_price(snapshot): return await _call_llm(PRICE_PROMPT, snapshot, {}, "price_advice")
async def call_batt(snapshot):  return await _call_llm(BATT_PROMPT,  snapshot, {}, "batt_status")
async def call_disp(snapshot):  return await _call_llm(DISP_PROMPT,  snapshot, {}, "disp_plan")
async def call_grid(snapshot):  return await _call_llm(GRID_PROMPT,  snapshot, {}, "grid_response")
async def call_app(snapshot):   return await _call_llm(APP_PROMPT,   snapshot, {}, "app_forecast")


async def call_twin(proposal: dict) -> dict:
    return await _call_llm(TWIN_PROMPT, proposal, {}, "twin_simulation_result")


async def call_guard(proposal: dict, sim: dict) -> dict:
    payload = {"proposal": proposal, "twin": sim}
    return await _call_llm(GUARD_PROMPT, payload, {}, "guard_verdict")
