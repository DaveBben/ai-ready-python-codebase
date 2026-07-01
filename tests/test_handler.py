"""Unit test for the Lambda handler itself (independent of CDK synthesis)."""

import pytest

from ai_ready_python_codebase.lambdas.hello import index


def test_handler_prints_and_returns_hello_world(
    capsys: pytest.CaptureFixture[str],
) -> None:
    result = index.handler({}, object())

    assert result == {"message": "Hello World"}
    assert "Hello World" in capsys.readouterr().out
