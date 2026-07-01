"""Custom exceptions for ai_ready_python_codebase."""


class AiReadyPythonCodebaseError(Exception):
    """Base exception for ai_ready_python_codebase errors."""


class ConfigurationError(AiReadyPythonCodebaseError):
    """Raised when configuration is invalid."""


class ServiceError(AiReadyPythonCodebaseError):
    """Raised when an external service call fails."""
