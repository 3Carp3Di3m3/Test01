# Handoff — start here

This project was designed and scaffolded in a Claude Code web session. The
remaining work happens **on your own machine**, because it needs real
credentials and those should never be typed into a remote container.

## Before you start

1. **Pull the branch** — `claude/custom-ai-research-o6wxvg` on `3Carp3Di3m3/Test01`.
2. **Lift this directory out.** `second-brain/` only lives inside a Flutter app
   repo because the web session's push access was scoped there. Move it to its
   own **private** repo. It is self-contained, and the isolation config is
   directory-scoped, so nothing breaks in the move.
3. **Open the `second-brain/` directory in VS Code** with the Claude Code
   extension, and start `claude` **from inside that directory** — the
   project-scoped MCP servers, permissions and isolation hook only load when it
   is the working directory.

## Then paste this prompt

---

You are the private-life second brain described in `CLAUDE.md`. Read that file,
then `PLAN.md`, then the three files in `identity/`.

Context you need:

- I am Danijel. I run 3dsvet.eu as my business, with a separate Claude setup
  and its own connectors — that is "Identity A". You are Identity B and you
  handle my **private life** only. The two must not mix.
- Your remit is four areas: personal admin, parenting and school support for my
  son (who is starting high school), personal projects, and planning/memory.
- **No specific job has been built yet, deliberately.** We are building the
  foundation. Do not invent Notion databases, skills or automations until I
  have picked a first real job.
- You are an **advisor**: read, analyse and draft, but send, publish and post
  nothing without my explicit approval of the exact content. Notifying me on my
  own phone is always fine.
- The scaffold is already written and tested. Do not rebuild it. The MCP
  servers in `servers/` are compile-checked, and the isolation hook passes all
  eight cases in `README.md`.

Do these three things, in order, stopping after each so I can confirm:

**Step 1 — get Telegram working end to end.**
Walk me through `cp .env.example .env` and filling in `TELEGRAM_BOT_TOKEN`
only, leave every other block blank. Then use `telegram_get_messages` to find
my chat id, have me add it to `.env`, and send me a test message. Nothing else
proceeds until a message reaches my phone.

**Step 2 — write your own identity files.**
`identity/SOUL.md`, `IDENTITY.md` and `USER.md` are templates full of `TODO`.
Interview me — ask whatever you need, one batch of questions, not twenty
rounds — then write all three from my answers. Record the four remit areas in
`IDENTITY.md`. For `USER.md`, ask about my timezone, working hours, when not to
interrupt me, and how I want to be talked to.

**Step 3 — verify the boundary.**
Run the eight isolation cases documented in `README.md` and show me the
results. Identity A tools, out-of-directory reads, `.env` reads and escaping
Bash commands must exit 2. Identity B tools and in-directory reads must exit 0.

Then stop and ask me what the first real job should be. Do not guess it.

---

## What already exists

| Piece | State |
|---|---|
| `.claude/hooks/isolation_guard.py` | Written, tested against 8 cases |
| `.claude/settings.json` | Hook registered, A-connectors denied, twilio deliberately not allowlisted |
| `.claude/isolation.json` | Boundary rules, tunable |
| `servers/telegram_mcp.py` | Send + read messages. Compile-checked, not yet run live |
| `servers/notify_mcp.py` | ntfy push. Compile-checked, not yet run live |
| `servers/mailbox_mcp.py` | IMAP/SMTP, app password. Parked until credentials exist |
| `servers/twilio_mcp.py` | SMS + voice. Parked. Costs money per use |
| `.mcp.json` | Active: `telegram`, `notify` |
| `mcp.parked.json` | Held back: `mailbox_b`, `twilio`, `notion_b` |
| `identity/*.md` | Templates with `TODO` markers — Step 2 fills these |
| `memory/` | Empty by design; `log.md` and `facts.md` created on first use |

**Nothing has been run against a live account.** The servers are written and
compile-checked, but Step 1 is the first real execution — expect to fix
something small there. That is normal, not a sign the scaffold is wrong.

## Two things worth knowing

**The isolation is a strong lock, not a security wall.** Both identities run
under one claude.ai account, so the boundary is configuration: a project-scoped
`.mcp.json`, a permission deny-list, and a `PreToolUse` hook. The hook is
string-matching — a determined shell command could evade it, and anyone with
access to your machine can edit the config. It is solid against accidental
crossover, which is what it was built for. If Identity B ever holds someone
else's data, the real answer is a second claude.ai account or a dedicated OS
user.

**Your son does not use this brain.** Claude is 18+ and enforces it
behaviourally, on conversation content — and this runs on the same account as
your business. A session that reads as a minor talking to Claude risks the
tooling you run 3dsvet on. You prepare material *for* him; he consumes it in
Notion or on paper. If he wants to ask an AI questions directly, Gemini or
NotebookLM under a supervised teen account is the route built for that.

## Where the design came from

`PLAN.md` has the full reasoning: the six cores, what was decided, what was
deliberately deferred and why. Read it before changing the shape of anything.
