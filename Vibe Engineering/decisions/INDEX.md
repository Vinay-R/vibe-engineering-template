# Decisions index

> One row per entry in [../DECISIONS.md](../DECISIONS.md) and the archives, newest first. The
> hook injects the newest 10 rows into every session; agents read this file instead of the
> bodies and open an entry by date + title only when it matters.
> **Maintained:** every new DECISIONS entry gets a row at the top (worklog skill step 3);
> `scripts/ve-check.sh` fails when the counts differ. **Status** is the one place supersession
> is recorded (`active` / `superseded→YYYY-MM-DD` / `partial→YYYY-MM-DD`); bodies are never
> rewritten. **Area** ∈ process, web, api, data, infra, security, design (edit the list for
> your product). Summary ≤ 100 chars = what was chosen, not why.

| Date | Area | Status | Summary | File |
|---|---|---|---|---|
| {{DATE}} | process | active | Adopt the Vibe Engineering context system: 9 KB bootstrap, one home per fact, verify on a real stack | DECISIONS.md |
