import { useState, useEffect, useMemo } from "react";
import {
  LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer,
  BarChart, Bar, CartesianGrid,
} from "recharts";
import {
  Activity, Shield, Cpu, Battery, Zap, Users, Gauge, Eye, AlertTriangle, CheckCircle2,
} from "lucide-react";

const THRESHOLDS = {
  twinConfidenceWarn: 0.75,
  twinConfidenceCrit: 0.6,
  rejectionRateWarn: 0.05,
  rejectionRateCrit: 0.15,
};

const AGENTS = [
  { code: "ORCH", name: "Orchestrator", icon: Activity, layer: "command" },
  { code: "PRICE", name: "Pricing", icon: Zap, layer: "exec" },
  { code: "BATT", name: "Battery Health", icon: Battery, layer: "exec" },
  { code: "DISP", name: "PCS Dispatch", icon: Cpu, layer: "exec" },
  { code: "GRID", name: "Grid Interaction", icon: Gauge, layer: "exec" },
  { code: "APP", name: "User App", icon: Users, layer: "exec" },
  { code: "TWIN", name: "Digital Twin", icon: Eye, layer: "governance" },
  { code: "GUARD", name: "Safety/Compliance", icon: Shield, layer: "governance" },
];

// 用於沒接後端時的假資料
function makeFakeTicks(n = 50) {
  const out = [];
  const now = Date.now();
  for (let i = n - 1; i >= 0; i--) {
    const conf = 0.7 + Math.random() * 0.28;
    const status = Math.random() < 0.08 ? "rejected" : Math.random() < 0.05 ? "modified" : "approved";
    out.push({
      tick_id: `T-${(now - i * 300000).toString(36).slice(-6)}`,
      timestamp: new Date(now - i * 300000).toISOString(),
      state_class: ["normal", "normal", "normal", "congested", "abnormal"][Math.floor(Math.random() * 5)],
      twin_confidence: conf,
      guard_status: status,
      rejection_reason: status === "rejected" ? ["thermal_risk", "ramp_rate", "soc_lower_bound", "pcs_overload"][Math.floor(Math.random() * 4)] : null,
      action_count: Math.floor(Math.random() * 12) + 3,
      revenue_cny: Math.round((Math.random() * 200 - 50) * 10) / 10,
      consulted: ["PRICE", "BATT", "DISP", "GRID", "APP"].filter(() => Math.random() > 0.2),
    });
  }
  return out;
}

