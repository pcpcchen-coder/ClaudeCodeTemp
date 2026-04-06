#!/usr/bin/env python3
"""
Facebook Content Tracker - 每日追蹤 Facebook 作者貼文

用法：
    python facebook_tracker.py setup-cookies       # 首次使用：取得 Facebook cookies
    python facebook_tracker.py run                 # 執行完整抓取
    python facebook_tracker.py run --author "黃仁勳" # 只抓特定作者
    python facebook_tracker.py list                # 顯示已設定的作者
    python facebook_tracker.py test --url URL      # 測試單一 URL
"""

import argparse
import json
import logging
import sys
import time
from pathlib import Path

import yaml

from models import AuthorConfig, TrackerConfig
from scraper import Scraper
from formatter import save_results

logger = logging.getLogger("facebook_tracker")

CONFIG_FILE = "config.yaml"


def load_config(config_path: str = CONFIG_FILE) -> TrackerConfig:
    """從 YAML 載入設定"""
    path = Path(config_path)
    if not path.exists():
        print(f"錯誤: 找不到設定檔 '{config_path}'")
        print(f"請在 FacebookTracker/ 目錄下建立 {CONFIG_FILE}")
        sys.exit(1)

    with open(path, "r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)

    authors = []
    for a in raw.get("authors", []):
        authors.append(AuthorConfig(
            name=a["name"],
            url=a["url"],
            type=a.get("type", "page"),
            enabled=a.get("enabled", True),
            max_posts=a.get("max_posts", 10),
            keywords=a.get("keywords", []),
        ))

    return TrackerConfig(
        authors=authors,
        output_dir=raw.get("output_dir", "output"),
        scraper_backend=raw.get("scraper_backend", "facebook-scraper"),
        request_delay_s=raw.get("request_delay_s", 3.0),
        facebook_cookies=raw.get("facebook_cookies", ""),
    )


def cmd_setup_cookies(config: TrackerConfig, output_path: str = "cookies.json"):
    """互動式取得 Facebook cookies"""
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("錯誤: 需要 Playwright 來取得 cookies")
        print("請安裝: pip install playwright && playwright install chromium")
        sys.exit(1)

    print("=" * 60)
    print("Facebook Cookies 設定工具")
    print("=" * 60)
    print()
    print("即將開啟瀏覽器視窗，請在瀏覽器中登入 Facebook。")
    print("登入成功後，程式會自動儲存 cookies。")
    print()

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        context = browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/120.0.0.0 Safari/537.36"
            ),
            locale="zh-TW",
        )
        page = context.new_page()
        page.goto("https://www.facebook.com/", wait_until="networkidle")

        print("等待登入中... (請在瀏覽器中完成登入)")
        print("提示：登入後程式會自動偵測並儲存 cookies")
        print()

        # 輪詢等待登入成功（檢查 c_user cookie）
        max_wait = 300  # 最多等 5 分鐘
        waited = 0
        while waited < max_wait:
            cookies = context.cookies()
            c_user = [c for c in cookies if c["name"] == "c_user"]
            if c_user:
                print("偵測到登入成功！")
                break
            time.sleep(2)
            waited += 2
            if waited % 30 == 0:
                print(f"  仍在等待登入... ({waited}s)")

        if waited >= max_wait:
            print("逾時：未偵測到登入。請重新執行。")
            browser.close()
            sys.exit(1)

        # 儲存 cookies
        all_cookies = context.cookies()
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(all_cookies, f, indent=2, ensure_ascii=False)

        browser.close()

    # 顯示結果
    cookie_names = [c["name"] for c in all_cookies]
    has_essential = "c_user" in cookie_names and "xs" in cookie_names

    print()
    print(f"已儲存 {len(all_cookies)} 個 cookies 到: {output_path}")
    if has_essential:
        print("✅ 關鍵 cookies (c_user, xs) 已取得")
    else:
        print("⚠️  未找到關鍵 cookies，抓取可能受限")

    print()
    print("下一步：")
    print(f"1. 確認 config.yaml 中 facebook_cookies 設為 \"{output_path}\"")
    print("2. 執行 python facebook_tracker.py run 開始抓取")


def cmd_list(config: TrackerConfig):
    """顯示已設定的作者清單"""
    print("已設定的追蹤作者：")
    print(f"{'狀態':<6} {'名稱':<30} {'類型':<10} {'URL'}")
    print("-" * 90)
    for a in config.authors:
        status = "✅" if a.enabled else "⏸️"
        print(f"{status:<6} {a.name:<30} {a.type:<10} {a.url}")
        if a.keywords:
            print(f"       關鍵字: {', '.join(a.keywords)}")
    print(f"\n共 {len(config.authors)} 位作者，"
          f"{sum(1 for a in config.authors if a.enabled)} 位啟用")


