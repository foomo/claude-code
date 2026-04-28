---
description: Audit Claude Code settings for security risks and report a severity-grouped punch list.
argument-hint: "[obacht scan flags]"
---

# /obacht — settings security audit

Run the `obacht` CLI and present its result as a clean, severity-grouped markdown report. The CLI owns rule evaluation; Claude only formats what it returns.

## 1. Run the scan

One Bash call. Pass `$ARGUMENTS` through so callers can use `--severity`, `--rule`, `--category`, `--format json`, etc.

```sh
obacht scan --rules-dir "${CLAUDE_PLUGIN_ROOT}/data" $ARGUMENTS
```

Capture stdout, stderr, and exit code from the bash result.

## 2. If `obacht` is missing, print install advice and stop

Treat the binary as missing if **either**:
- exit code is `127`, or
- stderr contains `command not found` or `: not found`.

In that case, print this verbatim and stop:

```
obacht is not installed. Install it with one of:

  brew install foomo/tap/obacht
  go install github.com/foomo/obacht@latest
  mise x github:foomo/obacht -- obacht scan --rules-dir "$CLAUDE_PLUGIN_ROOT/data"
```

## 3. Render the result as markdown

Read obacht's output and present it as:

- `## obacht — Claude Code Security Scan`
- A **Status** line: `✓ No issues found` when obacht reports no failures; otherwise a one-line summary of the failure count and severity breakdown taken straight from obacht's output.
- Findings grouped under `### Critical`, `### High`, `### Warn`, `### Info` (in that order). One bullet per finding showing rule ID, title, and remediation. Skip empty sections.
- If obacht reports rule evaluation errors (rules that didn't run cleanly), list them under a final `### Errors` section.

Rule IDs, titles, severities, and remediations must be copied **verbatim** from obacht's output. Do not paraphrase, summarise, or invent fields. If obacht's format is unfamiliar and you can't confidently parse a field, fall back to printing its stdout in a fenced block under the heading rather than fabricating structure.

If the caller passed `--format json`, obacht returns JSON; render the same markdown report from the JSON fields with the same verbatim rule.

## Do not

- Do not edit any settings file.
- Do not invent or interpret rules — the rule set lives in `${CLAUDE_PLUGIN_ROOT}/data` and is evaluated by the `obacht` binary.
- Do not invent findings, titles, severities, or remediations.
- Do not delegate to a sub-agent.
