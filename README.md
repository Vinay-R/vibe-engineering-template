# Vibe Engineering — context-system template

A reusable layout for running a codebase with AI agents (Claude Code, Codex, anything that
reads `AGENTS.md`) across many sessions and several collaborators without the context
rotting. The structure below is what survived ~110 real agent sessions and two audits in a
production codebase.

## The idea

Every session starts from the same small, deterministic bootstrap, and every durable fact
has exactly one home:

| Question | Home | Shape |
|---|---|---|
| What is the state right now? | `Vibe Engineering/STATUS.md` | rewritten, never appended; ≤ 12 KB |
| What is true regardless of date? | `Vibe Engineering/ARCHITECTURE.md` | invariants + map + conventions |
| Why did we choose that? | `Vibe Engineering/DECISIONS.md` | append-only, newest first |
| What happened in session N? | `Vibe Engineering/worklogs/` | one dated file per session |
| How do we do X repeatably? | `.claude/skills/*/SKILL.md` | a skill |

A SessionStart hook (`.claude/hooks/session-start.sh`) extracts a **9 KB, priority-ordered
bootstrap** from those files — session protocol → Active work → invariants → the head of every
owner block → the newest decision index rows — with per-section caps and visible truncation markers. The number is not
arbitrary: Claude Code inlines hook context up to ~10 KB and spills the rest to a file with a
2 KB preview; Codex defaults to ~2,500 tokens. Anything bigger silently disappears.

## What's in the box

```
AGENTS.md                      agent rules (CLAUDE.md just imports it)
.claude/settings.json          wires the hook for Claude Code
.claude/hooks/session-start.sh the bootstrap extractor (also `--print` for resumed sessions)
.claude/skills/
  worklog/                     session protocol: claim → work → log → promote
  live-e2e-verify/             "done = seen working on a real stack": author pass + merger pass
  persona-review/              multi-lens review before merge (+ an Invariants persona)
  session-context/             re-inject the bootstrap after resume/compaction
.codex/hooks.json              same hook for Codex (symlink into .claude)
.agents/skills -> .claude/skills
Vibe Engineering/
  README.md                    map of the map: what goes where, the loop
  STATUS.md / ARCHITECTURE.md / DECISIONS.md   skeletons with the hook's anchor headings
  decisions/INDEX.md           one row per decision (date, area, status, summary) — the hook's inventory
  plans/  reference/  worklogs/INDEX.md
docs/ONBOARDING.md             access model, local setup, agent tooling (Codex trust steps)
scripts/ve-check.sh            lint: anchors, budgets, truncation, decision titles, index coverage
install.sh                     fills {{PROJECT}}/{{OWNER}}/{{DATE}} — in-place or into another repo
```

## Install

**Prerequisites:** bash and standard Unix tools; `python3` or `jq` for the hook's JSON mode
(without either, Claude Code gets no injected context — `--print` still works everywhere).

**Path A — new project from this template.** Click **Use this template** on GitHub (or clone
this repo), then, inside your new checkout:

```bash
./install.sh --in-place --name "My App" --owner sam
```

This fills the name/owner/date placeholders in place, swaps this README for a project stub,
and removes `install.sh`.

**Path B — add to an existing repo.**

```bash
./install.sh ~/Code/my-app --name "My App" --owner sam
cd ~/Code/my-app
```

Existing files are never overwritten (pass `--force` to override — your `CLAUDE.md`,
`AGENTS.md`, `.claude/settings.json` and `.gitignore` are skipped if present, so merge the
hook wiring by hand).

**Then, either way:**

```bash
grep -rn '{{' "Vibe Engineering" AGENTS.md docs .claude/skills   # fill the rest
scripts/ve-check.sh                                               # should be 0 errors
.claude/hooks/session-start.sh --print                            # what a session will see
```

Write two to six real invariants, the stack, and the first DECISIONS entry — a fresh Claude
Code session should show five `===` sections.

## Rules that make it work

1. **Claim before working** (Active work row). Solo: a local commit. Team: a STATUS-only
   `status: claim` push, the one push that needs no go-ahead.
2. **Never push without a go-ahead.** One local commit per phase.
3. **Promote, don't pile.** At session end, every durable fact leaves the worklog for its
   home. Narrative never enters STATUS or ARCHITECTURE.
4. **Done = seen working.** Author pass on a local stack, merger pass on the live one,
   throwaway identities, both sides of every permission boundary, cleanup on failure too.
5. **A truncation marker means trim, never raise the budget.**
6. **Headings are an API.** The hook anchors on `## Active work`, `## Milestones`,
   `## Current status`, `## Worklog index`, `## Invariants`, `## Stack` and the DECISIONS
   `## YYYY-MM-DD — title (author)` format. `ve-check.sh` fails if they drift.

## Things learned the hard way (already baked in)

- A flat `head -c 20000` on a growing STATUS silently dropped invariants and decision titles
  for weeks in both tools. Hence per-section caps, priority order, visible markers, and a
  fail-visible stub when a section extracts empty.
- A hardcoded `/Users/<name>` path in the Codex wiring broke the hook for every other
  collaborator. Hence root-from-script-path and `git rev-parse --show-toplevel`.
- Codex ignores a repo's `.codex/` layer until the project *and* the hook hash are trusted,
  with no warning in `codex exec`. Documented in ONBOARDING rather than bypassed.
- Plans kept in `~/.claude/plans/` are invisible to collaborators. Plans live in `plans/`.
- Decision titles that bundle three decisions in one line stop fitting the inventory.
  One decision per entry, ≤ 120 chars.
- Owner blocks in STATUS grow into 40 KB novels unless something says stop. `ve-check.sh`
  warns at 40 lines per block and 20 KB per file; the hook injects only each block's head.
- Nothing an owner writes fits a 2.8 KB section whole, so "inject the owner blocks" became
  "inject every owner's first ~400 bytes" — and a first line longer than the cap is cut at a
  space, never dropped.
- A 100-entry DECISIONS file is unreadable as a title list. The index (area, status, one-line
  summary) is what the hook shows, and the one place a reversal is recorded.

## License

[MIT](LICENSE).
