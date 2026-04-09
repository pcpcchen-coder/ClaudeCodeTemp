# 報告 01 — Orchestrator ⇄ GUARD JSON Schema 規範

> 目標：定義 ORCH 與 GUARD（以及 TWIN）之間的通訊契約，讓 Agent 之間用 structured data 溝通而非自由文字。所有 schema 都用 **JSON Schema Draft 2020-12**，可直接餵給 Pydantic、Zod、或 Anthropic API 的 `tools` 欄位。

---

## 為什麼要用 schema 而不是自由文字？

| 自由文字 | Structured JSON |
|---|---|
| LLM 偶爾漏欄位 | 缺欄位直接 validation 失敗 |
| 難寫單元測試 | 可用 hypothesis 自動產生 fuzz cases |
| 下游程式要 regex 解析 | 直接 `json.loads` |
| 變更欄位需重訓 prompt | 變更 schema，prompt 自動跟上 |

對你的場景特別重要：**GUARD 否決時的 reason 必須是機器可讀**，不然儀表板沒辦法畫出否決熱區圖。

---

## 三個核心 schema

1. **`orch_proposal.schema.json`** — ORCH 給 TWIN 與 GUARD 的提案
2. **`twin_simulation_result.schema.json`** — TWIN 回給 ORCH 的模擬結果
3. **`guard_verdict.schema.json`** — GUARD 回給 ORCH 的審核結果

---

## 步驟 1：把三份 schema 放進你的 repo

建議目錄：
```
ems-agent-team/
└── schemas/
    ├── orch_proposal.schema.json
    ├── twin_simulation_result.schema.json
    └── guard_verdict.schema.json
```

三份 schema 的完整內容已附在本資料夾的 `schemas/` 子目錄。

---

## 步驟 2：在 Python 端產生 Pydantic model

```bash
pip install datamodel-code-generator
datamodel-codegen \
  --input schemas/orch_proposal.schema.json \
  --input-file-type jsonschema \
  --output ems/models/orch_proposal.py \
  --output-model-type pydantic_v2.BaseModel
```

對另兩份重複此步。產出後 import 即可：

```python
from ems.models.orch_proposal import OrchProposal
from ems.models.guard_verdict import GuardVerdict

proposal = OrchProposal.model_validate(llm_response_json)
```

---

## 步驟 3：在 Anthropic API 呼叫時用 tool schema 強制輸出

把 schema 包成 tool，模型就會被強制吐合法 JSON：

```python
import anthropic, json

client = anthropic.Anthropic()

with open("schemas/orch_proposal.schema.json") as f:
    proposal_schema = json.load(f)

response = client.messages.create(
    model="claude-opus-4-6",
    max_tokens=4096,
    system=ORCH_SYSTEM_PROMPT,
    tools=[{
        "name": "submit_proposal",
        "description": "Submit the tick's action proposal to TWIN and GUARD",
        "input_schema": proposal_schema,
    }],
    tool_choice={"type": "tool", "name": "submit_proposal"},
    messages=[{"role": "user", "content": state_snapshot_json}],
)

proposal = response.content[0].input  # 已是合法 dict
```

對 GUARD 與 TWIN 也用同樣手法，分別 force 輸出 `guard_verdict` 與 `twin_simulation_result`。

---

## 步驟 4：在 dispatch 前做雙重驗證

```python
from jsonschema import validate, ValidationError

def safe_dispatch(proposal: dict, sim: dict, verdict: dict):
    # 第一層：schema 驗證
    validate(proposal, proposal_schema)
    validate(sim,      twin_schema)
    validate(verdict,  guard_schema)
    
    # 第二層：商業邏輯驗證
    if verdict["status"] != "approved":
        raise PermissionError(f"GUARD 否決：{verdict['rejection_reason']}")
    if sim["confidence"] < 0.7:
        raise RuntimeError("TWIN 信心度過低，需人類覆核")
    if not sim["feasible"]:
        raise RuntimeError("TWIN 判定不可行")
    
    # 第三層：硬編碼紅線（不信任 prompt）
    for action in proposal["actions"]:
        assert action["target_power_kw"] <= MAX_PCS_POWER, "超過 PCS 額定"
        assert 0.05 <= action["target_soc_min"], "SOC 下限違規"
    
    return execute(proposal["actions"])
```

**第三層硬編碼是關鍵**：再聰明的 prompt 也可能漏判，紅線一定要寫死在 code。

---

## Schema 設計的三個原則

1. **欄位命名 snake_case 全小寫**：和你 Python 後端一致，省 mapping 工
2. **時間一律 ISO 8601 + UTC**：避免時區地獄
3. **每個 enum 都有 `unknown` 選項**：LLM 偶爾會給出意外類別，與其讓 schema validation 死掉，不如先收進來再警告

---

## 升級策略

Schema 一旦上線就不能隨便改。建議：
- 在 schema 加 `"$id"` 含版本號（例：`https://ems.example.com/schemas/orch_proposal/v1`）
- 加新欄位時設 `optional`，舊版 Agent 仍可運作
- 真要破壞性升級時，並行跑 v1 與 v2 一段時間，dashboard 顯示版本佔比

---

## 下一步

- 把 `schemas/` 目錄與本文件 commit 到你的 EMS repo
- 用 `datamodel-code-generator` 產出 Pydantic models
- 在現有 EMS 的決策模組外面包一層 wrapper，先讓它輸出符合 `OrchProposal` schema 的格式（不需真的接 LLM），驗證下游 pipeline 通順
- 然後才把真正的 LLM Agent 接上去
