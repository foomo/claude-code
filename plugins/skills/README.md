# skills

Common shared skills for everyday Claude Code workflows at foomo.

## What it does

Bundles skills that automate repetitive repo hygiene and PR work. Most are user-invocable via `/skills:<name>`; `gha`
is model-invoked and auto-applies while Claude edits GitHub Actions files. Each skill is self-contained and ships
under `skills/<name>/SKILL.md`.

| Skill                                              | Trigger                  | Purpose                                                                                                                                    |
|----------------------------------------------------|--------------------------|--------------------------------------------------------------------------------------------------------------------------------------------|
| [`gha`](skills/gha/SKILL.md)                       | _auto (model-invoked)_   | Auto-enforces least-privilege `permissions:` and SHA-pinned `uses:` rules whenever editing `.github/workflows/*.yml` or composite actions. |
| [`pr-description`](skills/pr-description/SKILL.md) | `/skills:pr-description` | Generate a pull request description by detecting the repo's PR template and filling sections from the current branch's commits and diff.   |

## Install

```shell
/plugin marketplace add foomo/claude-code
/plugin install skills@foomo
```

## Usage

Skills auto-trigger from natural-language phrases listed in each `SKILL.md`, or invoke them explicitly:

```
/skills:pr-description
```

`gha` is not user-invocable — it triggers automatically when Claude edits files under `.github/workflows/` or
`.github/actions/`.
