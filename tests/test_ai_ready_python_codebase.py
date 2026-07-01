"""Tests for ai_ready_python_codebase."""

from ai_ready_python_codebase.exceptions import (
    AiReadyPythonCodebaseError,
    ConfigurationError,
    ServiceError,
)


class TestExceptionHierarchy:
    """Tests for exception inheritance."""

    def test_configuration_error_inherits_from_base(self) -> None:
        assert issubclass(ConfigurationError, AiReadyPythonCodebaseError)

    def test_service_error_inherits_from_base(self) -> None:
        assert issubclass(ServiceError, AiReadyPythonCodebaseError)

    def test_base_error_inherits_from_exception(self) -> None:
        assert issubclass(AiReadyPythonCodebaseError, Exception)
