#!/usr/bin/env python3
"""MCP server for Identity B's mailbox over IMAP/SMTP.

Deliberately not the Gmail OAuth connector: that one is bound to Identity A at
the claude.ai account level. An app password scoped to Identity B's mailbox
keeps the two sets of credentials genuinely separate.

For Gmail, generate an app password at https://myaccount.google.com/apppasswords
(requires 2-Step Verification). Works with any IMAP provider, not just Gmail.

Requires: mcp, pydantic
"""

import asyncio
import email
import email.utils
import imaplib
import json
import os
import smtplib
from email.header import decode_header, make_header
from email.message import EmailMessage
from enum import Enum
from typing import Any, Dict, List, Optional

from mcp.server.fastmcp import FastMCP
from pydantic import BaseModel, ConfigDict, Field

mcp = FastMCP("mailbox_mcp")

IMAP_HOST = os.environ.get("MAILBOX_IMAP_HOST", "imap.gmail.com")
SMTP_HOST = os.environ.get("MAILBOX_SMTP_HOST", "smtp.gmail.com")
ADDRESS = os.environ.get("MAILBOX_ADDRESS", "")
APP_PASSWORD = os.environ.get("MAILBOX_APP_PASSWORD", "")
SMTP_PORT = 465
BODY_PREVIEW_CHARS = 2000


class SearchScope(str, Enum):
    """Which messages to search."""

    ALL = "ALL"
    UNSEEN = "UNSEEN"
    RECENT = "RECENT"


class SearchInput(BaseModel):
    """Input model for searching the mailbox."""

    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    query: Optional[str] = Field(
        default=None,
        description="Free text matched against subject, sender and body. "
        "Omit to list the most recent messages in scope.",
        max_length=200,
    )
    scope: SearchScope = Field(
        default=SearchScope.ALL,
        description="'ALL' for everything, 'UNSEEN' for unread only, 'RECENT' "
        "for messages that arrived this session.",
    )
    folder: str = Field(default="INBOX", description="IMAP folder to search.")
    limit: int = Field(
        default=15, description="Maximum messages to return, newest first.", ge=1, le=50
    )


class ReadInput(BaseModel):
    """Input model for reading one message in full."""

    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    uid: str = Field(..., description="Message uid from mailbox_search.", min_length=1)
    folder: str = Field(default="INBOX", description="Folder containing the message.")
    mark_read: bool = Field(
        default=False,
        description="Mark the message as read. Defaults to false so reading is "
        "non-destructive — the user's unread state stays as they left it.",
    )


class SendInput(BaseModel):
    """Input model for sending mail from Identity B's address."""

    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    to: str = Field(..., description="Recipient address, or several comma-separated.")
    subject: str = Field(..., description="Subject line.", min_length=1, max_length=300)
    body: str = Field(..., description="Plain-text body.", min_length=1)
    cc: Optional[str] = Field(default=None, description="Comma-separated cc addresses.")
    reply_to_message_id: Optional[str] = Field(
        default=None,
        description="RFC Message-ID being replied to, so the reply threads "
        "correctly. Take it from mailbox_read's 'message_id'.",
    )


def _check_credentials() -> Optional[str]:
    if not ADDRESS or not APP_PASSWORD:
        return (
            "Error: MAILBOX_ADDRESS / MAILBOX_APP_PASSWORD are not set. Add "
            "Identity B's address and an app password to second-brain/.env."
        )
    return None


def _decode(raw: Optional[str]) -> str:
    """Decode an RFC 2047 encoded header into plain text."""
    if not raw:
        return ""
    try:
        return str(make_header(decode_header(raw)))
    except (UnicodeDecodeError, LookupError, ValueError):
        return raw


def _plain_body(message: email.message.Message) -> str:
    """Extract the plain-text body, ignoring attachments and HTML alternatives."""
    if not message.is_multipart():
        payload = message.get_payload(decode=True) or b""
        return payload.decode(message.get_content_charset() or "utf-8", "replace")

    for part in message.walk():
        if part.get_content_type() != "text/plain":
            continue
        if "attachment" in str(part.get("Content-Disposition", "")):
            continue
        payload = part.get_payload(decode=True) or b""
        return payload.decode(part.get_content_charset() or "utf-8", "replace")
    return ""


