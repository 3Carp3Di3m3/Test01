#!/usr/bin/env python3
"""MCP server for SMS and voice calls via Twilio — Identity B's number.

Every tool here spends real money and reaches a real person. Both are
non-reversible once sent. The tools are deliberately NOT auto-approved in
.claude/settings.json, so each call prompts for permission.

Requires: mcp, httpx, pydantic
"""

import json
import os
from typing import Optional
from xml.sax.saxutils import escape

import httpx
from mcp.server.fastmcp import FastMCP
from pydantic import BaseModel, ConfigDict, Field, field_validator

mcp = FastMCP("twilio_mcp")

API_BASE_URL = "https://api.twilio.com/2010-04-01"
ACCOUNT_SID = os.environ.get("TWILIO_ACCOUNT_SID", "")
AUTH_TOKEN = os.environ.get("TWILIO_AUTH_TOKEN", "")
FROM_NUMBER = os.environ.get("TWILIO_FROM_NUMBER", "")
REQUEST_TIMEOUT = 30.0

E164 = r"^\+[1-9]\d{7,14}$"


class SendSmsInput(BaseModel):
    """Input model for sending an SMS."""

    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    to: str = Field(
        ...,
        description="Recipient in E.164 format, e.g. '+38641234567'.",
        pattern=E164,
    )
    body: str = Field(
        ...,
        description="Message text. Over 160 characters bills as multiple segments.",
        min_length=1,
        max_length=1600,
    )
    from_number: Optional[str] = Field(
        default=None,
        description="Sending number in E.164. Defaults to TWILIO_FROM_NUMBER.",
        pattern=E164,
    )


class MakeCallInput(BaseModel):
    """Input model for placing a voice call that speaks a message."""

    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    to: str = Field(
        ..., description="Recipient in E.164 format, e.g. '+38641234567'.", pattern=E164
    )
    say: str = Field(
        ...,
        description="Text spoken aloud when the call connects. Keep it short and "
        "front-load the important part — people hang up on robots.",
        min_length=1,
        max_length=1000,
    )
    voice_language: str = Field(
        default="en-US",
        description="BCP-47 language for text-to-speech, e.g. 'en-US', 'sl-SI', 'de-DE'.",
        max_length=10,
    )
    from_number: Optional[str] = Field(
        default=None,
        description="Calling number in E.164. Defaults to TWILIO_FROM_NUMBER.",
        pattern=E164,
    )

    @field_validator("say")
    @classmethod
    def reject_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("say cannot be blank")
        return value


def _check_credentials(from_number: Optional[str]) -> Optional[str]:
    """Return an error string if the server is not usable, else None."""
    if not ACCOUNT_SID or not AUTH_TOKEN:
        return (
            "Error: TWILIO_ACCOUNT_SID / TWILIO_AUTH_TOKEN are not set. Add them "
            "to second-brain/.env from your Twilio console."
        )
    if not (from_number or FROM_NUMBER):
        return (
            "Error: no sending number. Set TWILIO_FROM_NUMBER in "
            "second-brain/.env, or pass from_number explicitly."
        )
    return None


async def _post_twilio(resource: str, form: dict) -> dict:
    """POST to a Twilio REST resource for the configured account."""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{API_BASE_URL}/Accounts/{ACCOUNT_SID}/{resource}.json",
            data=form,
            auth=(ACCOUNT_SID, AUTH_TOKEN),
            timeout=REQUEST_TIMEOUT,
        )
        response.raise_for_status()
        return response.json()


