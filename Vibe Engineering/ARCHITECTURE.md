# {{PROJECT}} — Architecture Reference

> Structural map of the codebase + always-true rules. Read this first to get oriented;
> read [STATUS.md](STATUS.md) for current state/next steps, [DECISIONS.md](DECISIONS.md)
> for *why* load-bearing choices were made, and the dated files in [worklogs/](worklogs/)
> for session stories (on demand only).
> Product spec: `plans/{{SPEC_FILE}}`.
> Keep this current as phases land — see Maintenance rules at the bottom.

## Invariants (violations are bugs)

<!-- Always-true rules, each with WHERE it is enforced, 2–3 lines each. The hook injects
     this whole section (3,000-byte cap, comment included) into every session.
     Examples: every user-owned table has row-level ownership; secrets never reach the
     client; all external input is schema-validated. -->

- **INV-1 ({{name}}):** {{rule}} — enforced by {{where}}.
- **INV-2 ({{name}}):** {{rule}} — enforced by {{where}}.

## Stack

- {{runtime / framework / database / hosting, one line each with the version that matters}}

## Layout

<!-- Directory-level tree, annotated with counts + pointers to the authoritative section
     ("12 routes — see § API routes"). Never list files one by one: that rots. -->

```
.
├── {{dir}}/   — {{what lives here}} (see § …)
└── Vibe Engineering/   — this context system (README.md explains the files)
```

## Data model

<!-- One table per entity: columns that matter, ownership rule, constraints that encode
     invariants. Keep in sync with the migrations directory. -->

## API routes

| Method + path | Auth | Purpose | Validation |
|---|---|---|---|

## Environment

| Variable | Scope (server / client-public) | Purpose | Blank = ? |
|---|---|---|---|

## Run & verify

```
{{TYPECHECK_CMD}}
{{TEST_CMD}}
{{DEV_CMD}}
```

## Conventions & gotchas

> Grouped by area. Recurring traps get one bullet here the session they're discovered
> (promote from the worklog); past ~40 bullets total, spill a group to
> `architecture/conventions-<area>.md` and leave a pointer.

### Process & scope

- **Commits:** one per phase, local only. **Never push without explicit user go-ahead**
  (sole exception once >1 collaborator: STATUS-only claim/release commits — `worklog` skill).
- **One agent session per working tree.** Parallel sessions on one checkout commit each
  other's dirty files; use a git worktree for a second session.
- **Definition of done for every feature:** happy + sad paths, loading + empty + error states,
  input validation, errors logged, permission-scoped data, verified per `live-e2e-verify`.

### {{Area}}

- {{gotcha}} ({{date discovered}}, worklog link)

## Maintenance rules (for the agents that update this file)

- Decisions and their rationale do NOT live here — they go to [DECISIONS.md](DECISIONS.md).
  This file records *what is*, not *why we chose it*.
- **No stale islands:** if you update one representation of a fact (e.g. the data-model
  section), update its other representations too (the layout tree, the routes table) —
  or keep only one home per fact. File trees stay annotated at the directory level
  (counts + pointers to the authoritative section) so they don't rot file-by-file.
- If any single section outgrows ~100 lines, split it into
  `Vibe Engineering/architecture/<section>.md` and leave a one-line pointer here.
  `scripts/ve-check.sh` warns when a section crosses the line.
- Never duplicate STATUS.md content here — this file is the map, STATUS is the state.
- The `## Invariants` … `## Stack` headings are hook anchors. Rename them and the hook
  reports an EMPTY extraction in every session.
