# Vibe Engineering — the context system (map of the map)

Four always-current documents, one append-only log, and a dated history. Every agent
session starts from the same ~9 KB bootstrap (the SessionStart hook extracts it from these
files), so the files have shapes the hook depends on. **Keep the headings the hook anchors
on** (listed at the top of `.claude/hooks/session-start.sh`; `scripts/ve-check.sh` verifies).

| File | Holds | Rule |
|---|---|---|
| `STATUS.md` | *Current state*: mission, Active work (claims), Milestones (~300-byte rows), Current status (Shared + one block per owner), last ~10 worklog lines | **Rewrite, don't append.** Only your own rows/block. ≤ 20 KB; owner blocks ≤ 40 lines and lead with Now / Open / Next (the hook injects the first ~400 bytes of each). |
| `ARCHITECTURE.md` | *What is*: invariants, stack, layout, data model, routes, environment, run & verify, conventions & gotchas | Never *why* (that is DECISIONS). No stale islands — update every representation of a fact. Split a section past ~100 lines into `architecture/<section>.md`. |
| `DECISIONS.md` | *Why*: load-bearing choices with the rejected alternative and the consequences | Append-only, newest first. One decision per entry. Title ≤ 120 chars. Reversal = new entry that links the old one. |
| `decisions/INDEX.md` | One row per decision (date, area, status, ≤ 100-char summary, file) — the hook's inventory | Add a row for every new entry; flip `status` on supersession. The one place supersession is recorded. |
| `decisions/archive-*.md` | Entries older than a cut date, verbatim | Roll DECISIONS.md into a new archive when it passes ~100 KB. |
| `STATUS-archive.md` | Milestone rows and owner-block history rolled out of STATUS, verbatim (create on first roll-out) | Append at the top of each section; never edit what is there. Links from worklogs keep resolving. |
| `architecture/*.md` | Area detail once a map section outgrows ~40 lines (layout, data model, routes, conventions per area) | Read the one for the area you touch; the map keeps a summary + pointer per section. |
| `worklogs/` | *Story*: one dated file per session (`YYYY-MM-DD-<author>-<slug>.md`), ~50 lines, hard cap 100 | Never edit a previous session's file. Index line in `worklogs/INDEX.md` **and** STATUS. |
| `plans/` | Specs and implementation plans for multi-session work | Dated, named after the feature; mark superseded parts at the top rather than editing history. |
| `reference/` | Runbooks, portal checklists, policies, third-party kits — things that are consulted, not maintained | Each file says what it is for in its first line. |

## The loop every session follows

1. **Start**: the hook injects protocol + Active work + every owner block's head + all
   invariants + the newest decision index rows. Claim a row in Active work. Start the worklog file.
2. **Work**: capture decisions and surprises in the worklog *as they happen*. One local
   commit per phase. Never push without a go-ahead.
3. **Verify**: `live-e2e-verify` — typecheck, unit, build, then a real-stack pass with
   throwaway identities and cleanup. "Done" means seen working.
4. **End**: update STATUS (your rows/block), index the worklog, **promote, don't pile** —
   always-true rule → ARCHITECTURE invariants; recurring gotcha → ARCHITECTURE conventions;
   load-bearing decision → DECISIONS + an INDEX row; repeatable procedure → a skill. Run
   `scripts/ve-check.sh`.

## What goes where (the test)

- Would a future maintainer re-litigate it? → DECISIONS.
- Is it true regardless of date? → ARCHITECTURE.
- Does it change every session? → STATUS.
- Is it a story (what happened, in order)? → worklog.
- Is it a procedure someone will repeat? → skill.
