# {{PROJECT}} — Engineer onboarding

<!-- Fill the four sections below. Keep the access model honest: say what is production,
     who can touch it, and what the sanctioned write pattern from a laptop is. -->

## The access model in one paragraph

{{Who has what access, where production is, how prod changes land (CI on merge, never by hand).}}

## Local setup

1. {{clone, install, env file from `.env.example`}}
2. {{start the local stack}}
3. `{{DEV_CMD}}` — then `{{TYPECHECK_CMD}}` and `{{TEST_CMD}}` should be green.

## How work flows

1. **Claim it** — add a row to `Vibe Engineering/STATUS.md` *Active work* (push it as a
   STATUS-only `status: claim <what>` commit once there is more than one collaborator).
2. **Branch + PR.** Never push to `main` directly.
3. **Verify before you call it done** — the `live-e2e-verify` skill: author pass locally,
   merger pass on the live stack.
4. **Log the session** per the `worklog` skill; promote decisions to DECISIONS.md.
5. Never commit `.env*` files with values; secrets are server-only.

## Agent tooling (Claude Code, Codex, others)

`AGENTS.md` is the single source of agent rules; `CLAUDE.md` is just `@AGENTS.md` (only
Claude Code understands the import, which fixes the direction). Skills live in
`.claude/skills/` (`.agents/skills` symlinks there). A SessionStart hook injects the
session bootstrap — protocol, STATUS *Active work* + *Current status*, ARCHITECTURE
invariants, the newest `decisions/INDEX.md` rows — capped at 9 KB because both tools silently truncate larger
hook output. One script, two wirings: `.claude/settings.json` and `.codex/hooks.json`
both run `.claude/hooks/session-start.sh` (`.codex/hooks/` symlinks it).

- **Claude Code:** nothing to do — it works on first open.
- **Codex (CLI or app):** two one-time approvals, per person, or the hook is **silently
  skipped**: (1) trust the project when Codex asks on first open (writes
  `[projects."<repo path>"] trust_level = "trusted"` to `~/.codex/config.toml`); (2) run
  `/hooks` and trust the SessionStart hook. Trust is pinned to the hook definition's hash,
  so re-approve after any change to `.codex/hooks.json`. Sanity check in a fresh session:
  *"list the lines in your context that start with `===`"* should name STATUS, Invariants
  and the Decision inventory.
- **Cursor / Copilot / anything else:** reads `AGENTS.md` natively; no hook, so run
  `.claude/hooks/session-start.sh --print` yourself at session start.