def _handle_error(exc: Exception) -> str:
    """Turn an exception into something the agent can act on."""
    if isinstance(exc, httpx.HTTPStatusError):
        status = exc.response.status_code
        try:
            payload = exc.response.json()
            detail = payload.get("message", "")
            code = payload.get("code", "")
        except (ValueError, AttributeError):
            detail, code = "", ""
        if status == 401:
            return "Error: Twilio rejected the credentials (401). Check the SID and token."
        if status == 400:
            return (
                f"Error: Twilio rejected the request (400, code {code}): {detail}. "
                f"An unverified recipient on a trial account is the usual cause."
            )
        if status == 429:
            return "Error: Twilio rate limit hit (429). Wait before retrying."
        return f"Error: Twilio returned {status}: {detail}"
    if isinstance(exc, httpx.TimeoutException):
        return "Error: Twilio request timed out. The message may or may not have sent."
    return f"Error: unexpected {type(exc).__name__}: {exc}"


@mcp.tool(
    name="twilio_send_sms",
    annotations={
        "title": "Send SMS",
        "readOnlyHint": False,
        "destructiveHint": True,
        "idempotentHint": False,
        "openWorldHint": True,
    },
)
async def twilio_send_sms(params: SendSmsInput) -> str:
    """Send an SMS from Identity B's number. Costs money and cannot be recalled.

    Confirm the recipient and wording with the user before calling this, unless
    they have explicitly standing-authorised this exact recurring message.

    Args:
        params (SendSmsInput): Validated input containing:
            - to (str): Recipient in E.164 format
            - body (str): Message text, 1-1600 characters
            - from_number (Optional[str]): Override the sending number

    Returns:
        str: JSON on success:
        {"ok": true, "sid": str, "to": str, "status": str, "segments": str}
        On failure: "Error: <actionable description>"

    Examples:
        - Use when: the user explicitly asked you to text someone
        - Don't use when: Telegram or push would reach the same person for free
    """
    error = _check_credentials(params.from_number)
    if error:
        return error

    form = {
        "To": params.to,
        "From": params.from_number or FROM_NUMBER,
        "Body": params.body,
    }
    try:
        data = await _post_twilio("Messages", form)
    except Exception as exc:  # noqa: BLE001 - converted to an agent-readable message
        return _handle_error(exc)

    return json.dumps(
        {
            "ok": True,
            "sid": data.get("sid"),
            "to": data.get("to"),
            "status": data.get("status"),
            "segments": data.get("num_segments"),
        },
        indent=2,
    )


@mcp.tool(
    name="twilio_make_call",
    annotations={
        "title": "Place Voice Call",
        "readOnlyHint": False,
        "destructiveHint": True,
        "idempotentHint": False,
        "openWorldHint": True,
    },
)
async def twilio_make_call(params: MakeCallInput) -> str:
    """Place a voice call from Identity B's number that speaks a message aloud.

    The most intrusive tool available. Ringing someone's phone is a bigger
    interruption than any message — confirm before every use.

    Args:
        params (MakeCallInput): Validated input containing:
            - to (str): Recipient in E.164 format
            - say (str): Text spoken on connect, 1-1000 characters
            - voice_language (str): BCP-47 tag, e.g. 'en-US', 'sl-SI'
            - from_number (Optional[str]): Override the calling number

    Returns:
        str: JSON on success:
        {"ok": true, "sid": str, "to": str, "status": str}
        On failure: "Error: <actionable description>"

    Examples:
        - Use when: an urgent condition needs a human now and messages went unanswered
        - Don't use when: any quieter channel would do
    """
    error = _check_credentials(params.from_number)
    if error:
        return error

    # Escaped so an apostrophe or ampersand in the message cannot break the XML.
    twiml = (
        f'<Response><Say language="{escape(params.voice_language, {chr(34): "&quot;"})}">'
        f"{escape(params.say)}</Say></Response>"
    )
    form = {
        "To": params.to,
        "From": params.from_number or FROM_NUMBER,
        "Twiml": twiml,
    }
    try:
        data = await _post_twilio("Calls", form)
    except Exception as exc:  # noqa: BLE001 - converted to an agent-readable message
        return _handle_error(exc)

    return json.dumps(
        {
            "ok": True,
            "sid": data.get("sid"),
            "to": data.get("to"),
            "status": data.get("status"),
        },
        indent=2,
    )


if __name__ == "__main__":
    mcp.run()
