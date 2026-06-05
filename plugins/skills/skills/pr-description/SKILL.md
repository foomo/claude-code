---
name: pr-description
description: >
  Generate a short PR description using local templates (GitHub/Azure DevOps).
  Populate headings and tick checkboxes based on branch commits and diffs.
  Keep unchecked boxes. Remove headings that remain empty after clearing placeholders.
argument-hint: "[--template ] [--base ] [--out ]"
allowed-tools:
  Read, Bash(git log:, git diff:, git rev-parse:, git merge-base:, git status:)
disable-model-invocation: true
user-invocable: true
license: MIT
---

# PR Description Generator

Generate a pull request description matching the repository's template, populated by branch context, with empty sections removed.

## Rules

1. Follow Comment Instructions: Read and strictly adhere to any hidden HTML comments or instructional text within template sections to guide content generation.
2. Checkbox Ticking: Convert `- [ ]` to `- [x]` if branch commits or diffs provide supporting evidence. Never delete unchecked boxes.
3. Prune Empty Headings: Delete any heading where the content consists only of empty space or HTML placeholder comments.
