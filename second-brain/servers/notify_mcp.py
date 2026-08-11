#!/usr/bin/env python3
"""MCP server for push notifications via ntfy.

One-way alerts to Identity B's phone. Free, no account needed on ntfy.sh —
install the ntfy app, subscribe to a topic, and publish to it.

Topic names on the public server are effectively public URLs: anyone who knows
the topic can read and publish. Use a long random topic name, or self-host, or
set NTFY_TOKEN with an access-controlled server.

Requires: mcp, httpx, pydantic
"""

import json
import os
from enum import Enum
from typing import Dict, Optional

import httpx
from mcp.server.fastmcp import FastMCP
from pydantic import BaseModel, ConfigDict, Field

mcp = FastMCP("notify_mcp")

NTFY_SERVER = os.environ.get("NTFY_SERVER", "https://ntfy.sh").rstrip("/")
NTFY_TOPIC = os.environ.get("NTFY_TOPIC", "")
NTFY_TOKEN = os.environ.get("NTFY_TOKEN", "")
REQUEST_TIMEOUT = 20.0


class Priority(str, Enum):
    """Notification priority, controlling how intrusively the phone alerts."""

    MIN = "min"
    LOW = "low"
    DEFAULT = "default"
    HIGH = "high"
    URGENT = "urgent"


class PushInput(BaseModel):
    """Input model for sending a push notification."""

    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    message: str = Field(
        ..., description="Notification body.", min_length=1, max_length=4000
    )
    title: Optional[str] = Field(
        default=None, description="Short headline shown above the body.", max_length=200
    )
    priority: Priority = Field(
        default=Priority.DEFAULT,
        description="'min'/'low' are silent, 'default' is a normal alert, "
        "'high'/'urgent' bypass Do Not Disturb. Reserve urgent for things "
        "genuinely worth waking someone for.",
    )
    tags: Optional[str] = Field(
        default=None,
        description="Comma-separated ntfy tags, rendered as emoji "
        "(e.g. 'warning,skull' or 'white_check_mark').",
    )
    topic: Optional[str] = Field(
        default=None, description="Override the topic. Defaults to NTFY_TOPIC."
    )


@mcp.tool(
    name="notify_push",
    annotations={
        "title": "Send Push Notification",
        "readOnlyHint": False,
        "destructiveHint": False,
        "idempotentHint": False,
        "openWorldHint": True,
    },
)
async def notify_push(params: PushInput) -> str:
    """Send a one-way push notification to Identity B's phone.

    Use this for alerts the user should see but need not reply to. It is not a
    conversation channel — the user cannot answer a push. If you need a reply,
    use telegram_send_message instead.

    Args:
        params (PushInput): Validated input containing:
            - message (str): Notification body, 1-4000 characters
            - title (Optional[str]): Short headline
            - priority (Priority): min | low | default | high | urgent
            - tags (Optional[str]): Comma-separated tags rendered as emoji
            - topic (Optional[str]): Override the default topic

    Returns:
        str: JSON on success:
        {"ok": true, "id": str, "topic": str, "priority": str}
        On failure: "Error: <actionable description>"

    Examples:
        - Use when: a long-running job finished and the user is away
        - Use when: a monitored condition tripped and needs attention
        - Don't use when: you are asking a question (use telegram_send_message)
        - Don't use when: the information can wait for the next session
    """
    topic = params.topic or NTFY_TOPIC
    if not topic:
        return (
            "Error: NTFY_TOPIC is not set and no topic was given. Pick a long "
            "random topic name, subscribe to it in the ntfy app, and add it to "
            "second-brain/.env."
        )

    headers: Dict[str, str] = {"Priority": params.priority.value}
    if params.title:
        headers["Title"] = params.title
    if params.tags:
        headers["Tags"] = params.tags
    if NTFY_TOKEN:
        headers["Authorization"] = f"Bearer {NTFY_TOKEN}"

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{NTFY_SERVER}/{topic}",
                content=params.message.encode("utf-8"),
                headers=headers,
                timeout=REQUEST_TIMEOUT,
            )
            response.raise_for_status()
            data = response.json()
    except httpx.HTTPStatusError as exc:
        status = exc.response.status_code
        if status in (401, 403):
            return (
                f"Error: ntfy denied the request ({status}). The topic is "
                f"access-controlled and NTFY_TOKEN is missing or wrong."
            )
        if status == 429:
            return "Error: ntfy rate limit hit (429). Wait before retrying."
        return f"Error: ntfy returned {status}."
    except httpx.TimeoutException:
        return f"Error: ntfy request to {NTFY_SERVER} timed out."
    except Exception as exc:  # noqa: BLE001 - converted to an agent-readable message
        return f"Error: unexpected {type(exc).__name__}: {exc}"

    return json.dumps(
        {
            "ok": True,
            "id": data.get("id"),
            "topic": data.get("topic", topic),
            "priority": params.priority.value,
        },
        indent=2,
    )


if __name__ == "__main__":
    mcp.run()
