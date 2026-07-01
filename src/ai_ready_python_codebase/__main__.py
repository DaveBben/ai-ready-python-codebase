"""CLI entry point for ai-ready-python-codebase."""

import sys

from ai_ready_python_codebase.config import Settings
from ai_ready_python_codebase.logger import setup_root_logger


def main() -> int:
    """Run the application."""
    settings = Settings()
    setup_root_logger(level=settings.log_level, json_format=settings.log_json)

    # TODO: Implement your CLI logic here
    print("ai-ready-python-codebase v0.1.0")

    return 0


if __name__ == "__main__":
    sys.exit(main())
