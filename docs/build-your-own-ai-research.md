# Building Your Own AI — Research Notes

Research based on the 8 YouTube videos you sent, plus current (2026) tooling.

> **Method note:** the transcript service (Supadata) hit its plan quota partway
> through, so this is built from each video's full metadata — title, chapter
> list, description, linked repos and tools — plus general knowledge of the
> tooling involved. Chapter-level claims are solid; I have not quoted anything
> from inside the videos.

---

## 1. The big realisation: "build my own AI" is four different projects

Your 8 videos look like one topic. They are not. They are four separate
disciplines with almost no overlap in skills, time, or cost. Picking the wrong
one is the single most expensive mistake here.

| # | Path | What you actually build | Time to something useful | Your videos |
|---|---|---|---|---|
| A | **Learn the internals** | A neural network in raw Python/NumPy | 2–6 weeks, output is knowledge not a product | Green Code, commonLuke |
| B | **Train your own LLM** | A tiny GPT — tokenizer, transformer, training loop | 1–3 months + GPU money, result is worse than free models | WeeklyHow |
| C | **Build agents on existing models** | Software that uses Claude/GPT to do real work | **Days** | Tech With Tim, Dan Martell, Nate Herk |
| D | **Vibe-code an AI product** | A web app wrapping an LLM, sellable | Hours to days | tef (Mocha) |
| E | *(bonus)* **Physical/voice assistant** | JARVIS-style voice + home control | Weeks, mostly hardware | Hacksmith |

**The honest summary:** Path B (train your own LLM) is the one everyone
imagines when they say "build my own AI", and it is the one that produces the
least usable result. A model you train on a home machine will be roughly at
GPT-2 quality — it babbles. It's a fantastic learning exercise and a terrible
product.

Path C is where the actual value is for you, and I'll explain why below.

---

## 2. Video-by-video verdict

Ordered by how useful each is *to you*, not by view count.

### ⭐ Tech With Tim — *Build an AI Agent From Scratch in Python* (34 min, 2025)
`bTMPwUgLZf0` · 790k views · [repo linked in description]

**This is the most useful video in your list.** It's a real, complete,
code-along tutorial — not a hype video. The chapter list tells you exactly what
you get:

- Setup, virtual environments, getting an Anthropic/OpenAI API key
- Basic LLM calls → **structured output with Pydantic** (the single most
  important practical skill on this list)
- Prompt templates
- Creating and running an agent, output parsing
- Prebuilt tools (DuckDuckGo search), then **custom tool calling**

Stack: Python, LangChain, Pydantic, Claude or GPT via API.

**Caveat:** it's from March 2025. LangChain has moved a lot since. The
*concepts* — structured output, tools, agent loop — are permanent and correct.
The exact imports may not be. Build it, then be ready to update the syntax.

**Difficulty:** beginner-friendly if you know any Python. This is your
foundation.

### ⭐ Nate Herk — *Every Level of a Claude Second Brain* (31 min, June 2026)
`DTCyvo6cC54` · 206k views

**This is the most relevant video to your actual situation** — more on that in
section 3. Five levels of building a persistent AI system in Claude Code:

- **L1** (4:19) — a `CLAUDE.md` file that acts as a router: rules and context
  Claude reads every session, so you stop re-explaining yourself
- **L2** (8:11) — structured knowledge files the agent knows where to look in
- **L3** (13:03) — skills and subagents: packaged expertise and specialists
- **L4** (19:27) — MCP servers: live connections to real systems (email,
  calendar, your database)
- **L5** (25:25) — always-on autonomous system with scheduled runs

His framing at 28:48 is the important part and I'd underline it: **the goal is
not to reach level 5.** It's to find the lowest level that solves your actual
pain. Most people over-build.

### Dan Martell — *How to Build Your First AI Agent* (22 min, July 2026)
`Bm84BAtOfQw` · 313k views

Business-owner framing, no code. Its value is a mental model, and he published
the actual prompts in the description, so you get the goods without watching:

- **Identity files** — every agent gets three: a `SOUL` file (values, how it
  behaves), an `IDENTITY` file (what it is), and a `USER` file (about you).
- **Manager / specialist architecture** — a manager agent that *never does work
  itself*; it spawns one sub-agent per job. "One agent, one lane." This maps
  exactly onto Claude Code's subagents.
- **Voice cloning by example** — point the agent at your last 50 sent emails,
  have it write a style guide, then test it on a real draft.

