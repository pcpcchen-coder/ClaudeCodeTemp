"""影子決策落地。

正式版用 SQLAlchemy + Postgres JSONB；本骨架先用 in-memory dict 讓你跑通。
"""
import asyncio
from collections import OrderedDict


_lock = asyncio.Lock()
_store: "OrderedDict[str, dict]" = OrderedDict()
_MAX = 1000


async def save_decision(record: dict) -> None:
    async with _lock:
        _store[record["tick_id"]] = record
        while len(_store) > _MAX:
            _store.popitem(last=False)


async def fetch_decision(tick_id: str) -> dict | None:
    async with _lock:
        return _store.get(tick_id)


async def fetch_recent(limit: int = 20) -> list[dict]:
    async with _lock:
        items = list(_store.values())[-limit:]
        return list(reversed(items))


# ---------------- Postgres 版本（取消註解後改用） ----------------
#
# import asyncpg, json
# from settings import settings
#
# _pool: asyncpg.Pool | None = None
#
# async def _ensure_pool():
#     global _pool
#     if _pool is None:
#         _pool = await asyncpg.create_pool(settings.shadow_db_url)
#         async with _pool.acquire() as con:
#             await con.execute("""
#                 CREATE TABLE IF NOT EXISTS shadow_decisions (
#                     tick_id TEXT PRIMARY KEY,
#                     created_at TIMESTAMPTZ DEFAULT now(),
#                     state_class TEXT,
#                     guard_status TEXT,
#                     twin_confidence DOUBLE PRECISION,
#                     estimated_revenue_cny DOUBLE PRECISION,
#                     actions JSONB,
#                     full_record JSONB
#                 );
#             """)
#
# async def save_decision(record: dict) -> None:
#     await _ensure_pool()
#     async with _pool.acquire() as con:
#         await con.execute(
#             "INSERT INTO shadow_decisions(tick_id, state_class, guard_status, "
#             "twin_confidence, estimated_revenue_cny, actions, full_record) "
#             "VALUES($1,$2,$3,$4,$5,$6,$7) ON CONFLICT (tick_id) DO NOTHING",
#             record["tick_id"],
#             record["proposal"].get("state_class"),
#             record["guard_verdict"].get("status"),
#             record["twin_result"].get("confidence"),
#             record["proposal"].get("estimated_revenue_cny"),
#             json.dumps(record["proposal"].get("actions", [])),
#             json.dumps(record),
#         )
