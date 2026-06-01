---
description: Run an obacht security scan and present results as a severity-grouped report.
argument-hint: "[obacht scan flags]"
---

# /obacht — security scan

Run the `obacht` CLI, parse its JSON output, and present a clean severity-grouped markdown report. obacht owns rule evaluation and the rule corpus (including the Claude Code policies CLD001-CLD041); this command only formats what the CLI returns and routes drill-down questions back to `obacht explain`.

## 1. Run the scan

One Bash call. Always force JSON; pass `$ARGUMENTS` through so callers can use `--severity`, `--category`, `--rule`, `--exclude-rule`, and `--show-passing`. If `$ARGUMENTS` already contains `--format`, strip it — JSON is required for rendering.

```sh
obacht --format=json scan $ARGUMENTS
```

Capture stdout, stderr, and exit code. Note whether `$ARGUMENTS` contained `--show-passing` (obacht itself ignores it under `--format=json`; the rendering layer below uses it).

## 2. If `obacht` is missing, print install advice and stop

Treat the binary as missing if **either**:
- exit code is `127`, or
- stderr contains `command not found` or `: not found`.

In that case, print this verbatim and stop:

```
obacht is not installed. Install it with one of:

  brew install foomo/tap/obacht
  go install github.com/foomo/obacht@latest
  mise x github:foomo/obacht -- obacht --format=json scan
```

## 3. Parse the JSON

The schema is:

```
{
  "schema_version": "1.0",
  "results": [
    {
      "rule_id": "...",
      "title": "...",
      "severity": "critical" | "high" | "warn" | "info",
      "category": "...",
      "status": "pass" | "fail" | "skip",
      "evidence": "...",       // present on failures and skips (skip evidence describes why)
      "remediation": "..."
    }
  ],
  "summary": {
    "total": N, "passed": N, "failed": N, "skipped": N, "errors": N,
    "critical": N, "high": N, "warn": N, "info": N
  }
}
```

If parsing fails (non-JSON output, malformed body), fall back to printing stdout verbatim inside a fenced block under the heading. Do not fabricate structured fields.

## 4. Render the report

Build the markdown report from the parsed JSON:

- `## obacht — Security Scan`
- **Status line.** When `summary.failed == 0` and `summary.skipped == 0`: `✓ All <total> checks passed`. Otherwise: `✗ <failed> of <total> checks failed (<n> critical, <n> high, <n> warn, <n> info)`, listing only severity buckets where the failing-results count for that severity is > 0. Append `, <n> skipped` to the parenthetical when `summary.skipped > 0`. Compute the failing-severity counts from `results` (filter `status == "fail"`) — the `summary` per-severity counts include passing checks too.
- **Failure sections** under `### Critical`, `### High`, `### Warn`, `### Info`, in that order. Skip empty buckets. Each finding is one bullet:
  ```
  - **<rule_id>** — <title>
      _<category>_
      Evidence: <evidence>     # only if evidence is non-empty
  ```
  Do not print `remediation` inline.
- **Skipped section.** If any result has `status == "skip"`, render `### Skipped (<n>)` with one bullet per skipped rule:
  ```
  - **<rule_id>** — <title> _(<severity>)_
      Reason: <evidence>
  ```
  Skipped rules typically indicate an environmental gap (a required tool isn't installed). They are not failures, but a critical check that did not run is meaningful information — never hide them.
- **Passing checks.**
  - If `$ARGUMENTS` contained `--show-passing`: render `### Passing (<passed>)` with one bullet per passing rule: `- **<rule_id>** — <title>`.
  - Otherwise: render a single line — ``<passed> passing checks hidden. Re-run with `/obacht --show-passing` to list them.``
- **Errors section.** If `summary.errors > 0`, render `### Errors` with one bullet per result whose status is none of `pass`/`fail`/`skip`. (Evaluation failures, not skips.)
- **Footer.** One sentence: `Ask "explain <rule-id>" or "how do I fix <rule-id>?" for the full remediation.`

Rule IDs, titles, severities, categories, evidence, and remediation strings must be copied **verbatim** from the JSON. Do not paraphrase, summarise, or invent fields.

## 5. Drill-down on request

When the user follows up by asking about a specific rule by ID, or asks how to fix / mitigate / explain a finding (e.g. "explain CLD035", "how do I fix ENV001?", "what does CRD002 mean?"), shell out to:

```sh
obacht explain <RULE_ID>
```

Print the CLI output verbatim inside a fenced block under a `### <rule-id> — <title>` heading. If the CLI returns `rule "<id>" not found`, surface that message to the user instead of guessing. Do not paraphrase, condense, or supplement the explanation with content not produced by the CLI.

## Do not

- Do not edit any settings file.
- Do not invent or interpret rules — the rule corpus lives inside the `obacht` binary.
- Do not invent findings, titles, severities, evidence, or remediations.
- Do not pass `--rules-dir` — the binary ships its own rules.
- Do not delegate to a sub-agent.
