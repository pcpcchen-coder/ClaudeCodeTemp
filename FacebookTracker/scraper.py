"""Facebook Content Tracker - 抓取引擎（三引擎支援）"""

import json
import logging
import re
import time
from abc import ABC, abstractmethod
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urljoin

from models import AuthorConfig, Post, FetchResult

logger = logging.getLogger(__name__)

MBASIC_BASE = "https://mbasic.facebook.com"


def _extract_account(url: str) -> str:
    """從 Facebook URL 擷取帳號名稱或 ID"""
    url = url.rstrip("/")
    parts = url.split("/")
    return parts[-1] if parts else url


def _load_cookies_as_dict(cookies_path: str) -> dict[str, str]:
    """從 JSON 檔案載入 cookies 為 dict（給 requests 用）"""
    path = Path(cookies_path)
    if not path.exists():
        return {}
    with open(path, "r", encoding="utf-8") as f:
        cookies_list = json.load(f)
    # Playwright 格式: [{"name": "c_user", "value": "...", ...}, ...]
    if isinstance(cookies_list, list):
        return {c["name"]: c["value"] for c in cookies_list if "name" in c and "value" in c}
    # 已經是 dict 格式
    if isinstance(cookies_list, dict):
        return cookies_list
    return {}


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


class MbasicBackend(ScraperBackend):
    """使用 mbasic.facebook.com 的輕量引擎（推薦）

    mbasic.facebook.com 是 Facebook 的基本版行動網站，
    提供純靜態 HTML，不需要 JavaScript 渲染，DOM 結構簡單穩定。
    需要帶入 cookies 進行認證。
    """

    @property
    def name(self) -> str:
        return "mbasic"

    def is_available(self) -> bool:
        try:
            import requests  # noqa: F401
            from bs4 import BeautifulSoup  # noqa: F401
            return True
        except ImportError:
            return False

    # mbasic.facebook.com 設計給功能型手機，需要使用舊款/簡易 User-Agent
    # 現代 Chrome Mobile UA 會被封鎖（顯示「不支援的瀏覽器」攔截頁）
    MBASIC_USER_AGENTS = [
        # 舊版 Android WebView（最常見的通過方式）
        (
            "Mozilla/5.0 (Linux; U; Android 4.0.3; zh-tw; GT-I9100 Build/IML74K) "
            "AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30"
        ),
        # 功能型手機
        "Nokia5230/s60v5 (SymbianOS/9.4; U; Series60/5.0; Profile/MIDP-2.1 Configuration/CLDC-1.1)",
        # UCWEB（常見的功能手機瀏覽器）
        "UCWEB/2.0 (Linux; U; Opera Mini/7.1.32052/30.3697; en-US; SM-G900T) U2/1.0.0 UCBrowser/9.8.0.534 Mobile",
    ]

    def _build_session(self, cookies_path: str):
        """建立帶有 cookies 的 requests session"""
        import requests

        session = requests.Session()
        session.headers.update({
            "User-Agent": self.MBASIC_USER_AGENTS[0],
            "Accept-Language": "zh-TW,zh;q=0.9,en;q=0.8",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        })

        if cookies_path:
            cookie_dict = _load_cookies_as_dict(cookies_path)
            if cookie_dict:
                session.cookies.update(cookie_dict)
                logger.info("已載入 %d 個 cookies", len(cookie_dict))
            else:
                logger.warning("cookies 檔案為空或格式不正確: %s", cookies_path)

        return session

    def _find_post_containers(self, soup) -> list:
        """用多種策略找出貼文容器元素"""
        # 策略 1: div[data-ft] — mbasic 最常見的貼文容器
        containers = soup.find_all("div", attrs={"data-ft": True})
        if containers:
            logger.debug("選擇器命中: div[data-ft], 找到 %d 個", len(containers))
            return containers

        # 策略 2: <article> 標籤
        containers = soup.find_all("article")
        if containers:
            logger.debug("選擇器命中: <article>, 找到 %d 個", len(containers))
            return containers

        # 策略 3: 含 story/post 的 class
        containers = soup.find_all("div", {"class": re.compile(r"(story|post)", re.I)})
        if containers:
            logger.debug("選擇器命中: div.story/post, 找到 %d 個", len(containers))
            return containers

        # 策略 4: id 含 u_ 開頭的 div（mbasic 常見 ID 模式）
        containers = soup.find_all("div", id=re.compile(r"^u_\d+"))
        if containers:
            logger.debug("選擇器命中: div#u_*, 找到 %d 個", len(containers))
            return containers

        logger.debug("所有選擇器皆未命中")
        return []

    def _extract_post_text(self, container) -> str:
        """從貼文容器中提取文字內容"""
        # 優先用 <p> 標籤（mbasic 的貼文內容主要在 <p> 中）
        paragraphs = container.find_all("p")
        if paragraphs:
            parts = []
            for p in paragraphs:
                t = p.get_text(strip=True)
                if t:
                    parts.append(t)
            if parts:
                return "\n".join(parts)

        # 備用：找 dir="auto" 的 div/span（Facebook 常用於文字內容）
        auto_divs = container.find_all(["div", "span"], attrs={"dir": "auto"})
        if auto_divs:
            parts = []
            for d in auto_divs:
                t = d.get_text(strip=True)
                if t and len(t) > 5:
                    parts.append(t)
            if parts:
                return "\n".join(dict.fromkeys(parts))

        # 最終備用：取整個容器的文字
        return container.get_text(strip=True)

    def _parse_page(self, html: str, author: AuthorConfig, base_url: str) -> tuple[list[Post], str]:
        """解析 mbasic 頁面，回傳 (貼文列表, 下一頁URL)"""
        from bs4 import BeautifulSoup

        now = datetime.now(timezone.utc).isoformat()
        soup = BeautifulSoup(html, "html.parser")
        posts = []

        containers = self._find_post_containers(soup)

        # 過濾掉過小或嵌套的容器（data-ft 的 div 可能有巢狀關係）
        # 只保留最外層的貼文容器
        if containers:
            filtered = []
            for c in containers:
                # 檢查此容器是否是另一個容器的子元素
                is_nested = False
                for other in containers:
                    if other is not c and c in other.descendants:
                        is_nested = True
                        break
                if not is_nested:
                    filtered.append(c)
            containers = filtered
            logger.debug("過濾巢狀後剩餘 %d 個容器", len(containers))

        seen_texts = set()
        for container in containers:
            if len(posts) >= author.max_posts:
                break

            text = self._extract_post_text(container)

            if not text or len(text) < 10:
                continue

            # 去重
            text_key = text[:100]
            if text_key in seen_texts:
                continue
            seen_texts.add(text_key)

            # 時間戳：<abbr> 標籤
            timestamp = ""
            abbr = container.find("abbr")
            if abbr:
                timestamp = abbr.get_text(strip=True)

            # 貼文連結
            link = ""
            for a_tag in container.find_all("a", href=True):
                href = a_tag["href"]
                if any(kw in href for kw in ["/story.php", "/permalink", "/posts/", "photo.php"]):
                    link = urljoin(MBASIC_BASE, href)
                    break

            # 互動數：嘗試找 reaction 連結
            likes = 0
            for a_tag in container.find_all("a", href=True):
                if "reaction/profile" in a_tag.get("href", ""):
                    reaction_text = a_tag.get_text(strip=True)
                    nums = re.findall(r"[\d,]+", reaction_text)
                    if nums:
                        likes = int(nums[0].replace(",", ""))
                    break

            # post_id：從 data-ft 或連結提取
            post_id = ""
            data_ft = container.get("data-ft", "")
            if data_ft:
                try:
                    ft_data = json.loads(data_ft)
                    post_id = str(ft_data.get("top_level_post_id", ""))
                except (json.JSONDecodeError, TypeError):
                    pass
            if not post_id and link:
                id_match = re.search(r'(?:story_fbid=|/posts/|fbid=)(\d+)', link)
                if id_match:
                    post_id = id_match.group(1)
            if not post_id:
                post_id = f"mb_{hash(text) & 0xFFFFFFFF:08x}"

            post = Post(
                post_id=post_id,
                author_name=author.name,
                text=text,
                timestamp=timestamp,
                likes=likes,
                link=link,
                fetched_at=now,
            )
            posts.append(post)

        # 翻頁連結：找含 timestart= 的 <a>
        next_url = ""
        for a_tag in soup.find_all("a", href=True):
            href = a_tag["href"]
            if "timestart=" in href or "bacr=" in href:
                next_url = urljoin(MBASIC_BASE, href)
                logger.debug("找到翻頁連結: %s", next_url)
                break
        # 備用：文字匹配翻頁
        if not next_url:
            for a_tag in soup.find_all("a", href=True):
                link_text = a_tag.get_text(strip=True).lower()
                if any(kw in link_text for kw in [
                    "顯示更多", "更多帖子", "see more", "show more",
                    "查看更多", "更多動態", "older posts",
                ]):
                    next_url = urljoin(MBASIC_BASE, a_tag["href"])
                    break

        return posts, next_url

    def _is_blocked_page(self, html: str) -> bool:
        """偵測是否被 mbasic 攔截（不支援的瀏覽器頁面）"""
        return "unsupported-interstitial" in html or "無法在此瀏覽器上使用" in html

    def _fetch_with_ua_retry(self, session, url: str, account: str) -> str:
        """嘗試多個 User-Agent 來繞過 mbasic 的瀏覽器封鎖"""
        import requests

        for i, ua in enumerate(self.MBASIC_USER_AGENTS):
            session.headers["User-Agent"] = ua
            logger.debug("嘗試 UA #%d: %s...", i + 1, ua[:50])

            try:
                resp = session.get(url, timeout=15)
                resp.raise_for_status()
            except requests.RequestException as e:
                raise RuntimeError(f"無法存取 {url}: {e}")

            # 檢查登入狀態
            if "/login" in resp.url:
                raise RuntimeError(
                    "被導向登入頁面，cookies 可能已過期。"
                    "請重新執行: python facebook_tracker.py setup-cookies"
                )

            if not self._is_blocked_page(resp.text):
                if i > 0:
                    logger.info("UA #%d 成功通過 mbasic 檢查", i + 1)
                return resp.text

            logger.debug("UA #%d 被封鎖，嘗試下一個", i + 1)

        # 所有 UA 都被封鎖
        raise RuntimeError(
            "所有 User-Agent 皆被 mbasic.facebook.com 封鎖。"
            "Facebook 可能已更新封鎖策略。"
        )

    def fetch_posts(self, author: AuthorConfig, cookies: str = "") -> list[Post]:
        import requests

        if not cookies:
            raise RuntimeError(
                "mbasic 引擎需要 cookies 認證。"
                "請先執行: python facebook_tracker.py setup-cookies"
            )

        session = self._build_session(cookies)
        account = _extract_account(author.url)
        url = f"{MBASIC_BASE}/{account}"

        all_posts = []
        pages_fetched = 0
        max_pages = 3  # 最多翻 3 頁

        while url and pages_fetched < max_pages and len(all_posts) < author.max_posts:
            logger.info("抓取頁面: %s (第 %d 頁)", url, pages_fetched + 1)

            if pages_fetched == 0:
                # 第一頁：嘗試多個 UA
                html = self._fetch_with_ua_retry(session, url, account)
            else:
                # 後續頁面：用已成功的 UA
                try:
                    resp = session.get(url, timeout=15)
                    resp.raise_for_status()
                    html = resp.text
                except requests.RequestException as e:
                    logger.warning("翻頁失敗，停止: %s", e)
                    break

            # Debug: 儲存原始 HTML
            if logger.isEnabledFor(logging.DEBUG):
                debug_dir = Path("debug")
                debug_dir.mkdir(exist_ok=True)
                debug_file = debug_dir / f"{account}_page{pages_fetched}.html"
                debug_file.write_text(html, encoding="utf-8")
                logger.debug("已儲存 debug HTML: %s (%d bytes)", debug_file, len(html))

            posts, next_url = self._parse_page(html, author, url)
            all_posts.extend(posts)
            url = next_url
            pages_fetched += 1

            if next_url:
                time.sleep(1)  # 頁面間延遲

        return all_posts[:author.max_posts]


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

    def fetch_posts(self, author: AuthorConfig, cookies: str = "") -> list[Post]:
        from facebook_scraper import get_posts, set_cookies

        if cookies:
            set_cookies(cookies)

        account = _extract_account(author.url)
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

    def __init__(self, primary_backend: str = "mbasic", cookies: str = ""):
        self.cookies = cookies
        self._backends: dict[str, ScraperBackend] = {}

        # 註冊可用引擎（mbasic 優先）
        for backend_cls in [MbasicBackend, FacebookScraperBackend, PlaywrightBackend]:
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
