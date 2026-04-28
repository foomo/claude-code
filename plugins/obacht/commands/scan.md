---
description: Audit Claude Code settings for security risks and report a severity-grouped punch list.
argument-hint: "[obacht scan flags]"
---

# /obacht — settings security audit

This command shells out to the `obacht` CLI and prints its output **verbatim**. The CLI owns rule evaluation and renders its own header. Do not summarize, reformat, or annotate the output.

## 1. Check that `obacht` is installed

Run exactly **one** Bash call:

```sh
if ! command -v obacht >/dev/null 2>&1; then
  cat <<'EOF'
obacht is not installed. Install it with one of:

  brew install foomo/tap/obacht
  go install github.com/foomo/obacht@latest
  mise x github:foomo/obacht -- obacht scan --rules-dir "$CLAUDE_PLUGIN_ROOT/data"

EOF
  exit 127
fi
```

If the call exits non-zero, print its stdout verbatim and stop. Do not attempt the scan.

## 2. Run the scan

Run exactly **one** Bash call, forwarding `$ARGUMENTS` so callers can pass flags like `--severity high` or `--format json`:

```sh
obacht scan --rules-dir "${CLAUDE_PLUGIN_ROOT}/data" $ARGUMENTS
```

## 3. Print the result

Return obacht's output **verbatim** as the command's response. Do not add commentary, headers, or footers around it.

## Do not

- Do not edit any settings file.
- Do not invent or interpret rules — the rule set lives in `${CLAUDE_PLUGIN_ROOT}/data` and is evaluated by the `obacht` binary.
- Do not summarise findings beyond what `obacht` prints.
- Do not delegate to a sub-agent.
