#!/usr/bin/env python3
"""MCP server for Telegram — Identity B's primary chat interface.

Uses the Telegram Bot API with a bot token belonging to Identity B only.
Create the bot by messaging @BotFather; get your chat id by messaging the bot
once and calling telegram_get_messages.

Requires: mcp, httpx, pydantic
"""

import json
import os
from enum import Enum
from typing import Any, Dict, List, Optional

import httpx
from mcp.server.fastmcp import FastMCP
from pydantic import BaseModel, ConfigDict, Field

mcp = FastMCP("telegram_mcp")

API_BASE_URL = "https://api.telegram.org"
BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")
DEFAULT_CHAT_ID = os.environ.get("TELEGRAM_CHAT_ID", "")
REQUEST_TIMEOUT = 30.0


class ParseMode(str, Enum):
    """Telegram text formatting mode."""

    PLAIN = "plain"
    MARKDOWN = "MarkdownV2"
    HTML = "HTML"


class SendMessageInput(BaseModel):
    """Input model for sending a Telegram message."""

    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    text: str = Field(
        ...,
        description="Message body. Telegram hard-limits this to 4096 characters.",
        min_length=1,
        max_length=4096,
    )
    chat_id: Optional[str] = Field(
        default=None,
        description="Target chat id (e.g. '123456789'). Defaults to TELEGRAM_CHAT_ID.",
    )
    parse_mode: ParseMode = Field(
        default=ParseMode.PLAIN,
        description="'plain' for literal text, 'HTML' or 'MarkdownV2' for formatting. "
        "Use plain unless you need formatting — MarkdownV2 requires escaping "
        "many characters and fails the whole send if you get it wrong.",
    )
    silent: bool = Field(
        default=False,
        description="Deliver without a notification sound. Use for low-priority updates.",
    )


class GetMessagesInput(BaseModel):
    """Input model for reading recent messages sent to the bot."""

    model_config = ConfigDict(extra="forbid")

    limit: int = Field(
        default=20, description="Maximum messages to return.", ge=1, le=100
    )
    offset_update_id: Optional[int] = Field(
        default=None,
        description="Return only updates with an id greater than this. Pass the "
        "'next_offset' from a previous call to page forward and avoid re-reading.",
    )


def _require_token() -> Optional[str]:
    if not BOT_TOKEN:
        return (
            "Error: TELEGRAM_BOT_TOKEN is not set. Create a bot with @BotFather "
            "on Telegram, then add the token to second-brain/.env."
        )
    return None


async def _call_api(method: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    """Call one Telegram Bot API method."""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{API_BASE_URL}/bot{BOT_TOKEN}/{method}",
            json=payload,
            timeout=REQUEST_TIMEOUT,
        )
        response.raise_for_status()
        return response.json()


def _handle_error(exc: Exception) -> str:
    """Turn an exception into something the agent can act on."""
    if isinstance(exc, httpx.HTTPStatusError):
        status = exc.response.status_code
        try:
            detail = exc.response.json().get("description", "")
        except (ValueError, AttributeError):
            detail = ""
        if status == 401:
            return (
                "Error: Telegram rejected the bot token (401). Check "
                "TELEGRAM_BOT_TOKEN in second-brain/.env."
            )
        if status == 400:
            return (
                f"Error: Telegram rejected the request (400): {detail}. A bad "
                f"chat_id or malformed MarkdownV2 escaping is the usual cause."
            )
        if status == 429:
            return "Error: Telegram rate limit hit (429). Wait before retrying."
        return f"Error: Telegram API returned {status}: {detail}"
    if isinstance(exc, httpx.TimeoutException):
        return "Error: Telegram request timed out. Try again."
    return f"Error: unexpected {type(exc).__name__}: {exc}"


