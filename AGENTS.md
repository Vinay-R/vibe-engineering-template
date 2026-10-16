# {{PROJECT}}

<!-- One paragraph: what the product is and the stack. Keep this file under ~60 lines —
     it is read by every agent on every session. Detail belongs in Vibe Engineering/. -->
{{ONE_LINE_STACK_DESCRIPTION}}

**Auto-injected at session start** (SessionStart hook, 9 KB budget): session protocol,
STATUS.md *Active work* + *Current status* (the latter may be truncated), ARCHITECTURE
invariants, the newest `decisions/INDEX.md` rows — don't re-read those.
STATUS *Milestones* and the worklog index are **not** injected; open STATUS.md for them.
Resumed or compacted session (no hook fired)? Use the `session-context` skill.
**Read before structural/code work:** the full `Vibe Engineering/ARCHITECTURE.md`
(layout + conventions + gotchas).
**Decisions + rationale:** `Vibe Engineering/DECISIONS.md` — check before re-deciding anything.
**History:** `Vibe Engineering/worklogs/` — dated per-session files; read on demand only.
At session end, log the session per the `worklog` skill.
**New to the repo?** `docs/ONBOARDING.md` — local setup, access model, workflow.

## Hard rules

- **Never push without explicit user go-ahead.** Commit locally, one commit per phase.
  (Sole exception once >1 collaborator: STATUS-only claim/release commits — `worklog` skill.)
- **Claim work before starting it:** add a row to STATUS.md's Active work table
  (owner, claimed date, branch, what). Don't work on something another row claims.
- Nothing is "done" until verified per the `live-e2e-verify` skill: **author pass** on your
  local stack (throwaway identities, both sides of every permission boundary, cleanup);
  the **merger** runs the live pass.
- Secrets are server-only; clients get public-prefixed values only.
- Plans and specs live in `Vibe Engineering/plans/`, never in a machine-local path.
<!-- Add project-specific hard rules here (migrations, release gates, data handling).
     A hard rule is one whose violation ships a bug or leaks data; everything else is a
     convention and belongs in ARCHITECTURE.md § Conventions & gotchas. -->

## Commands

- `{{TYPECHECK_CMD}}` · `{{TEST_CMD}}` · `{{DEV_CMD}}`
- Context-system lint: `scripts/ve-check.sh` (run before committing docs)
