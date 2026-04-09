# 報告 02 — Shadow Mode FastAPI 骨架

> 目標：搭一個可以馬上 `docker compose up` 的 FastAPI 服務，跑 ORCH ↔ TWIN ↔ GUARD 的完整循環，但所有對 PCS / DCDC 的下發**只寫 log 不真執行**。讓你能在生產環境並行觀察 Agent 決策與既有 EMS 的差距。

---

## 影子模式的核心原則

| 項目 | 規則 |
|---|---|
| 讀數據 | 接生產的 MQTT / InfluxDB（read-only） |
| Agent 推理 | 真的呼叫 Anthropic API |
| 決策結果 | **只寫進影子資料庫，不下發** |
| 對比 | 同步 dump 既有 EMS 的同期決策，dashboard 並排顯示 |

兩週後若 Agent 決策「偏差但合理」≤ 5%、「危險偏差」= 0，再考慮切換流量。

---

## 目錄結構

```
fastapi_skeleton/
├── main.py                # FastAPI 入口
├── orchestrator.py        # ORCH 主循環
├── agents.py              # 各 Agent 的 LLM 呼叫封裝
├── safety_hardcoded.py    # 寫死的紅線檢查（不信任 prompt）
├── shadow_log.py          # 影子決策落地
├── settings.py            # 環境變數
├── requirements.txt
└── docker-compose.yml
```

所有檔案已附在本資料夾的 `fastapi_skeleton/` 子目錄。

---

## 步驟 1：環境變數

建立 `.env`（不要 commit）：

```env
ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-opus-4-6
MQTT_BROKER=tcp://your-broker:1883
MQTT_USERNAME=ems_shadow
MQTT_PASSWORD=...
INFLUX_URL=http://your-influx:8086
INFLUX_TOKEN=...
INFLUX_ORG=ems
INFLUX_BUCKET=site_telemetry
SHADOW_DB_URL=postgresql://ems:ems@db:5432/shadow
SHADOW_MODE=true       # 關鍵：設為 false 才會真正下發
TICK_INTERVAL_SECONDS=300
```

---

## 步驟 2：本機跑起來

```bash
cd fastapi_skeleton
docker compose up -d        # 啟動 Postgres + FastAPI
docker compose logs -f api  # 看 ORCH tick log
```

正常你會看到每 5 分鐘一次：

```
[orch] tick 0192abc... state=normal
[orch]   consulting PRICE, BATT, DISP
[twin]   confidence=0.86 feasible=true
[guard]  status=approved
[shadow] would dispatch 12 actions (NOT EXECUTED)
```

---

## 步驟 3：觀察影子決策

直接連 Postgres 看：

```sql
SELECT 
  tick_id,
  state_class,
  jsonb_array_length(actions) AS n_actions,
  guard_status,
  twin_confidence,
  estimated_revenue_cny
FROM shadow_decisions
ORDER BY created_at DESC
LIMIT 20;
```

---

## 步驟 4：對比與評估

每天跑一次離線比較腳本（不在本骨架內，但目錄留好 `analytics/`）：

```sql
-- 找出 Agent 與既有 EMS 決策方向相反的 tick
SELECT tick_id, shadow_total_kw, baseline_total_kw
FROM shadow_decisions s
JOIN baseline_decisions b USING (tick_id)
WHERE sign(shadow_total_kw) != sign(baseline_total_kw);
```

把結果丟進 dashboard（見報告 03）做散點圖。

---

## 步驟 5：兩週後切換流量

當你準備好真實下發時：

1. 改 `.env` 的 `SHADOW_MODE=false`
2. **且** `safety_hardcoded.py` 內的 `ENABLE_REAL_DISPATCH` 同步改為 `True`（雙閘）
3. 重啟服務

雙閘設計是刻意的：單一環境變數太容易誤觸。

---

## 程式碼重點解說

### `orchestrator.py` 的循環
- 從 InfluxDB / MQTT 拉一個 5 分鐘窗口的 snapshot
- 並行 `asyncio.gather` 呼叫五個執行 Agent
- 整合為 `OrchProposal`
- 強制依序送 TWIN、GUARD
- 任一階段失敗即落地到 `shadow_decisions` 並 escalate

### `safety_hardcoded.py` 的角色
- GUARD prompt 是第一道，這檔是第二道，**不信任任何 LLM 輸出**
- 寫死的紅線：SOC < 5%、PCS > 100% 額定、ramp rate 超標、未知 action_type
- 任何一條觸發 → 整個 proposal 整批拒絕，不允許部分下發

### `shadow_log.py`
- 把每個 tick 的所有中間產物（snapshot、各 agent 回覆、TWIN 結果、GUARD 結果、最終決策）落地
- 用 JSONB 欄位存，方便日後 query

---

## 為什麼選 FastAPI 而不是純 Python script？

- 你已經是 FastAPI stack，不增加維運負擔
- 開 `/healthz` 與 `/metrics` 端點給 Prometheus，比 cron job 更可觀察
- 開 `/tick/manual` 端點讓 dashboard 可以手動觸發一次 tick 做演示
- 開 `/tick/{tick_id}` 端點讓你查任一歷史 tick 的所有中間狀態

---

## 下一步

1. 把 `fastapi_skeleton/` 整個 copy 到你的 monorepo
2. 填好 `.env`
3. `docker compose up`
4. 跑兩天，每天早上掃一次 log，確認沒有 prompt 設計上的明顯問題
5. 兩週後對接 dashboard（報告 03）開始正式評估
