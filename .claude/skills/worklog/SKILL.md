---
name: worklog
description: Session worklog protocol for {{PROJECT}} — use at session start (to load recent context) and at session end or after significant progress (to log the session). Creates dated files under "Vibe Engineering/worklogs/" and keeps STATUS.md current.
---

# {{PROJECT}} Session Worklog Protocol

History lives in `Vibe Engineering/worklogs/` as **one dated file per session**
(`YYYY-MM-DD-<author>-<slug>.md` — author is the collaborator's short name so parallel
sessions never collide; same author + day + slug taken → append `-2`). The always-read
docs stay short:
`Vibe Engineering/STATUS.md` (current state, active work, milestones),
`Vibe Engineering/ARCHITECTURE.md` (structural map + conventions), and
`Vibe Engineering/DECISIONS.md` (append-only decision log). Never grow STATUS or
ARCHITECTURE with narrative — narrative goes here.

## At session start

1. On fresh sessions the SessionStart hook (`.claude/hooks/session-start.sh`; the Codex
   wiring symlinks to it) already injected the session protocol, STATUS.md *Active work*
   + the head of every owner block under *Current status* (a `[… more …]` marker says where
   it stopped), every ARCHITECTURE invariant, and the newest rows of `decisions/INDEX.md` —
   don't re-read them. Milestones, the rest of the owner blocks and the worklog index are not
   injected. Re-read STATUS only after pulling or if you need an owner block's tail; if the
   session was resumed/compacted the hook didn't fire — use the `session-context` skill.
2. Need the story behind something? Open the 1–3 most relevant dated files (via the index) —
   not all of them. For a past *choice* and its rationale, scan `decisions/INDEX.md` (area,
   status, summary) and open that one entry in `DECISIONS.md` / `decisions/archive-*.md`.
   Before code work in an area, read `ARCHITECTURE.md` (the map) + its `architecture/<area>.md`.
3. Starting new work? **Claim it**: add a row to the Active work table (owner, claimed
   date, branch, what). Solo, a local commit suffices; once this repo has >1 collaborator,
   push the claim as a STATUS-only `status: claim <what>` commit — the one push that
   needs no go-ahead. Never start work another row already claims; rows >7 days stale
   with no branch activity may be reaped by anyone (note it in your worklog).

## At session end (or after a major milestone)

1. Create `Vibe Engineering/worklogs/YYYY-MM-DD-<author>-<slug>.md` from the template
   below. **Never append to or edit a previous session's file** — one file per session,
   ~50 lines, hard cap 100. Over? Cut sections, not specificity.
2. Update `Vibe Engineering/STATUS.md` — **your own rows and owner-block only**:
   - Active work: update your row, or release it (delete the row; outcome + evidence →
     milestone table).
   - Milestones: one ~300-byte row — status, PR + hash + date, open items, worklog link.
     Rows older than ~2 weeks (or two-or-more milestones old) move **verbatim** to
     `STATUS-archive.md` § Milestones and become one clause of the Shipped roll-up.
   - Your `### @<author>` block under "Current status" (rewrite, don't append; ≤ 40 lines —
     the hook injects only its first ~400 bytes, so lead with Now / Open / Next); shipped
     paragraphs move verbatim to `STATUS-archive.md` § your history. The Shared block only
     if project-wide truth changed.
   - Add an index line for the new worklog in STATUS (≤ 120 chars, keep the last ~10 rows)
     **and** the full line in `worklogs/INDEX.md`.
3. **Promote, don't pile:** anything durable moves to its home —
   - always-true rule → `ARCHITECTURE.md` § Invariants (≤ 2 lines; long form in
     `architecture/invariants.md`); structural change → the map section + its
     `architecture/<area>.md` file (no stale islands: update every representation);
   - recurring gotcha → `architecture/conventions-<area>.md` if the area has a file, else
     `ARCHITECTURE.md` § Conventions & gotchas;
   - **load-bearing decision + rationale → `DECISIONS.md`** (one decision per entry, title
     ≤ 120 chars, newest first) **plus one row at the top of `decisions/INDEX.md`** (date,
     area, status, ≤ 100-char summary); a reversal is a new entry + flipping the old row's
     status to `superseded→<date>` — bodies are never rewritten;
   - repeatable procedure → a skill in `.claude/skills/`.
   The worklog keeps only the one-time story.
4. Run `scripts/ve-check.sh` before committing the docs — it catches heading drift, size
   budgets, hook truncation, missing index rows and machine-local paths.

## Template

Start the file at session start and fill it in as you work, not retroactively at the end.

```markdown
# YYYY-MM-DD — <Title> (Session N, branch if any) — <author>

**Goal:** [one sentence — what and why]

## Skills Loaded
> Load skills for *everything*, no matter how small — this prevents
> "I didn't know that existed" mistakes.
- `skill-name` — [why it applies]

## Invariants declared (only if this session introduces new always-true rules)
- **INV-X:** [rule — payments, auth, rate limiting, data privacy… anywhere
  "almost right" ships a bug. Promote to ARCHITECTURE.md at session end.]

## Progress
- [what got done, with commits]

## Closing the Loop
> Done means *seen working*, not "code looks right".
- [ ] `{{TYPECHECK_CMD}}` clean
- [ ] `{{TEST_CMD}}` passes
- [ ] build/bundle step (if a client was touched)
- [ ] live E2E per the `live-e2e-verify` skill (if API/DB/storage/AI touched)
- [ ] [feature-specific verification]

**Blocked by:** [specific: "API returns 403 and I don't know why", not "stuck"]
**Next:** [what the next session should pick up — and WHO: "anyone" or "needs <name> because <reason>"]

## Surprises
- [unexpected behavior / wrong assumption — capture in real time, then promote if durable]

## Decisions
> Capture here as they happen; promote the load-bearing ones to DECISIONS.md at session end.
| Decision | Rationale |
|---|---|
```

## Protocol rules

1. **Update in real-time.** Capture decisions and surprises as they happen, not batched
   at session end — context is freshest right after you hit the issue.
2. **Atomic commits**, one logical change each; codebase working at every commit.
3. **Close the loop.** Don't check a Closing-the-Loop box until you've run it and seen
   it pass this session.
4. **End with "Next".** Future sessions — yours or a collaborator's — start from
   STATUS.md + your Next line. Write it for someone who wasn't here.
5. Drop sections that don't apply — cut sections, not specificity.
