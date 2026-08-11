#!/usr/bin/env python3
"""PreToolUse hook enforcing the Identity A / Identity B boundary.

Claude Code sends the full tool call as JSON on stdin before the tool runs.
Exiting with code 2 blocks the call and shows stderr to the model as the reason.

This is the part of the isolation that does not depend on the model behaving.
Both identities share one claude.ai account, so Identity A's connectors are
present in the tool list whether or not this brain should touch them. This hook
is what makes "should not" into "cannot".

Config lives in .claude/isolation.json so the rules can be tuned without
editing this script.
"""

import fnmatch
import json
import os
import re
import sys
from pathlib import Path

BRAIN_ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = BRAIN_ROOT / ".claude" / "isolation.json"

DEFAULT_CONFIG = {
    # Tool-name globs belonging to Identity A. Matched case-insensitively.
    "blocked_tools": [
        "mcp__Gmail__*",
        "mcp__Google_Drive__*",
        "mcp__Google_Calendar__*",
        "mcp__Notion__*",
        "mcp__3DSVET_WordPress__*",
        "mcp__Semrush__*",
        "mcp__Interactive_Brokers__*",
    ],
    # Filesystem paths this brain must never touch, as globs.
    "blocked_paths": [
        "**/.env",
        "**/.env.*",
        "**/id_rsa*",
        "**/credentials.json",
    ],
    # If true, file tools may only touch paths inside the brain directory.
    "confine_to_brain_dir": True,
    # System locations Bash may reference despite the confinement rule —
    # interpreters, binaries and libraries, which are not identity data.
    "allowed_system_prefixes": [
        "/usr", "/bin", "/sbin", "/lib", "/lib64", "/opt", "/etc",
        "/proc", "/dev/null", "/var/tmp", "/tmp",
    ],
}

# Tools whose arguments name a file we should check.
FILE_TOOLS = {"Read", "Write", "Edit", "NotebookEdit"}
PATH_KEYS = ("file_path", "path", "notebook_path")

# Bash can read anything a file tool can, so its command string gets scanned
# for path-like tokens too. This is a lint, not a sandbox: a determined shell
# command can still evade it (variables, encoding, subshells). If you need a
# real boundary rather than a strong lock, deny Bash outright in
# .claude/settings.json, or run this brain as its own OS user.
PATH_TOKEN = re.compile(r"(?:^|[\s=:'\"(<>|;&])((?:~|\.\.|/)[^\s'\";|&)]*)")


def load_config() -> dict:
    config = dict(DEFAULT_CONFIG)
    try:
        with open(CONFIG_PATH, encoding="utf-8") as handle:
            config.update(json.load(handle))
    except FileNotFoundError:
        pass
    except (OSError, json.JSONDecodeError) as exc:
        # Fail closed on a broken config rather than silently running unguarded.
        block(f"isolation.json could not be read ({exc}). Refusing to run "
              f"unguarded — fix the config before continuing.")
    return config


def block(reason: str) -> None:
    """Block the tool call. stderr becomes the model's explanation."""
    print(f"BLOCKED by Identity B isolation guard: {reason}", file=sys.stderr)
    sys.exit(2)


def matches_any(value: str, patterns: list) -> bool:
    lowered = value.lower()
    return any(fnmatch.fnmatch(lowered, pattern.lower()) for pattern in patterns)


def check_tool_name(tool_name: str, config: dict) -> None:
    if matches_any(tool_name, config["blocked_tools"]):
        block(
            f"'{tool_name}' belongs to Identity A. This brain may only reach "
            f"Identity B's accounts, via the servers in this project's "
            f".mcp.json. Do not attempt to route around this."
        )


def candidate_paths(tool_name: str, tool_input: dict) -> list:
    if tool_name in FILE_TOOLS:
        return [str(tool_input[key]) for key in PATH_KEYS if tool_input.get(key)]
    if tool_name == "Bash":
        command = str(tool_input.get("command", ""))
        return PATH_TOKEN.findall(command)
    return []


def is_system_path(resolved: Path, config: dict) -> bool:
    """True for interpreters, binaries and libraries — not identity data."""
    text = str(resolved)
    return any(
        text == prefix or text.startswith(prefix.rstrip("/") + "/")
        for prefix in config.get("allowed_system_prefixes", [])
    )


def check_paths(tool_name: str, tool_input: dict, config: dict) -> None:
    for raw in candidate_paths(tool_name, tool_input):
        expanded = Path(os.path.expanduser(raw))
        if expanded.is_absolute():
            resolved = Path(os.path.normpath(expanded))
        else:
            resolved = Path(os.path.normpath(BRAIN_ROOT / expanded))

        if matches_any(str(resolved), config["blocked_paths"]):
            block(f"'{raw}' is a protected path (secrets or credentials).")

        if not config.get("confine_to_brain_dir"):
            continue
        if is_system_path(resolved, config):
            continue

        try:
            resolved.relative_to(BRAIN_ROOT)
        except ValueError:
            block(
                f"'{raw}' is outside the Identity B directory ({BRAIN_ROOT}). "
                f"Files belonging to Identity A — or to no identity — are out "
                f"of bounds for this brain."
            )


def main() -> None:
    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        # Malformed input means we cannot verify the call, so refuse it.
        block("hook received malformed JSON and cannot verify this tool call.")
        return

    config = load_config()
    tool_name = event.get("tool_name", "")
    tool_input = event.get("tool_input") or {}

    check_tool_name(tool_name, config)
    check_paths(tool_name, tool_input, config)

    sys.exit(0)


if __name__ == "__main__":
    main()
