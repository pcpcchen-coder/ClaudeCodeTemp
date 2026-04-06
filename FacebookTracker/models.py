"""Facebook Content Tracker - 資料模型定義"""

from dataclasses import dataclass, field
from typing import Optional


@dataclass
class AuthorConfig:
    """追蹤作者設定"""
    name: str
    url: str
    type: str = "page"          # "page" 或 "profile"
    enabled: bool = True
    max_posts: int = 10
    keywords: list[str] = field(default_factory=list)


@dataclass
class TrackerConfig:
    """追蹤器全域設定"""
    authors: list[AuthorConfig] = field(default_factory=list)
    output_dir: str = "output"
    scraper_backend: str = "facebook-scraper"  # "facebook-scraper" 或 "playwright"
    request_delay_s: float = 3.0
    facebook_cookies: str = ""  # cookies 檔案路徑，個人檔案需登入時使用


@dataclass
class Post:
    """單篇 Facebook 貼文"""
    post_id: str
    author_name: str
    text: str
    timestamp: str = ""         # ISO 8601
    likes: int = 0
    comments: int = 0
    shares: int = 0
    images: list[str] = field(default_factory=list)
    link: str = ""
    fetched_at: str = ""


@dataclass
class FetchResult:
    """單一作者的抓取結果"""
    author: AuthorConfig
    posts: list[Post] = field(default_factory=list)
    success: bool = True
    error_message: str = ""
    backend_used: str = ""
