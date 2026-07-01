"""Logging configuration with optional structured JSON output."""

import logging
import sys

__all__ = ["get_logger", "setup_root_logger"]

_LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
_DATE_FORMAT = "%Y-%m-%d %H:%M:%S"


def setup_root_logger(
    *,
    name: str = "root",
    level: str = "INFO",
    json_format: bool = True,
) -> None:
    """Configure application logging.

    Args:
        name: Root logger name for the application.
        level: Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL).
        json_format: If True (default), output logs as JSON. Both structlog
            and standard-library loggers are rendered as JSON so that
            ``get_logger`` records are structured too.
    """
    handler = logging.StreamHandler(sys.stdout)
    formatter: logging.Formatter

    if json_format:
        import structlog

        # Shared processor chain: add level, logger name, and an ISO timestamp.
        shared_processors: list[structlog.typing.Processor] = [
            structlog.stdlib.add_log_level,
            structlog.stdlib.add_logger_name,
            structlog.processors.TimeStamper(fmt="iso"),
        ]

        structlog.configure(
            processors=[
                structlog.contextvars.merge_contextvars,
                *shared_processors,
                # Hand the event dict to ProcessorFormatter for final rendering.
                structlog.stdlib.ProcessorFormatter.wrap_for_formatter,
            ],
            wrapper_class=structlog.stdlib.BoundLogger,
            logger_factory=structlog.stdlib.LoggerFactory(),
        )

        # ProcessorFormatter renders BOTH structlog and stdlib records as JSON.
        # foreign_pre_chain runs on records from plain logging.getLogger loggers.
        formatter = structlog.stdlib.ProcessorFormatter(
            processor=structlog.processors.JSONRenderer(),
            foreign_pre_chain=shared_processors,
        )
    else:
        formatter = logging.Formatter(_LOG_FORMAT, datefmt=_DATE_FORMAT)

    handler.setFormatter(formatter)

    root_logger = logging.getLogger(name)
    root_logger.setLevel(getattr(logging, level.upper()))
    root_logger.addHandler(handler)

    logging.basicConfig(
        level=getattr(logging, level.upper()),
        handlers=[handler],
        force=True,
    )


def get_logger(name: str) -> logging.Logger:
    """Get a logger for a module.

    Args:
        name: Module name (typically __name__).

    Returns:
        Logger instance.
    """
    return logging.getLogger(name)
