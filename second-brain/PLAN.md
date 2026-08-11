# Private-Life Brain — Foundation

## Context

Danijel runs 3dsvet.eu with Claude Code already wired to WordPress, Semrush,
Gmail, Notion, Drive and Calendar. That is **Identity A** — his business.

He wants a **second brain** for **Identity B: his private life**, on a separate
set of accounts (personal Gmail, Telegram, phone, Notion), so business context
stops bleeding into personal work and vice versa.

**He operates it himself.** An earlier pass explored building it for his son,
who starts high school soon; that is now correctly scoped as a *use case inside*
the private brain — Danijel prepares material as a parent — rather than the son
operating anything. Worth recording why: Claude is 18+ and enforces it
behaviourally, and this runs on the same claude.ai account as his business, so a
brain a minor talks to directly would put his 3dsvet tooling at risk. With
Danijel as the user, that concern disappears entirely.

A scaffold already exists on branch `claude/custom-ai-research-o6wxvg` under
`second-brain/`. With Identity B settled as his private life, **it is correct as
built** — every server in it is appropriate for his own personal accounts. This
plan finishes the foundation rather than rebuilding it.

## Scope

Four areas confirmed in remit: **personal admin**, **parenting & school
support**, **personal projects**, **planning & memory**.

**No job gets built yet.** The decision is foundation-first: get the brain
running, then pick the first real job once he's felt how it behaves. This plan
deliberately stops short of Notion databases and job skills — building those
before a real job exists produces structure nobody uses.

## The six cores

| # | Core | Answer |
|---|---|---|
| 1 | Identity | Danijel's private life; he is the operator |
| 2 | Jobs | Four areas in remit; none built yet, by choice |
| 3 | Knowledge | Notion, structure deferred until a job needs it |
| 4 | Channels | Telegram primary, ntfy push, Twilio SMS/voice, personal mailbox |
| 5 | Autonomy | Advisor only — reads, analyses, drafts; sends nothing unasked |
| 6 | Runtime | Local only for now; VPS when something must run unattended |

## Where this runs

**Build here, run locally.** The code is already pushed to the branch, so it
transfers by pulling. But the foundation work below happens in VS Code on
Danijel's own machine, for two reasons:

1. **Credentials never enter a remote container.** This session runs in an
   ephemeral cloud container, and `second-brain/` currently sits inside a GitHub
   repo. The personal Gmail app password and Telegram token should exist only on
   his machine. `.env` is gitignored, but the stronger rule is that real secrets
   are never typed into remote infrastructure at all.
2. **MCP servers must run where the credentials are.** Testing them means
   executing against live accounts — local first, VPS later.

**Also: lift `second-brain/` out into its own private repo.** It currently lives
inside the `Test01` Flutter app only because push access was scoped to that
repository. The directory is self-contained, so this is a move, not a rewrite —
and the isolation config is directory-scoped, so it keeps working unchanged.

Setup locally: VS Code with the Claude Code extension, `claude` started from
inside the `second-brain/` directory so the project-scoped config loads.

## Work to do

### 1. Get one channel working end to end
- `cp .env.example .env`, fill in **`TELEGRAM_BOT_TOKEN` only**
- Run `telegram_get_messages` to discover the chat id, add it to `.env`
- Send a test message; confirm it lands on his phone

Nothing else proceeds until this works. Every other credential block stays blank
— those servers report themselves unconfigured rather than failing.

### 2. Rewrite the identity layer
`identity/SOUL.md`, `IDENTITY.md` and `USER.md` are `TODO` templates. Fill them
**by interview, not by guesswork** — the brain asks what it needs and writes its
own files. `IDENTITY.md` records the four areas as its remit.

`CLAUDE.md` needs its purpose line changed from generic "Identity B" to the
private-life framing, and an explicit **advisor-only** rule: it may read,
analyse and draft, but sends, publishes and posts nothing without approval.

### 3. Trim `.mcp.json` to what's configured
Keep `telegram` and `notify` active. Leave `mailbox_b`, `twilio` and `notion_b`
defined but unconfigured until their credentials exist — an unconfigured server
is noise in the tool list.

### 4. Verify the boundary
Rerun the 8 hook cases documented in `second-brain/README.md`.

## Critical files

- `second-brain/CLAUDE.md` — purpose + advisor-only rule
- `second-brain/identity/{SOUL,IDENTITY,USER}.md` — fill by interview
- `second-brain/.env` — Telegram only, not committed (already gitignored)
- `second-brain/.mcp.json` — trim to configured servers
- `second-brain/.claude/hooks/isolation_guard.py` — unchanged, already tested

## Verification

1. **Isolation** — the 8 cases from `README.md`: Identity A tools, out-of-brain
   file reads, `.env` reads and escaping `Bash` commands all exit 2; Identity B
   tools and in-brain reads exit 0.
2. **Telegram round trip** — send a message from the brain, reply from the
   phone, read the reply back with `telegram_get_messages`.
3. **Identity** — start a fresh session in `second-brain/` and confirm it knows
   who it is and what it may not do, without being told.
4. **The real test** — pick the first job only after a few days of use. If
   nothing obvious surfaces, that itself is the answer: the brain isn't needed
   yet, and no amount of scaffolding fixes that.

## Deliverable from this session

Work moves to Danijel's machine, so this session's output is a **handoff that
survives**. The plan file itself lives in an ephemeral container and is lost
when the session is reclaimed, so everything needed must be committed to the
branch.

1. **`second-brain/HANDOFF.md`** — a kickoff prompt to paste into local Claude
   Code, carrying: what Identity B is, the advisor-only rule, what is already
   built and verified, what is deliberately deferred and why, and the first
   three steps in order.
2. **`second-brain/PLAN.md`** — this plan, committed so it outlives the session.
3. **`second-brain/CLAUDE.md`** — rewritten from generic "Identity B" to the
   private-life purpose, with the advisor-only rule stated explicitly.
4. **`second-brain/.mcp.json`** — trimmed to `telegram` and `notify`; the rest
   stay defined but inactive until their credentials exist.

Nothing else is built here. The identity interview, Notion structure and first
job all happen locally, where the credentials live.

## Deferred by decision

Notion database structure, job skills, scheduled reminders, and the VPS move.
All wait for a confirmed first job.
