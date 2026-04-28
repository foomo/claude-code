# superpowers

Foomo defaults on top of the upstream `superpowers` plugin from the `claude-plugins-official` marketplace.

## What it does

This plugin pulls in the official `superpowers` plugin from the `claude-plugins-official` marketplace as a dependency
(see `.claude-plugin/plugin.json`) and layers a foomo-specific storage rule on top. It does not override any upstream
skills — refer to the upstream plugin for the full skill list.

## Storage rule

Summary of [`rules/storage.md`](rules/storage.md):

- Specs go under `.claude/specs/`, plans under `.claude/plans/`.
- Do not place these files in `docs/` or the repository root — keep `docs/` for human-oriented documentation.
- Do not commit superpowers files — `.claude/` is gitignored.

## Install

```shell
/plugin marketplace add foomo/claude-code
/plugin install superpowers@foomo
```
