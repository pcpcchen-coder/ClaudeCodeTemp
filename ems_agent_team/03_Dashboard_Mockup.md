# 報告 03 — Agent Team 即時監控 Dashboard

> 目標：給你一個可以放進 React 專案的 mockup component，顯示 ORCH 每個 tick 的決策狀態、各 Agent 的 health、TWIN 信心度、GUARD 否決率、以及最近 N 次的決策對比。

---

## 設計重點

| 區塊 | 顯示什麼 | 為什麼重要 |
|---|---|---|
| 頂部狀態列 | 影子模式 ON/OFF、最新 tick 時間、總 tick 數 | 一眼確認系統還活著 |
| Agent 矩陣 | 8 個 Agent 的即時健康狀態與本 tick 是否被諮詢 | 找出哪個 Agent 變慢或失敗 |
| TWIN 信心度趨勢 | 最近 50 個 tick 的 confidence 折線 | 看模型是否在某些情境下信心崩盤 |
| GUARD 否決熱區 | 最常觸發的紅線排行 | 快速定位 prompt 還是 schema 哪裡有問題 |
| 決策時間軸 | 最近 10 個 tick 的 status pill | 抓出連續異常的時段 |

---

## 步驟 1：放進你的 React 專案

```bash
# 假設你用 Vite + Tailwind
cp dashboard/AgentTeamDashboard.jsx src/components/
```

### 必要依賴

```bash
npm install recharts lucide-react
```

Tailwind 已預設可用（component 內用的是 Tailwind utility class）。

---

## 步驟 2：接 FastAPI 後端

component 預設會打 `/api/ticks/recent` 與 `/api/healthz`，對應到報告 02 的 FastAPI 端點。

如果你的 dev server 在不同 port，加 Vite proxy：

```js
// vite.config.js
export default {
  server: {
    proxy: {
      "/api": "http://localhost:8000",
    },
  },
}
```

---

## 步驟 3：嵌入頁面

```jsx
import AgentTeamDashboard from "./components/AgentTeamDashboard";

export default function App() {
  return <AgentTeamDashboard />;
}
```

---

## 步驟 4：自訂閾值

component 內有一個 `THRESHOLDS` 物件，調整這些值不需改 UI 邏輯：

```js
const THRESHOLDS = {
  twinConfidenceWarn: 0.75,
  twinConfidenceCrit: 0.6,
  rejectionRateWarn: 0.05,   // 5% 以上 GUARD 否決率變黃
  rejectionRateCrit: 0.15,
};
```

---

## 步驟 5：擴充建議

- **對比視圖**：拉一條時間軸，左邊放既有 EMS 的決策、右邊放 Agent 決策，標出方向相反的點
- **單 tick 追溯**：點任一 tick → 開 modal 顯示完整的 snapshot / 各 agent 回覆 / TWIN 結果 / GUARD 結果
- **告警 webhook**：當 GUARD 否決率連續 30 分鐘 > 15%，發 Slack 告警
- **電池熱圖**：把 20 個電池畫成 4×5 grid，顏色 = SOC，框線 = 健康分級

這些都可以在 mockup 之後迭代。

---

## 為什麼選 React + Recharts 而不是 Grafana？

| 工具 | 優點 | 缺點 |
|---|---|---|
| Grafana | 接 Influx 容易、模板多 | 對「Agent 推理過程」這種非時序資料不友善 |
| React + Recharts | 完全可客製、能塞 LLM 推理的 JSON 細節 | 需自己寫 |

你是 Python + 自家前端 stack，建議走 React 路線；Grafana 留給純電氣指標即可。

---

## 檔案位置

- 完整 component：`dashboard/AgentTeamDashboard.jsx`

直接 copy 進你的 `src/components/`，改幾個 API 路徑就能跑。
