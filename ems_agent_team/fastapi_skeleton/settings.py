"""環境變數封裝。"""
import os
from dataclasses import dataclass


@dataclass
class Settings:
    anthropic_api_key: str = os.environ.get("ANTHROPIC_API_KEY", "")
    anthropic_model: str = os.environ.get("ANTHROPIC_MODEL", "claude-opus-4-6")
    mqtt_broker: str = os.environ.get("MQTT_BROKER", "")
    influx_url: str = os.environ.get("INFLUX_URL", "")
    shadow_db_url: str = os.environ.get("SHADOW_DB_URL", "postgresql://ems:ems@db:5432/shadow")
    shadow_mode: bool = os.environ.get("SHADOW_MODE", "true").lower() == "true"
    tick_interval_seconds: int = int(os.environ.get("TICK_INTERVAL_SECONDS", "300"))


settings = Settings()
