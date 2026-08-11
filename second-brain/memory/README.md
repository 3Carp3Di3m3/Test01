# Memory

Two files, both gitignored because they will accumulate Identity B's private
detail:

- **`log.md`** — append-only record of significant actions. What was sent, what
  was published, what was decided. The next session reads this to know what
  already happened.
- **`facts.md`** — durable facts about Identity B's world that are expensive to
  rediscover. Account names, recurring contacts, standing preferences,
  decisions that shouldn't be relitigated.

Create them on first use. Keep them short — this is a working memory, not an
archive. When `facts.md` grows past a page, that's a signal the brain wants
proper structure (a Notion database, a real file tree), not a longer file.
