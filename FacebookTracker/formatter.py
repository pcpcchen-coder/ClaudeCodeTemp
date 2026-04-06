"""Facebook Content Tracker - Markdown 輸出產生器"""

from datetime import datetime, timezone
from pathlib import Path

from models import AuthorConfig, Post, FetchResult


def _format_number(n: int) -> str:
    """格式化數字（1200 → 1.2K）"""
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.1f}K"
    return str(n)


def _truncate(text: str, max_len: int = 2000) -> str:
    """截斷過長文字"""
    if len(text) <= max_len:
        return text
    return text[:max_len] + "...(截斷)"


def generate_author_markdown(result: FetchResult) -> str:
    """為單一作者產生 Markdown 內容"""
    author = result.author
    posts = result.posts
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    lines = []
    lines.append(f"# Facebook 追蹤 - {author.name}")
    lines.append(f"> 日期: {datetime.now().strftime('%Y-%m-%d')} | 抓取時間: {now} | 共 {len(posts)} 篇貼文")

    if result.backend_used:
        lines.append(f"> 使用引擎: {result.backend_used}")

    if not result.success:
        lines.append("")
        lines.append(f"**抓取失敗**: {result.error_message}")
        return "\n".join(lines) + "\n"

    if not posts:
        lines.append("")
        lines.append("*本次未抓取到任何貼文*")
        return "\n".join(lines) + "\n"

    for i, post in enumerate(posts, 1):
        lines.append("")
        lines.append("---")
        lines.append("")
        lines.append(f"### 貼文 {i}")

        if post.timestamp:
            lines.append(f"- **時間**: {post.timestamp}")

        lines.append(f"- **內容**:")
        lines.append("")
        # 貼文內容縮排為引用區塊
        for text_line in _truncate(post.text).split("\n"):
            lines.append(f"  > {text_line}")

        lines.append("")

        if post.likes or post.comments or post.shares:
            interactions = []
            if post.likes:
                interactions.append(f"👍 {_format_number(post.likes)}")
            if post.comments:
                interactions.append(f"💬 {_format_number(post.comments)}")
            if post.shares:
                interactions.append(f"🔄 {_format_number(post.shares)}")
            lines.append(f"- **互動**: {' | '.join(interactions)}")

        if post.images:
            lines.append(f"- **圖片**: {len(post.images)} 張")

        if post.link:
            lines.append(f"- **連結**: {post.link}")

    lines.append("")
    return "\n".join(lines) + "\n"


def generate_daily_summary(results: list[FetchResult]) -> str:
    """產生當日所有作者的彙總 Markdown"""
    now = datetime.now()
    date_str = now.strftime("%Y-%m-%d")

    lines = []
    lines.append(f"# Facebook 每日追蹤彙總")
    lines.append(f"> 日期: {date_str}")
    lines.append("")

    total_posts = sum(len(r.posts) for r in results)
    success_count = sum(1 for r in results if r.success)
    fail_count = sum(1 for r in results if not r.success)

    lines.append("## 統計")
    lines.append(f"- 追蹤作者數: {len(results)}")
    lines.append(f"- 成功抓取: {success_count}")
    lines.append(f"- 失敗: {fail_count}")
    lines.append(f"- 總貼文數: {total_posts}")
    lines.append("")

    # 作者摘要表格
    lines.append("## 作者摘要")
    lines.append("")
    lines.append("| 作者 | 狀態 | 貼文數 | 引擎 |")
    lines.append("|------|------|--------|------|")
    for r in results:
        status = "✅" if r.success else "❌"
        count = len(r.posts) if r.success else "-"
        engine = r.backend_used or "-"
        lines.append(f"| {r.author.name} | {status} | {count} | {engine} |")

    lines.append("")

    # 每位作者的最新貼文預覽
    for r in results:
        if not r.posts:
            continue

        lines.append(f"## {r.author.name}")
        lines.append("")

        for i, post in enumerate(r.posts[:3], 1):  # 彙總只顯示前 3 篇
            preview = _truncate(post.text, 200)
            lines.append(f"{i}. {preview}")
            if post.link:
                lines.append(f"   [{post.link}]({post.link})")
            lines.append("")

        if len(r.posts) > 3:
            lines.append(f"   *...還有 {len(r.posts) - 3} 篇，詳見 {r.author.name}.md*")
            lines.append("")

    return "\n".join(lines) + "\n"


def save_results(results: list[FetchResult], output_dir: str):
    """儲存所有結果到指定目錄"""
    date_str = datetime.now().strftime("%Y-%m-%d")
    output_path = Path(output_dir) / date_str
    output_path.mkdir(parents=True, exist_ok=True)

    saved_files = []

    for result in results:
        md_content = generate_author_markdown(result)
        # 使用作者名稱作為檔名（移除不安全字元）
        safe_name = result.author.name.replace("/", "_").replace("\\", "_")
        file_path = output_path / f"{safe_name}.md"
        file_path.write_text(md_content, encoding="utf-8")
        saved_files.append(str(file_path))

    # 產生每日彙總
    summary_content = generate_daily_summary(results)
    summary_path = output_path / "daily_summary.md"
    summary_path.write_text(summary_content, encoding="utf-8")
    saved_files.append(str(summary_path))

    return saved_files
