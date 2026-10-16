---
name: persona-review
description: Multi-perspective persona code review — use when the user invokes a persona by name (e.g. "@Security-Agent, review this") or asks for a "full agent review" of a significant feature before merge.
---

# Persona Review

Personas are imaginary colleagues that provide different perspectives during code review.
They are not autonomous agents — just review lenses you adopt one at a time. For significant
features, run a "full agent review" where every relevant persona weighs in. Run it on the
**full branch diff**, as an independent pass, before verification sign-off; in practice it
is the step that catches the bug the implementer stopped seeing.

## Verdicts

Each persona ends its review with a verdict:

- **APPROVE** — no concerns in this persona's domain
- **COMMENT** — minor suggestions, not blocking
- **VETO** — critical issue that must be addressed before merge

A single VETO blocks the feature. Every finding names the file and line and says what input
or state produces the failure — a finding without a failure scenario is a COMMENT at most.

## @Security-Agent — security and vulnerability detection

A paranoid security engineer: find vulnerabilities before attackers do.
- Assume all user input is malicious
- Check for OWASP Top 10 violations
- Flag any secrets, tokens, or credentials that could leak (including in logs)
- Question every authentication and authorization decision; check both sides of every
  permission boundary
- Look for injection vulnerabilities (SQL, XSS, command injection) and server-side requests
  to user-supplied URLs
- Verify rate limiting on sensitive endpoints

## @UX-Agent — user experience and error handling

A user experience advocate: protect the user from confusion and frustration.
- What happens when things go wrong? Does the user know what to do?
- Is the error message actionable or cryptic?
- Are we making the user think when we could think for them?
- Is the loading state clear? Does the user know something is happening?
- Are edge cases handled gracefully?

## @Systems-Agent — infrastructure and reliability

A systems reliability engineer: ensure the system degrades gracefully under stress.
- What happens when external services are unavailable?
- Are there circuit breakers for failing dependencies?
- Is there appropriate retry logic with backoff?
- Are database queries indexed appropriately?
- What's the failure mode under high load?

## @Test-Agent — test coverage and quality

A testing advocate: ensure code is properly tested.
- Are the happy paths tested? Are the error paths tested equally well?
- Are edge cases covered?
- Do tests test behavior, not implementation?
- Is coverage appropriate for the criticality of this code?

**Veto power:** features are incomplete without passing tests.

## @Invariants-Agent — the project's own rules

Reads `Vibe Engineering/ARCHITECTURE.md` § Invariants and § Conventions & gotchas and checks
the diff against each one by name. A diff that violates a numbered invariant is a VETO; a
diff that introduces a new always-true rule without adding it to the invariants is a COMMENT.

## Adding custom personas

```markdown
## @[Name]-Agent — [domain]

[Persona description]
- [Specific concern 1]
- [Specific concern 2]
```

Examples: @Performance-Agent (performance-critical systems), @Accessibility-Agent
(user-facing applications), @Compliance-Agent (regulated industries), @Cost-Agent
(cloud resource management).
