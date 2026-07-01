"""Pytest fixtures for ai_ready_python_codebase tests."""

import pytest


@pytest.fixture
def settings() -> dict[str, str]:
    """Return test settings."""
    return {"log_level": "DEBUG"}