@mcp.tool(
    name="telegram_send_message",
    annotations={
        "title": "Send Telegram Message",
        "readOnlyHint": False,
        "destructiveHint": False,
        "idempotentHint": False,
        "openWorldHint": True,
    },
)
async def telegram_send_message(params: SendMessageInput) -> str:
    """Send a message to Identity B's Telegram chat.

    This is the primary way to reach the user on their phone. The message is
    delivered immediately and cannot be recalled, so confirm before sending
    anything addressed to a third party.

    Args:
        params (SendMessageInput): Validated input containing:
            - text (str): Message body, 1-4096 characters
            - chat_id (Optional[str]): Target chat, defaults to TELEGRAM_CHAT_ID
            - parse_mode (ParseMode): 'plain', 'HTML', or 'MarkdownV2'
            - silent (bool): Suppress the notification sound

    Returns:
        str: JSON with the delivered message, on success:
        {"ok": true, "message_id": int, "chat_id": int, "sent_text": str}
        On failure: "Error: <actionable description>"

    Examples:
        - Use when: reporting a finished job to the user on their phone
        - Use when: asking the user a question while they are away from a desk
        - Don't use when: the user only needs a passive alert (use notify_push)
    """
    token_error = _require_token()
    if token_error:
        return token_error

    chat_id = params.chat_id or DEFAULT_CHAT_ID
    if not chat_id:
        return (
            "Error: no chat_id given and TELEGRAM_CHAT_ID is not set. Message "
            "your bot once from Telegram, then call telegram_get_messages to "
            "find your chat id."
        )

    payload: Dict[str, Any] = {
        "chat_id": chat_id,
        "text": params.text,
        "disable_notification": params.silent,
    }
    if params.parse_mode is not ParseMode.PLAIN:
        payload["parse_mode"] = params.parse_mode.value

    try:
        data = await _call_api("sendMessage", payload)
    except Exception as exc:  # noqa: BLE001 - converted to an agent-readable message
        return _handle_error(exc)

    result = data.get("result", {})
    return json.dumps(
        {
            "ok": True,
            "message_id": result.get("message_id"),
            "chat_id": result.get("chat", {}).get("id"),
            "sent_text": params.text,
        },
        indent=2,
    )


@mcp.tool(
    name="telegram_get_messages",
    annotations={
        "title": "Read Recent Telegram Messages",
        "readOnlyHint": True,
        "destructiveHint": False,
        "idempotentHint": True,
        "openWorldHint": True,
    },
)
async def telegram_get_messages(params: GetMessagesInput) -> str:
    """Read recent messages sent to Identity B's bot.

    Also the way to discover your own chat id during setup: message the bot
    from Telegram, then call this with no arguments and read 'chat_id' off the
    first result.

    Note: Telegram only retains undelivered updates for about 24 hours, and
    reading them with an offset marks earlier ones as delivered. This is a
    recent-activity feed, not a searchable archive.

    Args:
        params (GetMessagesInput): Validated input containing:
            - limit (int): Maximum messages to return, 1-100 (default 20)
            - offset_update_id (Optional[int]): Only updates newer than this id

    Returns:
        str: JSON with the following schema:
        {
            "count": int,
            "next_offset": int | null,   # pass back as offset_update_id
            "messages": [
                {
                    "update_id": int,
                    "message_id": int,
                    "chat_id": int,
                    "from": str,          # sender display name
                    "date": int,          # unix timestamp
                    "text": str
                }
            ]
        }
        On failure: "Error: <actionable description>"

    Examples:
        - Use when: finding your chat id during first-time setup
        - Use when: checking whether the user replied to a question you sent
        - Don't use when: you need history older than ~24 hours
    """
    token_error = _require_token()
    if token_error:
        return token_error

    payload: Dict[str, Any] = {"limit": params.limit}
    if params.offset_update_id is not None:
        payload["offset"] = params.offset_update_id + 1

    try:
        data = await _call_api("getUpdates", payload)
    except Exception as exc:  # noqa: BLE001 - converted to an agent-readable message
        return _handle_error(exc)

    updates: List[Dict[str, Any]] = data.get("result", [])
    messages = []
    for update in updates:
        message = update.get("message") or update.get("channel_post")
        if not message:
            continue
        sender = message.get("from", {})
        name = " ".join(
            part
            for part in (sender.get("first_name"), sender.get("last_name"))
            if part
        )
        messages.append(
            {
                "update_id": update.get("update_id"),
                "message_id": message.get("message_id"),
                "chat_id": message.get("chat", {}).get("id"),
                "from": name or sender.get("username") or "unknown",
                "date": message.get("date"),
                "text": message.get("text", ""),
            }
        )

    if not messages:
        return json.dumps(
            {
                "count": 0,
                "next_offset": None,
                "messages": [],
                "hint": "No pending messages. Send one to the bot from Telegram "
                "and call this again.",
            },
            indent=2,
        )

    return json.dumps(
        {
            "count": len(messages),
            "next_offset": messages[-1]["update_id"],
            "messages": messages,
        },
        indent=2,
    )


if __name__ == "__main__":
    mcp.run()
