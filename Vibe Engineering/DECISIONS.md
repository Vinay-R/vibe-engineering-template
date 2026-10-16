# {{PROJECT}} — Decisions

> Append-only log of load-bearing decisions: choices a future maintainer would otherwise
> re-litigate or accidentally reverse. **Never rewrite or delete entries** — if a decision
> is reversed, append a new entry and link the old one ("supersedes {{DATE}} …").
> What qualifies: anything with a real alternative that was considered and rejected.
> Routine implementation detail stays in the worklog's per-session Decisions table;
> promote the load-bearing ones here at session end (`worklog` skill, step 3).
> Newest first. **One decision per entry; title ≤ 120 characters; one row at the top of
> [decisions/INDEX.md](decisions/INDEX.md)** (date, area, status, ≤ 100-char summary) — the hook
> injects the newest index rows, and the index is the one place supersession is recorded.
> When this file passes ~100 KB, move the oldest entries verbatim to `decisions/archive-<range>.md`.
> Heading format is a hook anchor: `## YYYY-MM-DD — <title> (<author>)`.

## {{DATE}} — The repo adopts the Vibe Engineering context system ({{OWNER}})

- **Decision:** Agent sessions bootstrap from a 9 KB extraction of `STATUS.md`,
  `ARCHITECTURE.md` and `DECISIONS.md` (SessionStart hook, same script for Claude Code and
  Codex); history lives in dated worklogs; durable facts are promoted to their one home at
  session end; nothing is done until verified on a real stack.
- **Why:** Narrative that piles up in always-read files silently truncates (measured: Claude
  Code inlines ~9 KB of hook context, spills the rest to a 2 KB preview; Codex defaults to
  ~2,500 tokens). Splitting state / map / why / story keeps the always-read set small and
  gives every fact exactly one home. Rejected: a single growing NOTES file (truncates, rots);
  per-agent memory only (not shared across collaborators or tools).
- **Consequences:** Heading names in the three files are load-bearing; `scripts/ve-check.sh`
  guards them and the size budgets. Resumed/compacted sessions must re-run the hook by hand
  (`session-context` skill).
