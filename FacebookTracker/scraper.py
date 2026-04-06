"""Facebook Content Tracker - 抓取引擎（雙引擎支援）"""

import logging
import time
from abc import ABC, abstractmethod
from datetime import datetime, timezone

from models import AuthorConfig, Post, FetchResult

logger = logging.getLogger(__name__)


class ScraperBackend(ABC):
    """抓取引擎抽象基底類別"""

    @abstractmethod
    def fetch_posts(self, author: AuthorConfig, cookies: str = "") -> list[Post]:
        """抓取指定作者的貼文"""
        ...

    @abstractmethod
    def is_available(self) -> bool:
        """檢查此引擎是否可用（依賴已安裝）"""
        ...

    @property
    @abstractmethod
    def name(self) -> str:
        ...


class FacebookScraperBackend(ScraperBackend):
    """使用 facebook-scraper 套件的輕量引擎"""

    @property
    def name(self) -> str:
        return "facebook-scraper"

    def is_available(self) -> bool:
        try:
            import facebook_scraper  # noqa: F401
            return True
        except ImportError:
            return False

    def _extract_account(self, url: str) -> str:
        """從 URL 擷取帳號名稱或 ID"""
        url = url.rstrip("/")
        parts = url.split("/")
        return parts[-1] if parts else url

    def fetch_posts(self, author: AuthorConfig, cookies: str = "") -> list[Post]:
        from facebook_scraper import get_posts, set_cookies

        if cookies:
            set_cookies(cookies)

        account = self._extract_account(author.url)
        now = datetime.now(timezone.utc).isoformat()
        posts = []

        try:
            for raw in get_posts(account, pages=2, options={"allow_extra_requests": False}):
                if len(posts) >= author.max_posts:
                    break

                post_text = raw.get("post_text") or raw.get("text") or ""
                post_time = raw.get("time")
                timestamp = post_time.isoformat() if post_time else ""

                post = Post(
                    post_id=str(raw.get("post_id", "")),
                    author_name=author.name,
                    text=post_text,
                    timestamp=timestamp,
                    likes=raw.get("likes", 0) or 0,
                    comments=raw.get("comments", 0) or 0,
                    shares=raw.get("shares", 0) or 0,
                    images=raw.get("images", []) or [],
                    link=raw.get("post_url", ""),
                    fetched_at=now,
                )
                posts.append(post)

        except Exception as e:
            logger.warning("facebook-scraper 抓取 %s 失敗: %s", author.name, e)
            raise

        return posts


class PlaywrightBackend(ScraperBackend):
    """使用 Playwright 無頭瀏覽器的備援引擎"""

    @property
    def name(self) -> str:
        return "playwright"

    def is_available(self) -> bool:
        try:
            from playwright.sync_api import sync_playwright  # noqa: F401
            return True
        except ImportError:
            return False

    def _load_cookies(self, context, cookies_path: str):
        """從 JSON 檔案載入 cookies 到瀏覽器 context"""
        import json
        from pathlib import Path

        path = Path(cookies_path)
        if path.exists():
            with open(path, "r", encoding="utf-8") as f:
                cookies = json.load(f)
            context.add_cookies(cookies)
            logger.info("已載入 cookies: %s", cookies_path)

    def _parse_posts_from_page(self, page, author: AuthorConfig) -> list[Post]:
        """從頁面 HTML 解析貼文"""
        from bs4 import BeautifulSoup

        now = datetime.now(timezone.utc).isoformat()
        posts = []

        # 滾動頁面以載入更多貼文
        for _ in range(3):
            page.evaluate("window.scrollBy(0, window.innerHeight)")
            page.wait_for_timeout(2000)

        html = page.content()
        soup = BeautifulSoup(html, "html.parser")

        # Facebook 的貼文容器 class 經常變動，嘗試多種選擇器
        post_selectors = [
            'div[data-ad-preview="message"]',
            'div[data-testid="post_message"]',
            'div[class*="userContent"]',
            'div[dir="auto"]',
        ]

        seen_texts = set()
        for selector in post_selectors:
            elements = soup.select(selector)
            for el in elements:
                text = el.get_text(strip=True)
                if not text or len(text) < 20 or text in seen_texts:
                    continue
                seen_texts.add(text)

                if len(posts) >= author.max_posts:
                    break

                post = Post(
                    post_id=f"pw_{hash(text) & 0xFFFFFFFF:08x}",
                    author_name=author.name,
                    text=text,
                    fetched_at=now,
                )
                posts.append(post)

            if posts:
                break  # 找到有效選擇器，不再嘗試其他

        return posts

    def fetch_posts(self, author: AuthorConfig, cookies: str = "") -> list[Post]:
        from playwright.sync_api import sync_playwright

        try:
            with sync_playwright() as p:
                browser = p.chromium.launch(headless=True)
                context = browser.new_context(
                    user_agent=(
                        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                        "AppleWebKit/537.36 (KHTML, like Gecko) "
                        "Chrome/120.0.0.0 Safari/537.36"
                    ),
                    locale="zh-TW",
                )

                if cookies:
                    self._load_cookies(context, cookies)

                page = context.new_page()
                page.goto(author.url, wait_until="networkidle", timeout=30000)
                page.wait_for_timeout(3000)

                posts = self._parse_posts_from_page(page, author)

                browser.close()

        except Exception as e:
            logger.warning("Playwright 抓取 %s 失敗: %s", author.name, e)
            raise

        return posts


class Scraper:
    """抓取器門面 — 管理引擎選擇與 fallback"""

    def __init__(self, primary_backend: str = "facebook-scraper", cookies: str = ""):
        self.cookies = cookies
        self._backends: dict[str, ScraperBackend] = {}

        # 註冊可用引擎
        for backend_cls in [FacebookScraperBackend, PlaywrightBackend]:
            backend = backend_cls()
            if backend.is_available():
                self._backends[backend.name] = backend
                logger.info("引擎可用: %s", backend.name)
            else:
                logger.info("引擎不可用（未安裝）: %s", backend.name)

        # 決定引擎順序
        self._order: list[str] = []
        if primary_backend in self._backends:
            self._order.append(primary_backend)
        for name in self._backends:
            if name not in self._order:
                self._order.append(name)

        if not self._order:
            logger.error("沒有可用的抓取引擎！請安裝 facebook-scraper 或 playwright")

    def get_available_backends(self) -> list[str]:
        return list(self._order)

    def fetch(self, author: AuthorConfig) -> FetchResult:
        """抓取單一作者的貼文，自動 fallback"""
        if not self._order:
            return FetchResult(
                author=author,
                success=False,
                error_message="沒有可用的抓取引擎",
            )

        last_error = ""
        for backend_name in self._order:
            backend = self._backends[backend_name]
            try:
                logger.info("使用 %s 抓取 %s ...", backend_name, author.name)
                posts = backend.fetch_posts(author, self.cookies)
                logger.info("成功抓取 %s: %d 篇貼文", author.name, len(posts))
                return FetchResult(
                    author=author,
                    posts=posts,
                    success=True,
                    backend_used=backend_name,
                )
            except Exception as e:
                last_error = f"{backend_name}: {e}"
                logger.warning("引擎 %s 失敗，嘗試下一個: %s", backend_name, e)
                continue

        return FetchResult(
            author=author,
            success=False,
            error_message=f"所有引擎皆失敗。最後錯誤: {last_error}",
        )
