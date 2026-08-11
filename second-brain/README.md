# Second Brain — Identity B

A second Claude Code "brain" with its own identity, its own credentials, and a
hard-enforced boundary against Identity A (3dsvet.eu and its accounts).

**This is not a web app and not an artifact.** It's a Claude Code project
directory. Claude Code *is* the runtime; Telegram is the user interface. There
is no server to write and no frontend to maintain.

---

## Why it's built this way

Your Gmail, Notion, Calendar and Drive are OAuth connectors installed on your
**claude.ai account** — one authenticated identity each. There is no "add a
second account" on a built-in connector, so Identity B's accounts cannot be
reached through them.

Instead, Identity B reaches its own accounts through **project-scoped MCP
servers defined in this directory**, authenticated with credentials that only
exist in this directory's `.env`.

### The boundary, and its honest limits

Both brains run under one claude.ai account, so the separation is enforced by
configuration, in three layers:

1. **`.mcp.json`** — defines only Identity B's servers.
2. **`.claude/settings.json`** — denies Identity A's connectors by permission.
3. **`.claude/hooks/isolation_guard.py`** — a `PreToolUse` hook that inspects
   every tool call before it runs and exits with code 2 to block it. This is the
   layer that actually holds, because it doesn't depend on the model choosing to
   behave.

The guard blocks Identity A's connector tools, file access outside this
directory, secrets files, and `Bash` commands that reference paths outside the
brain. Verified against all of those cases.

**What this is not:** a security sandbox. A determined shell command can still
evade a string-matching hook, and anyone with access to your machine can edit
the config. If you ever need a guarantee rather than a strong lock — a real
client, a legal boundary, someone else's data — the answer is a **second
claude.ai account**, or running this brain as its own OS user. Ask and I'll set
that up instead.

---

## Setup

### 1. Install dependencies

```bash
cd second-brain
python3 -m venv .venv && source .venv/bin/activate
pip install "mcp[cli]" httpx pydantic
```

### 2. Credentials

```bash
cp .env.example .env
```

Fill in `.env` following the comments in it. **Start with Telegram only** — get
one channel working end to end before adding the rest. Every other block can
stay blank; those servers will just report that they're unconfigured.

### 3. Telegram, end to end

1. Message [@BotFather](https://t.me/BotFather), send `/newbot`, follow prompts.
2. Put the token in `.env` as `TELEGRAM_BOT_TOKEN`.
3. Send your new bot any message from Telegram.
4. Start Claude Code in this directory and ask it to run `telegram_get_messages`.
5. Copy the `chat_id` from the result into `.env` as `TELEGRAM_CHAT_ID`.
6. Ask it to send you a test message. If it arrives on your phone, you're done.

### 4. Fill in the identity files

`identity/SOUL.md`, `IDENTITY.md` and `USER.md` are templates with `TODO`
markers. The fastest way to fill them is to let the brain interview you:

> "Ask me whatever you need to fill in the three identity files accurately,
> then write them."

### 5. Run it

```bash
cd second-brain
claude
```

Claude Code picks up `CLAUDE.md`, `.mcp.json` and `.claude/settings.json` from
the working directory. **Always start it from inside `second-brain/`** — the
isolation config is scoped to this directory and does not apply if you launch
from the parent.

---

## What's wired up

| Server | Status | Tools |
|---|---|---|
| `telegram` | Ready | `telegram_send_message`, `telegram_get_messages` |
| `notify` | Ready | `notify_push` |
| `twilio` | Ready | `twilio_send_sms`, `twilio_make_call` |
| `mailbox_b` | Ready | `mailbox_search`, `mailbox_read`, `mailbox_send` |
| `notion_b` | Ready | official `@notionhq/notion-mcp-server` via npx |
| `wordpress_b` | **Not wired** | see below |

### Adding WordPress B

Your 3dsvet site uses a WordPress MCP adapter plugin. For site B, install the
same plugin on that site, generate an application password for Identity B's WP
user, then add to `.mcp.json`:

```json
"wordpress_b": {
  "type": "http",
  "url": "https://SITE-B.example/wp-json/mcp/v1",
  "headers": { "Authorization": "Basic ${WORDPRESS_B_BASIC_AUTH}" }
}
```

The exact URL and auth header depend on the plugin version — check its settings
page. Tell me the plugin and I'll wire it properly.

### Note on `twilio`

Deliberately **not** in the `allow` list in `.claude/settings.json`, so every
SMS and call prompts for permission. That's intentional: those tools spend money
and reach real people. Don't allowlist them.

---

## Moving to a VPS

Everything above runs locally. Move it to an always-on server once you actually
want the brain reacting without your laptop open — a scheduled inbox sweep, or
replying to Telegram while you're out.

What changes:

- Clone this directory to the VPS (it's self-contained), recreate `.env` there
  by hand — never copy secrets through git.
- Install Claude Code on the VPS and authenticate.
- Add scheduling: cron for periodic runs, or a long-running process polling
  `telegram_get_messages` for reactive behaviour.
- Set `confine_to_brain_dir` in `.claude/isolation.json` — on a dedicated VPS
  you may also want a dedicated OS user, which gives you the hard boundary the
  hook can only approximate.

A 5–10 EUR/month VPS is enough. Don't do this until step 3 works locally.

---

## Layout

```
second-brain/
├── CLAUDE.md                    identity + boundary rules, read every session
├── .mcp.json                    Identity B's MCP servers
├── .env.example                 credential template (copy to .env)
├── identity/
│   ├── SOUL.md                  how it behaves
│   ├── IDENTITY.md              what it is and owns
│   └── USER.md                  who it works for
├── memory/                      log.md + facts.md (gitignored)
├── servers/
│   ├── telegram_mcp.py
│   ├── notify_mcp.py
│   ├── twilio_mcp.py
│   └── mailbox_mcp.py
└── .claude/
    ├── settings.json            hook registration + permissions
    ├── isolation.json           boundary rules, tunable
    └── hooks/isolation_guard.py the enforcement
```

---

## Testing the boundary

The guard is worth re-checking whenever you edit `isolation.json`:

```bash
echo '{"tool_name":"mcp__Gmail__get_message","tool_input":{}}' \
  | python3 .claude/hooks/isolation_guard.py; echo "exit=$?"   # expect exit=2

echo '{"tool_name":"mcp__telegram__telegram_send_message","tool_input":{}}' \
  | python3 .claude/hooks/isolation_guard.py; echo "exit=$?"   # expect exit=0
```

Exit 2 means blocked, exit 0 means allowed.
