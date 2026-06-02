# foomo superpowers overrides

This plugin layers two always-on rules on top of the upstream
`claude-plugins-official/superpowers` plugin. They override upstream
defaults wherever the two conflict.

## Storage paths

Write superpowers specs and plans under `.claude/`, never under
`docs/` or the repository root.

- Specs → `.claude/specs/`
- Plans → `.claude/plans/`

This supersedes the upstream `writing-plans` default of
`docs/superpowers/plans/YYYY-MM-DD-<feature>.md`. `docs/` is reserved
for human-authored documentation.

`.claude/` is gitignored. Treat these files as ephemeral session
artifacts. Do not commit them.

## Git handoff

Never run `git commit` or `git push` yourself. Never stage files
unless the user explicitly asks.

When a change is ready to land — including the wrap-up steps of
upstream skills like `finishing-a-development-branch`,
`requesting-code-review`, or `executing-plans` — print the exact
commands (`git add …`, `git commit -m …`, `git push …`) and stop.
The user runs them.

This applies to every git write operation: tag, branch delete,
force-push, PR merge. Print, don't execute.
