---
name: session-context
description: Re-inject the session bootstrap (protocol, STATUS Active work + Current status, ARCHITECTURE invariants, newest decision index rows) when no SessionStart hook fired — after a resume, a compaction, a long session, or in a tool that has no hook support. Also use to check what a fresh session would see after editing STATUS/ARCHITECTURE/DECISIONS.
---

# Session context (on demand)

The SessionStart hook only fires on `startup` and `/clear`. A resumed or compacted session,
a session in a tool without hooks, or one that has drifted far from its bootstrap should
reload the same 9 KB extraction by hand:

```bash
.claude/hooks/session-start.sh --print
```

Read the output as if it had been injected: claim before working, don't re-decide anything
in the decision inventory, read the full ARCHITECTURE before structural work.

After editing `STATUS.md`, `ARCHITECTURE.md` or `DECISIONS.md`, run the same command to see
what the next session will get. A `[... truncated at N bytes …]` marker means the source
section has outgrown its share: trim it per the file's own roll-up rules (worklog skill),
never raise the budget. `scripts/ve-check.sh` runs the structural checks.