def cmd_run(config: TrackerConfig, author_filter: str = ""):
    """執行抓取"""
    authors = [a for a in config.authors if a.enabled]

    if author_filter:
        authors = [a for a in authors if author_filter in a.name]
        if not authors:
            print(f"找不到符合 '{author_filter}' 的作者")
            sys.exit(1)

    if not authors:
        print("沒有啟用的作者，請檢查 config.yaml")
        sys.exit(1)

    print(f"開始抓取 {len(authors)} 位作者的貼文...")
    print(f"抓取引擎: {config.scraper_backend}")
    print()

    scraper = Scraper(
        primary_backend=config.scraper_backend,
        cookies=config.facebook_cookies,
    )

    backends = scraper.get_available_backends()
    if not backends:
        print("錯誤: 沒有可用的抓取引擎")
        print("請安裝: pip install facebook-scraper")
        print("或安裝: pip install playwright && playwright install chromium")
        sys.exit(1)

    print(f"可用引擎: {', '.join(backends)}")
    print()

    results = []
    for i, author in enumerate(authors):
        print(f"[{i + 1}/{len(authors)}] 抓取 {author.name}...")

        result = scraper.fetch(author)
        results.append(result)

        if result.success:
            post_count = len(result.posts)
            print(f"  ✅ 成功: {post_count} 篇貼文 (引擎: {result.backend_used})")

            # 套用關鍵字過濾
            if author.keywords:
                before = len(result.posts)
                result.posts = [
                    p for p in result.posts
                    if not author.keywords or any(
                        kw.lower() in p.text.lower() for kw in author.keywords
                    )
                ]
                filtered = before - len(result.posts)
                if filtered:
                    print(f"  📋 關鍵字過濾: 保留 {len(result.posts)}/{before} 篇")
        else:
            print(f"  ❌ 失敗: {result.error_message}")

        # 作者之間的延遲
        if i < len(authors) - 1:
            time.sleep(config.request_delay_s)

    # 儲存結果
    print()
    saved = save_results(results, config.output_dir)
    print(f"已儲存 {len(saved)} 個檔案:")
    for f in saved:
        print(f"  📄 {f}")

    # 摘要
    print()
    total_posts = sum(len(r.posts) for r in results)
    success = sum(1 for r in results if r.success)
    print(f"完成！成功 {success}/{len(results)} 位作者，共 {total_posts} 篇貼文")


def cmd_test(config: TrackerConfig, url: str):
    """測試單一 URL 的抓取"""
    test_author = AuthorConfig(name="測試", url=url, max_posts=3)

    print(f"測試抓取: {url}")
    print()

    scraper = Scraper(
        primary_backend=config.scraper_backend,
        cookies=config.facebook_cookies,
    )

    result = scraper.fetch(test_author)

    if result.success:
        print(f"✅ 成功! 引擎: {result.backend_used}, 貼文數: {len(result.posts)}")
        print()
        for i, post in enumerate(result.posts, 1):
            preview = post.text[:200] + "..." if len(post.text) > 200 else post.text
            print(f"--- 貼文 {i} ---")
            print(f"時間: {post.timestamp}")
            print(f"內容: {preview}")
            print(f"互動: 👍{post.likes} 💬{post.comments} 🔄{post.shares}")
            print()
    else:
        print(f"❌ 失敗: {result.error_message}")


def main():
    parser = argparse.ArgumentParser(
        description="Facebook Content Tracker - 追蹤 Facebook 作者貼文",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--config", default=CONFIG_FILE,
        help=f"設定檔路徑 (預設: {CONFIG_FILE})",
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true",
        help="顯示詳細日誌",
    )

    subparsers = parser.add_subparsers(dest="command", help="子指令")

    # setup-cookies
    cookies_parser = subparsers.add_parser("setup-cookies", help="互動式取得 Facebook cookies")
    cookies_parser.add_argument(
        "--output", default="cookies.json",
        help="cookies 儲存路徑 (預設: cookies.json)",
    )

    # run
    run_parser = subparsers.add_parser("run", help="執行抓取")
    run_parser.add_argument("--author", default="", help="只抓取特定作者（名稱關鍵字）")
    run_parser.add_argument("--debug", action="store_true", help="儲存原始 HTML 到 debug/ 以便除錯")

    # list
    subparsers.add_parser("list", help="顯示已設定的作者")

    # test
    test_parser = subparsers.add_parser("test", help="測試單一 URL")
    test_parser.add_argument("--url", required=True, help="要測試的 Facebook URL")

    args = parser.parse_args()

    # 設定 logging
    debug_mode = args.verbose or getattr(args, "debug", False)
    log_level = logging.DEBUG if debug_mode else logging.WARNING
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
        datefmt="%H:%M:%S",
    )

    if not args.command:
        parser.print_help()
        sys.exit(0)

    config = load_config(args.config)

    if args.command == "setup-cookies":
        cmd_setup_cookies(config, args.output)
    elif args.command == "list":
        cmd_list(config)
    elif args.command == "run":
        cmd_run(config, args.author)
    elif args.command == "test":
        cmd_test(config, args.url)


if __name__ == "__main__":
    main()
