"""Pytest fixtures for the CDK tests."""

import aws_cdk as cdk
import pytest
from aws_cdk.assertions import Template

from ai_ready_python_codebase.hello_stack import HelloStack


@pytest.fixture
def template() -> Template:
    """Synthesize HelloStack and return its CloudFormation template for assertions.

    Synthesis runs in-process — no AWS credentials and no CDK CLI (though a local
    Node.js runtime is required, since CDK Python calls into jsii) — so these
    tests are a fast, hermetic verification oracle the agent can run on every edit.
    """
    app = cdk.App()
    stack = HelloStack(app, "TestStack")
    return Template.from_stack(stack)
