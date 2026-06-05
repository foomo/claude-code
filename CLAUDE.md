# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code **marketplace** (`.claude-plugin/marketplace.json`) bundling three plugins. Each plugin is self-contained under `plugins/<name>/` with its own `.claude-plugin/plugin.json`. Distribution is via:

```
/plugin marketplace add foomo/claude-code
/plugin install <plugin>@foomo
```

The marketplace declares cross-marketplace dependencies on `claude-plugins-official` (used by `superpowers`).

## Commands

```shell
make help        # ASCII-art banner + task list
make lint        # rumdl check . (markdown lint, repo-wide)
make lint.fix    # rumdl check --fix .
```

## Eval workspaces

Skill evaluations related files (fixtures, run outputs, grading, benchmarks, skill snapshots) live under:

```
.claude/workspaces/<plugin-name>/<skill-name>/
```
