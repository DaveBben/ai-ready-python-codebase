"""Hello World Lambda handler.

Runs inside the AWS Lambda Python runtime and is bundled as a deployment asset,
so it stays self-contained and dependency-free (it must not import the rest of the
package, which isn't shipped in the Lambda zip). `print` goes to CloudWatch Logs.
"""


def handler(event: dict[str, object], context: object) -> dict[str, object]:
    """Log a greeting and return it.

    Args:
        event: The invocation event (unused for this demo).
        context: The Lambda runtime context (unused for this demo).

    Returns:
        A small response payload echoing the greeting.
    """
    print("Hello World")
    return {"message": "Hello World"}
