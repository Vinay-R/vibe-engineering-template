---
name: live-e2e-verify
description: Live verification pattern for {{PROJECT}} — use before declaring any phase/feature "done", especially anything touching the API, database, permissions, storage, or AI pipeline. Author pass runs against your local stack; the merger repeats it against the live one. Throwaway identities, full cleanup.
---

# Live E2E Verification ({{PROJECT}})

Not "done" until seen working against a **real stack**. Typecheck passing and code looking
right is not verification. Two passes, same script:

- **Author pass** — you, against your local stack (setup in `docs/ONBOARDING.md`). No
  production credential needed.
- **Merger pass** — whoever merges, against the **live stack** (needs whatever named,
  per-person, revocable credential the project hands out). Same script, same assertions,
  same cleanup. This is the only sanctioned write pattern against production from a laptop.

## Standard sequence per phase/feature

1. `{{TYPECHECK_CMD}}` — clean across all workspaces.
2. `{{TEST_CMD}}` — unit suite passes.
3. {{BUILD_CMD — the step that proves the client bundles/builds; skip if server-only}}.
4. **Live E2E script** (below) for anything touching API/DB/storage/AI.
5. **Browser or device walk** for anything with a UI: drive the real screen, assert the
   backend state after every write (not just the screen), keep screenshots as evidence.

## Live E2E pattern

Write a script in the session scratchpad (never committed):

1. **Create a throwaway identity** named `{{project}}-verify-<random>` with the admin
   credential (local: from the local stack; live: your named key).
2. **Sign in for a real token** and exercise the endpoints as that identity — the same
   path production clients take.
3. **Assert all of:**
   - Status codes for happy AND sad paths (400 bad input, 401 no auth, 404 foreign/missing
     resource, 422/429/5xx where the contract says so).
   - Rows actually written, with expected values (query with the admin credential).
   - **Permissions both directions:** owner sees their rows; a second throwaway sees zero
     and gets 404 on cross-user access by id. Storage: prefix/ownership policy blocks reads
     and writes outside the identity's own prefix.
   - Concurrency where it matters (N parallel spends at limit L → exactly L succeed).
4. **Delete the throwaway identities** at the end — including anything cascades do NOT
   reach (storage objects, external-provider records, queued jobs). **Never leave test data
   behind**, even on script failure (trap/finally).

## Gotchas that bite during verification

<!-- Promote here from worklogs the moment a trap bites twice. Keep each to 2–3 lines with
     the date. Typical residents: client-SDK calls that behave differently stateless vs
     stateful; model/provider access ≠ having a key; empty-string env vars treated as unset;
     scheduled jobs that no-op locally and must be driven by hand; analytics events that
     must be asserted against a local sink, never the real host. -->

- {{gotcha}} ({{date}})