def _summarise(message: email.message.Message, uid: str) -> Dict[str, Any]:
    """Header-level summary of a message, cheap enough to list in bulk."""
    return {
        "uid": uid,
        "from": _decode(message.get("From")),
        "to": _decode(message.get("To")),
        "subject": _decode(message.get("Subject")),
        "date": _decode(message.get("Date")),
        "message_id": message.get("Message-ID", ""),
    }


def _imap_search(params: SearchInput) -> Dict[str, Any]:
    """Blocking IMAP search. Called via asyncio.to_thread."""
    with imaplib.IMAP4_SSL(IMAP_HOST) as imap:
        imap.login(ADDRESS, APP_PASSWORD)
        imap.select(params.folder, readonly=True)

        criteria: List[str] = [params.scope.value]
        if params.query:
            criteria = [params.scope.value, "TEXT", params.query]

        status, data = imap.uid("search", None, *criteria)
        if status != "OK":
            raise RuntimeError(f"IMAP search failed in folder '{params.folder}'")

        uids = data[0].split()
        selected = uids[-params.limit :][::-1]  # newest first

        messages = []
        for uid in selected:
            status, fetched = imap.uid("fetch", uid, "(BODY.PEEK[HEADER])")
            if status != "OK" or not fetched or not isinstance(fetched[0], tuple):
                continue
            parsed = email.message_from_bytes(fetched[0][1])
            messages.append(_summarise(parsed, uid.decode()))

        return {"total_matched": len(uids), "count": len(messages), "messages": messages}


def _imap_read(params: ReadInput) -> Dict[str, Any]:
    """Blocking IMAP fetch of one full message. Called via asyncio.to_thread."""
    with imaplib.IMAP4_SSL(IMAP_HOST) as imap:
        imap.login(ADDRESS, APP_PASSWORD)
        imap.select(params.folder, readonly=not params.mark_read)

        fetch_command = "(RFC822)" if params.mark_read else "(BODY.PEEK[])"
        status, fetched = imap.uid("fetch", params.uid, fetch_command)
        if status != "OK" or not fetched or not isinstance(fetched[0], tuple):
            raise LookupError(f"No message with uid '{params.uid}' in {params.folder}")

        parsed = email.message_from_bytes(fetched[0][1])
        body = _plain_body(parsed)
        result = _summarise(parsed, params.uid)
        result["body"] = body[:BODY_PREVIEW_CHARS]
        result["body_truncated"] = len(body) > BODY_PREVIEW_CHARS
        return result


def _smtp_send(params: SendInput) -> Dict[str, Any]:
    """Blocking SMTP send. Called via asyncio.to_thread."""
    message = EmailMessage()
    message["From"] = ADDRESS
    message["To"] = params.to
    message["Subject"] = params.subject
    message["Message-ID"] = email.utils.make_msgid()
    if params.cc:
        message["Cc"] = params.cc
    if params.reply_to_message_id:
        message["In-Reply-To"] = params.reply_to_message_id
        message["References"] = params.reply_to_message_id
    message.set_content(params.body)

    with smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT) as smtp:
        smtp.login(ADDRESS, APP_PASSWORD)
        smtp.send_message(message)

    return {
        "ok": True,
        "from": ADDRESS,
        "to": params.to,
        "subject": params.subject,
        "message_id": message["Message-ID"],
    }


def _handle_error(exc: Exception) -> str:
    """Turn an exception into something the agent can act on."""
    if isinstance(exc, imaplib.IMAP4.error):
        return (
            f"Error: IMAP rejected the request ({exc}). If this is an "
            f"authentication failure, the app password is wrong or IMAP access "
            f"is disabled for this mailbox."
        )
    if isinstance(exc, smtplib.SMTPAuthenticationError):
        return (
            "Error: SMTP authentication failed. Regenerate the app password — "
            "a normal account password will not work with 2-Step Verification."
        )
    if isinstance(exc, smtplib.SMTPException):
        return f"Error: sending failed ({type(exc).__name__}: {exc})."
    if isinstance(exc, LookupError):
        return f"Error: {exc}"
    if isinstance(exc, OSError):
        return f"Error: could not reach the mail server ({exc})."
    return f"Error: unexpected {type(exc).__name__}: {exc}"


