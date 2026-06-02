# superpowers

Foomo defaults on top of the upstream `superpowers` plugin from the `claude-plugins-official` marketplace.

## What it does

This plugin pulls in the official `superpowers` plugin from the `claude-plugins-official` marketplace as a dependency
(see `.claude-plugin/plugin.json`) and layers foomo-specific overrides on top via [`CLAUDE.md`](CLAUDE.md). It does not
shadow any upstream skills — refer to the upstream plugin for the full skill list.

## Overrides

See [`CLAUDE.md`](CLAUDE.md) for the always-on rules. Summary:

- **Storage paths** — specs go under `.claude/specs/`, plans under `.claude/plans/`. Never `docs/` or the repository
  root. `.claude/` is gitignored; treat these files as ephemeral.
- **Git handoff** — never run `git commit` / `git push` (or any git write). Print the exact commands and let the user
  run them.

## Install

```shell
/plugin marketplace add foomo/claude-code
/plugin install superpowers@foomo
```
