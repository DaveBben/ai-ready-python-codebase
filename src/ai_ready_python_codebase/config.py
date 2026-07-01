"""Application configuration via environment variables."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables.

    Attributes:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL).
        log_json: If True (default), emit logs as JSON. Set LOG_JSON=false
            for human-readable console output during local development.
    """

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    log_level: str = "INFO"
    log_json: bool = True
