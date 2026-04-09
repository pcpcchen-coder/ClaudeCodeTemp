"""EMS Agent Team — Shadow Mode FastAPI 入口

只負責 HTTP 與背景任務啟動，業務邏輯都在 orchestrator.py。
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
import asyncio

from settings import settings
from orchestrator import run_tick, get_tick_record, list_recent_ticks


_background_task: asyncio.Task | None = None


async def tick_loop():
    """背景循環：每 TICK_INTERVAL_SECONDS 跑一次 ORCH tick。"""
    while True:
        try:
            await run_tick()
        except Exception as exc:
            print(f"[loop] tick failed: {exc}")
        await asyncio.sleep(settings.tick_interval_seconds)


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _background_task
    _background_task = asyncio.create_task(tick_loop())
    print(f"[startup] shadow_mode={settings.shadow_mode} interval={settings.tick_interval_seconds}s")
    yield
    _background_task.cancel()


app = FastAPI(title="EMS Agent Team — Shadow", lifespan=lifespan)


@app.get("/healthz")
async def healthz():
    return {"status": "ok", "shadow_mode": settings.shadow_mode}


@app.post("/tick/manual")
async def manual_tick():
    """手動觸發一次 tick，給 dashboard 演示用。"""
    record = await run_tick()
    return record


@app.get("/tick/{tick_id}")
async def get_tick(tick_id: str):
    record = await get_tick_record(tick_id)
    if not record:
        raise HTTPException(404, "tick not found")
    return record


@app.get("/ticks/recent")
async def recent_ticks(limit: int = 20):
    return await list_recent_ticks(limit)
