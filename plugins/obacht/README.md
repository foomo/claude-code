# obacht

Runs the [`obacht`](https://github.com/foomo/obacht) security scanner and presents the results as a severity-grouped report. obacht audits the local developer environment — credentials, SSH/GPG, Docker/Kubernetes, shell history, OS hardening, and the full Claude Code policy set (CLD001-CLD041) — against rules embedded in the binary.

The plugin is presentation-only: rule evaluation, evidence collection, and remediation text are owned by the CLI.

## Prerequisites

The `obacht` CLI must be installed. Pick one:

```shell
# Homebrew
brew install foomo/tap/obacht

# Go toolchain
go install github.com/foomo/obacht@latest

# mise (ephemeral, no install)
mise x github:foomo/obacht -- obacht --format=json scan
```

Verify with `obacht --version`.

## Install

```shell
/plugin marketplace add foomo/claude-code
/plugin install obacht@foomo
```

## Usage

Run the scan from inside Claude Code:

```
/obacht
```

The report shows failing checks grouped by severity (Critical → High → Warn → Info). Passing checks are hidden behind a count; pass `--show-passing` to list them. All other flags pass through to `obacht scan`:

```
/obacht --severity high,critical
/obacht --category git,ssh
/obacht --rule CLD035,ENV001
/obacht --exclude-rule CLD041
/obacht --show-passing
```

## Drill into a finding

After the scan prints the punch list, ask in chat for the full remediation:

```
explain CLD035
how do I fix ENV001?
what does CRD002 check?
```

Claude shells out to `obacht explain <rule-id>` and prints the binary's explanation verbatim — no paraphrasing, no fabricated steps.

## What this plugin does not do

- It does not edit any settings file.
- It does not interpret, summarise, or invent rules — the rule corpus lives inside the `obacht` binary; run `obacht explain <rule-id>` directly to read a rule outside Claude Code.
- It does not delegate to a sub-agent.
