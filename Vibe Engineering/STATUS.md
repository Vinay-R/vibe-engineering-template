# {{PROJECT}} — Status

> Current state + next steps. Structural map: [ARCHITECTURE.md](ARCHITECTURE.md).
> Decisions + rationale: [DECISIONS.md](DECISIONS.md) — check before re-deciding anything.
> Session history: [worklogs/](worklogs/) (dated files; recent index below, full index in
> [worklogs/INDEX.md](worklogs/INDEX.md) — read on demand only).
> Update at every session end per the `worklog` skill; **rewrite, don't append** — but only
> ever rewrite your own owner-block and rows. On merge conflict, rewrite the merged truth.
> **Size budget: ≤ 20 KB; owner blocks ≤ 40 lines; milestone rows ≤ ~300 bytes.** The hook
> injects *Active work* whole and the head of every owner block; a `[... truncated ...]` marker
> in a fresh session means trim (roll rows and history into `STATUS-archive.md`), never raise.

## Mission

{{MISSION_ONE_PARAGRAPH}} (spec: `plans/{{SPEC_FILE}}`).

## Active work

> Coordination point. Claim = add a row (and, once this repo has >1 collaborator, push it
> as a STATUS-only `status: claim` commit — solo, a local commit suffices). Release = delete
> your row and record the outcome + evidence in the milestone table. Any collaborator may
> reap a row >7 days stale with no branch activity (note it in your worklog).

| Owner | Claimed | Branch | What | State / blocker |
|---|---|---|---|---|
| {{OWNER}} | {{DATE}} | `main` | Adopt the context system (fill ARCHITECTURE invariants + stack, first DECISIONS entry) | Just installed |

## Milestones

> Active + recently-shipped rows only; **Verified** = evidence + worklog link, ~1 line.
> Shipped milestones two-or-more milestones old collapse into the roll-up below.

| # | Phase | Status | Verified |
|---|---|---|---|
| 0 | Context system installed | 🟡 | — |

**Shipped roll-up:** (none yet — when rows age out of the table, summarize them here in one
paragraph with worklog links.)

## Current status → immediate next

### Shared / project-wide

{{ONE_PARAGRAPH_PROJECT_WIDE_TRUTH}} — where production runs, what is live, what every
collaborator must know this week. Rewrite when project-wide truth changes; never append.

### @{{OWNER}}

What I'm on, what's blocked, what's next. ≤ ~25 lines; detail goes in the worklog.

## Worklog index (recent — full index: [worklogs/INDEX.md](worklogs/INDEX.md))

| Date | File | What |
|---|---|---|
