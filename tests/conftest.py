"""Pytest fixtures for ai_ready_python_codebase tests.

Fixtures here return the *real* types the app uses, not stand-in dicts, so an
agent copying a pattern from a test can't drift away from the actual API.
"""

import pytest

from ai_ready_python_codebase.config import Settings


@pytest.fixture
def settings() -> Settings:
    """A Settings instance with test-friendly overrides.

    Returns the real Settings type (not a dict) with quiet, human-readable
    logging, so tests exercise the same object the application constructs.
    """
    return Settings(log_level="DEBUG", log_json=False)


@pytest.fixture
def env_settings(monkeypatch: pytest.MonkeyPatch) -> Settings:
    """Settings loaded from patched environment variables.

    Demonstrates the intended override path: set env vars, then let
    pydantic-settings read them — the same way the app does in production.
    """
    monkeypatch.setenv("LOG_LEVEL", "WARNING")
    monkeypatch.setenv("LOG_JSON", "false")
    return Settings()