@mcp.tool(
    name="mailbox_search",
    annotations={
        "title": "Search Identity B Mailbox",
        "readOnlyHint": True,
        "destructiveHint": False,
        "idempotentHint": True,
        "openWorldHint": True,
    },
)
async def mailbox_search(params: SearchInput) -> str:
    """Search Identity B's mailbox and return message headers, newest first.

    Returns headers only, not bodies, so it stays cheap on large mailboxes.
    Follow up with mailbox_read on the uid you want.

    Args:
        params (SearchInput): Validated input containing:
            - query (Optional[str]): Free text over subject, sender and body
            - scope (SearchScope): ALL | UNSEEN | RECENT
            - folder (str): IMAP folder, default 'INBOX'
            - limit (int): Maximum results, 1-50 (default 15)

    Returns:
        str: JSON with the following schema:
        {
            "total_matched": int,   # matches before the limit was applied
            "count": int,
            "messages": [
                {"uid": str, "from": str, "to": str, "subject": str,
                 "date": str, "message_id": str}
            ]
        }
        On failure: "Error: <actionable description>"

    Examples:
        - Use when: "anything unread from the supplier?" -> query + scope=UNSEEN
        - Don't use when: you already have a uid (use mailbox_read)
    """
    error = _check_credentials()
    if error:
        return error
    try:
        result = await asyncio.to_thread(_imap_search, params)
    except Exception as exc:  # noqa: BLE001 - converted to an agent-readable message
        return _handle_error(exc)

    if not result["messages"]:
        return json.dumps(
            {**result, "hint": f"No messages matched in '{params.folder}'."}, indent=2
        )
    return json.dumps(result, indent=2)


@mcp.tool(
    name="mailbox_read",
    annotations={
        "title": "Read One Message",
        "readOnlyHint": True,
        "destructiveHint": False,
        "idempotentHint": True,
        "openWorldHint": True,
    },
)
async def mailbox_read(params: ReadInput) -> str:
    """Read one message from Identity B's mailbox in full.

    Leaves the message unread by default, so inspecting the inbox does not
    disturb what the user still has to look at.

    Args:
        params (ReadInput): Validated input containing:
            - uid (str): Message uid from mailbox_search
            - folder (str): Folder containing the message, default 'INBOX'
            - mark_read (bool): Mark as read, default false

    Returns:
        str: JSON with the following schema:
        {
            "uid": str, "from": str, "to": str, "subject": str, "date": str,
            "message_id": str,      # pass to mailbox_send as reply_to_message_id
            "body": str,            # plain text, truncated at 2000 characters
            "body_truncated": bool
        }
        On failure: "Error: <actionable description>"

    Examples:
        - Use when: you need the content behind a search result
        - Don't use when: the subject line already answered the question
    """
    error = _check_credentials()
    if error:
        return error
    try:
        result = await asyncio.to_thread(_imap_read, params)
    except Exception as exc:  # noqa: BLE001 - converted to an agent-readable message
        return _handle_error(exc)
    return json.dumps(result, indent=2)


@mcp.tool(
    name="mailbox_send",
    annotations={
        "title": "Send Mail As Identity B",
        "readOnlyHint": False,
        "destructiveHint": True,
        "idempotentHint": False,
        "openWorldHint": True,
    },
)
async def mailbox_send(params: SendInput) -> str:
    """Send an email from Identity B's address. Cannot be recalled.

    Show the user the full draft and get explicit approval before calling this,
    unless they have standing-authorised this specific recurring message.

    Args:
        params (SendInput): Validated input containing:
            - to (str): Recipient address, or comma-separated addresses
            - subject (str): Subject line
            - body (str): Plain-text body
            - cc (Optional[str]): Comma-separated cc addresses
            - reply_to_message_id (Optional[str]): Message-ID for threading

    Returns:
        str: JSON on success:
        {"ok": true, "from": str, "to": str, "subject": str, "message_id": str}
        On failure: "Error: <actionable description>"

    Examples:
        - Use when: the user approved a draft you wrote
        - Don't use when: you have not shown the user the exact text
    """
    error = _check_credentials()
    if error:
        return error
    try:
        result = await asyncio.to_thread(_smtp_send, params)
    except Exception as exc:  # noqa: BLE001 - converted to an agent-readable message
        return _handle_error(exc)
    return json.dumps(result, indent=2)


if __name__ == "__main__":
    mcp.run()