Expect a sales funnel (free "AI Company OS", partner program). The three ideas
above are genuinely good; take them and skip the offer.

### tef — *I Made AI Create AI* (9 min, Feb 2026)
`4PZvO0ILluo` · 61k views

Vibe-coding a whole AI web app ("EduBot") using Claude Opus to write the prompt,
then **Mocha AI** to build the app. Chapters cover naming, logo, refining,
**monetising** (7:07) and publishing (7:31).

This is the fastest path to a *thing that exists on the internet*. It is also a
sponsored video for Mocha, and the honest caveat is that no-code AI app builders
produce apps you don't fully control and can't easily debug. Worth watching for
the shape of the workflow; I would not build anything you care about on it —
you already have Claude Code, which does the same job and leaves you owning the
code.

### Green Code — *I Built a Neural Network from Scratch* (9 min, 2024)
`cAkMcPfY_Ns` · 1.25M views

Pure Python + NumPy neural network, no framework (PyTorch used only to check the
forward pass). He credits [nnfs.io](https://nnfs.io) — *Neural Networks from
Scratch* by sentdex — as how he learned it.

This is Path A: real understanding of forward pass, backpropagation, gradient
descent, activation functions, loss. **A 9-minute video is a trailer, not a
course.** The actual resource is the nnfs book/series behind it. Watch the video
to decide whether you want to spend a month on this.

### commonLuke — *I Tried to Build an AI From Scratch* (17 min, July 2026)
`IoM5zUI8oFc` · 297k views

Neural network that learns to play Super Mario Bros — neuroevolution (a genetic
algorithm evolving network weights against a fitness score), not standard
supervised learning. Uses `gym-super-mario-bros`, code on GitHub, inspired by
SethBling's classic MarI/O.

Excellent motivation, very visual, teaches fitness functions and why "learning"
takes thousands of iterations. Entertainment-first — the pitfalls are the
lesson. Same category as Green Code: understanding, not product.

### WeeklyHow — *I Made AI Make AI (LLM)* (11 min, March 2026)
`R_di8auKgPc` · 167k views

Eight frontier models (GPT-5.3, Codex, Gemini 3.1/3 Pro, Claude Opus 4.6, Sonnet
4.6, Composer 1.5) each asked to write an LLM from scratch, compared at 9:38.

Useful as a **reality check on Path B**: it shows what components an LLM needs
(tokenizer → embeddings → transformer blocks → training loop → sampling) and
that even top models writing the code doesn't get you a good model, because the
bottleneck is data and compute, not code. Content-format video, not a tutorial.

### Hacksmith — *I made JARVIS from Iron Man real* (13 min, 2023)
`e_nKCZe6Ikc` · 1.67M views

Voice assistant in a workshop: speech-to-text → LLM → **ElevenLabs** for the
voice → home/shop automation (lights, a go-kart, a flamethrower). Entertainment
with a real pipeline underneath. The architecture is legitimate and cheap to
copy today (Whisper + Claude + ElevenLabs + Home Assistant); the theatrics are
not the point. Watch last, for fun and for the pipeline diagram in your head.

**Suggested watch order:** Nate Herk → Tech With Tim (code along, don't just
watch) → Dan Martell (skim, read the prompts) → the rest as interest allows.

---

## 3. What I'd actually recommend for you

You have a strong signal in your own setup that most beginners don't: **you are
already running Claude Code with MCP servers connected to WordPress, Semrush,
Gmail, Notion, Google Drive and Calendar.** You have custom skills written for
3dsvet.eu product descriptions.

That means you are *already living in Nate Herk's Level 3–4*. You didn't set out
to build an AI, but you have most of one. The highest-return move is not to
start over with NumPy — it's to formalise what you already have.

**Recommendation: Path C, in three stages.**

**Stage 1 — Consolidate (this week, ~4 hours).**
Write a proper `CLAUDE.md` for your work. Add the SOUL / IDENTITY / USER idea
from Dan Martell. Audit the skills you already have. This is Level 1–2 and it
pays off immediately because it stops you re-explaining context every session.

**Stage 2 — Learn the primitives (weekend, ~6 hours).**
Code along with Tech With Tim in VS Code. Build the agent yourself in raw Python
with the Anthropic SDK. Do not skip this even though Claude Code already does it
for you — until you've written a tool-calling loop by hand, agents are magic,
and you can't debug magic. Focus on: structured output, tool definitions, the
agent loop.

**Stage 3 — Build one real agent for your business (1–2 weeks).**
Pick one repetitive job you actually do. Given your shop, the obvious candidates:
a product-description agent that takes a supplier datasheet URL and produces the
full WooCommerce listing; a competitor/SEO monitor using your Semrush connection;
an inbox triage agent. **One agent, one lane** — Martell is right about that.

Do Path A (Green Code / nnfs.io) later, in parallel, purely for understanding.
It will make you better at Path C but it is not on the critical path. Skip Path
B entirely unless it's a hobby — training your own LLM in 2026 is a research
exercise, not a product decision.

---

## 4. Tools — what to use and what to skip

**Keep / use:**

- **VS Code** — yes, it's the right editor. Add the Python extension and the
  Claude Code extension.
- **Claude Code** — this *is* your agent framework. Skills, subagents, MCP and
  hooks cover everything Nate Herk's levels 1–5 describe, natively.
- **NotebookLM (Gemini)** — genuinely good for exactly one job here: dump the
  docs (Anthropic API docs, LangChain docs, the nnfs material) into a notebook
  and interrogate them. It's a study tool, not a build tool. Don't try to build
  the agent in it.
- **Python 3.12+ with `uv`** — `uv` has replaced pip/venv as the sane default.
- **The Anthropic Python SDK** — start here rather than LangChain. LangChain
  adds abstraction you don't need yet, and Tim's 2025 syntax has drifted.

**Add when needed:**

- **Pydantic** — structured output. Non-negotiable for reliable agents.
- **MCP** — when your agent needs live data. You already use it.
- **Git/GitHub** — you have it. Commit your prompts like code; they *are* code.

**Skip for now:** no-code builders (Mocha, n8n, Make), vector databases and RAG
(only when you actually have documents to search), fine-tuning (almost always
the wrong answer — better prompts and better tools beat it), local model hosting
(interesting, but it's a distraction until something works).

**Rough costs:** Anthropic API pay-as-you-go, a few euros/month while learning.
Your existing Claude subscription covers Claude Code. GPU rental only matters on
Path B — another reason to skip it.

---

## 5. Five traps these videos will walk you into

1. **Confusing the paths.** "I want to build my own AI" almost always means
   Path C, but YouTube's most-viewed videos are Path A and B because they make
   better thumbnails. Don't spend a month on backprop to solve a business
   problem.
2. **Tutorial syntax rot.** Tim's video is from March 2025. Expect broken
   imports. When something breaks, read the current docs — don't assume you
   made a mistake.
3. **Over-building.** Level 5 autonomous systems are a great video and a bad
   first project. Solve one real pain at the lowest level that works.
4. **Sponsored recommendations.** Mocha, CodeRabbit, Hostinger, Copilot and
   several courses are paid placements in these videos. The *techniques* are
   real; the specific tool named is often just the sponsor.
5. **Skipping the boring part.** Structured output and error handling are what
   separates a demo that works once from an agent you trust with your inbox.
   That's the actual work.

---

## 6. Concrete first step

```bash
# in VS Code's terminal
curl -LsSf https://astral.sh/uv/install.sh | sh
uv init my-first-agent && cd my-first-agent
uv add anthropic pydantic
```

Then set `ANTHROPIC_API_KEY`, and write one script that asks Claude a question
and returns a Pydantic model instead of a string. That is roughly 20 lines and
it is the whole foundation. Everything after it — tools, memory, subagents,
scheduling — is a layer on top of that one loop.

---

### Sources

- [LLM Roadmap 2026 — Scaler](https://www.scaler.com/blog/llm-roadmap-2026-how-to-learn-large-language-models-from-scratch/)
- [Self-Training a Small LLM From Scratch (2026)](https://codersera.com/blog/self-training-small-llm-complete-guide-2026/)
- [The Roadmap to Becoming an LLM Engineer in 2026 — KDnuggets](https://www.kdnuggets.com/the-roadmap-to-becoming-an-llm-engineer-in-2026)
- [Claude Code Project Structure Explained (2026)](https://www.prakashbhandari.com.np/posts/claude-code-project-structure-2026/)
- [Claude Code Skills Complete Guide (2026)](https://duet.so/guides/claude-code-skills-complete-guide)
- [Claude Code as Your AI OS: Skills, Hooks, Subagents & MCP](https://claudeskills.info/blog/claude-code-ai-os-skills-hooks-subagents-mcp/)
- [Neural Networks from Scratch — nnfs.io](https://nnfs.io/)