export default function AgentTeamDashboard() {
  const [ticks, setTicks] = useState(() => makeFakeTicks(50));
  const [shadowMode, setShadowMode] = useState(true);
  const [loading, setLoading] = useState(false);

  // 連線後端
  useEffect(() => {
    const fetchData = async () => {
      try {
        const [ticksRes, healthRes] = await Promise.all([
          fetch("/api/ticks/recent?limit=50"),
          fetch("/api/healthz"),
        ]);
        if (ticksRes.ok && healthRes.ok) {
          const t = await ticksRes.json();
          const h = await healthRes.json();
          if (Array.isArray(t) && t.length > 0) {
            setTicks(t.map(flattenTick));
            setShadowMode(h.shadow_mode);
          }
        }
      } catch {
        // 後端未連線時用假資料
      }
    };
    fetchData();
    const id = setInterval(fetchData, 10000);
    return () => clearInterval(id);
  }, []);

  const latest = ticks[ticks.length - 1];

  const stats = useMemo(() => {
    if (ticks.length === 0) return null;
    const rejected = ticks.filter(t => t.guard_status === "rejected").length;
    const avgConf = ticks.reduce((s, t) => s + (t.twin_confidence || 0), 0) / ticks.length;
    const totalRev = ticks.reduce((s, t) => s + (t.revenue_cny || 0), 0);
    return {
      rejectionRate: rejected / ticks.length,
      avgConfidence: avgConf,
      totalRevenue: totalRev,
      total: ticks.length,
    };
  }, [ticks]);

  const rejectionsByReason = useMemo(() => {
    const map = {};
    ticks.forEach(t => {
      if (t.rejection_reason) map[t.rejection_reason] = (map[t.rejection_reason] || 0) + 1;
    });
    return Object.entries(map).map(([reason, count]) => ({ reason, count })).sort((a, b) => b.count - a.count);
  }, [ticks]);

  const confidenceTrend = useMemo(
    () => ticks.map(t => ({ time: t.tick_id.slice(-4), confidence: t.twin_confidence })),
    [ticks]
  );

  const triggerManualTick = async () => {
    setLoading(true);
    try {
      await fetch("/api/tick/manual", { method: "POST" });
    } catch {
      // 後端未連線
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-stone-50 p-6 font-sans text-stone-800">
      <header className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-medium">EMS Agent Team Dashboard</h1>
          <p className="text-sm text-stone-500">Shadow mode monitor — 換電站 EMS 多 Agent 協作監控</p>
        </div>
        <div className="flex items-center gap-3">
          <span className={`rounded-md px-3 py-1.5 text-xs font-medium ${shadowMode ? "bg-amber-100 text-amber-800" : "bg-emerald-100 text-emerald-800"}`}>
            {shadowMode ? "影子模式 SHADOW" : "正式下發 LIVE"}
          </span>
          <button
            onClick={triggerManualTick}
            disabled={loading}
            className="rounded-md bg-stone-800 px-3 py-1.5 text-xs text-white hover:bg-stone-700 disabled:opacity-50"
          >
            {loading ? "執行中…" : "手動觸發 tick"}
          </button>
        </div>
      </header>

      {/* 統計卡片 */}
      <div className="mb-6 grid grid-cols-4 gap-4">
        <StatCard
          label="總 tick 數"
          value={stats?.total ?? 0}
          icon={<Activity className="h-4 w-4" />}
        />
        <StatCard
          label="GUARD 否決率"
          value={`${((stats?.rejectionRate ?? 0) * 100).toFixed(1)}%`}
          tone={stats?.rejectionRate > THRESHOLDS.rejectionRateCrit ? "crit" : stats?.rejectionRate > THRESHOLDS.rejectionRateWarn ? "warn" : "ok"}
          icon={<Shield className="h-4 w-4" />}
        />
        <StatCard
          label="TWIN 平均信心度"
          value={(stats?.avgConfidence ?? 0).toFixed(2)}
          tone={stats?.avgConfidence < THRESHOLDS.twinConfidenceCrit ? "crit" : stats?.avgConfidence < THRESHOLDS.twinConfidenceWarn ? "warn" : "ok"}
          icon={<Eye className="h-4 w-4" />}
        />
        <StatCard
          label="累計影子收益"
          value={`¥${(stats?.totalRevenue ?? 0).toFixed(0)}`}
          icon={<Zap className="h-4 w-4" />}
        />
      </div>

      {/* Agent 矩陣 */}
      <section className="mb-6 rounded-lg border border-stone-200 bg-white p-4">
        <h2 className="mb-3 text-base font-medium">Agent 矩陣</h2>
        <div className="grid grid-cols-4 gap-3">
          {AGENTS.map(a => {
            const Icon = a.icon;
            const consulted = latest?.consulted?.includes(a.code) || a.code === "ORCH" || a.code === "TWIN" || a.code === "GUARD";
            const tone = a.layer === "command" ? "purple" : a.layer === "governance" ? "amber" : "teal";
            return (
              <div
                key={a.code}
                className={`rounded-md border p-3 ${consulted ? "border-stone-300 bg-white" : "border-stone-200 bg-stone-50 opacity-60"}`}
              >
                <div className="flex items-center justify-between">
                  <Icon className={`h-4 w-4 text-${tone}-600`} />
                  <span className={`rounded px-1.5 py-0.5 text-[10px] ${consulted ? "bg-emerald-100 text-emerald-800" : "bg-stone-100 text-stone-500"}`}>
                    {consulted ? "active" : "idle"}
                  </span>
                </div>
                <div className="mt-2 text-sm font-medium">{a.code}</div>
                <div className="text-xs text-stone-500">{a.name}</div>
              </div>
            );
          })}
        </div>
      </section>

      <div className="mb-6 grid grid-cols-2 gap-4">
        {/* TWIN 信心度趨勢 */}
        <section className="rounded-lg border border-stone-200 bg-white p-4">
          <h2 className="mb-3 text-base font-medium">TWIN 信心度趨勢</h2>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={confidenceTrend}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e7e5e4" />
              <XAxis dataKey="time" stroke="#78716c" fontSize={11} />
              <YAxis domain={[0.5, 1]} stroke="#78716c" fontSize={11} />
              <Tooltip />
              <Line type="monotone" dataKey="confidence" stroke="#0f6e56" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </section>

        {/* GUARD 否決熱區 */}
        <section className="rounded-lg border border-stone-200 bg-white p-4">
          <h2 className="mb-3 text-base font-medium">GUARD 否決熱區</h2>
          {rejectionsByReason.length === 0 ? (
            <div className="flex h-[200px] items-center justify-center text-sm text-stone-400">
              <CheckCircle2 className="mr-2 h-4 w-4 text-emerald-500" />
              本期間無否決
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={rejectionsByReason} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#e7e5e4" />
                <XAxis type="number" stroke="#78716c" fontSize={11} />
                <YAxis dataKey="reason" type="category" stroke="#78716c" fontSize={11} width={120} />
                <Tooltip />
                <Bar dataKey="count" fill="#993c1d" />
              </BarChart>
            </ResponsiveContainer>
          )}
        </section>
      </div>

      {/* 決策時間軸 */}
      <section className="rounded-lg border border-stone-200 bg-white p-4">
        <h2 className="mb-3 text-base font-medium">最近決策時間軸</h2>
        <div className="space-y-2">
          {ticks.slice(-10).reverse().map(t => (
            <div key={t.tick_id} className="flex items-center justify-between rounded border border-stone-100 bg-stone-50 px-3 py-2 text-xs">
              <div className="flex items-center gap-3">
                <span className="font-mono text-stone-500">{t.tick_id}</span>
                <span className="text-stone-400">{new Date(t.timestamp).toLocaleTimeString()}</span>
                <StateBadge state={t.state_class} />
              </div>
              <div className="flex items-center gap-3">
                <span className="text-stone-500">{t.action_count} actions</span>
                <span className="text-stone-500">conf {t.twin_confidence?.toFixed(2)}</span>
                <span className="text-stone-500">¥{t.revenue_cny}</span>
                <GuardBadge status={t.guard_status} reason={t.rejection_reason} />
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}

function StatCard({ label, value, icon, tone = "ok" }) {
  const toneClass = {
    ok: "text-stone-800",
    warn: "text-amber-700",
    crit: "text-red-700",
  }[tone];
  return (
    <div className="rounded-lg border border-stone-200 bg-white p-4">
      <div className="flex items-center justify-between text-stone-500">
        <span className="text-xs">{label}</span>
        {icon}
      </div>
      <div className={`mt-2 text-2xl font-medium ${toneClass}`}>{value}</div>
    </div>
  );
}

function StateBadge({ state }) {
  const colorMap = {
    normal: "bg-emerald-100 text-emerald-800",
    congested: "bg-amber-100 text-amber-800",
    abnormal: "bg-orange-100 text-orange-800",
    emergency: "bg-red-100 text-red-800",
    unknown: "bg-stone-100 text-stone-600",
  };
  return <span className={`rounded px-1.5 py-0.5 text-[10px] ${colorMap[state] || colorMap.unknown}`}>{state}</span>;
}

function GuardBadge({ status, reason }) {
  if (status === "approved") return <span className="rounded bg-emerald-100 px-1.5 py-0.5 text-[10px] text-emerald-800">approved</span>;
  if (status === "modified") return <span className="rounded bg-amber-100 px-1.5 py-0.5 text-[10px] text-amber-800">modified</span>;
  return (
    <span className="flex items-center gap-1 rounded bg-red-100 px-1.5 py-0.5 text-[10px] text-red-800">
      <AlertTriangle className="h-3 w-3" />
      {reason || "rejected"}
    </span>
  );
}

function flattenTick(record) {
  const p = record.proposal || {};
  const t = record.twin_result || {};
  const g = record.guard_verdict || {};
  return {
    tick_id: record.tick_id,
    timestamp: p.timestamp,
    state_class: p.state_class,
    twin_confidence: t.confidence,
    guard_status: g.status,
    rejection_reason: g.rejection_reason,
    action_count: (p.actions || []).length,
    revenue_cny: p.estimated_revenue_cny || 0,
    consulted: p.consulted_agents || [],
  };
}
