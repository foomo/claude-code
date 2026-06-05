---
name: gha
description: Auto-applies when writing, creating, or editing files under `.github/workflows/*.{yml,yaml}` or `.github/actions/**/action.yml`.
license: MIT
---

# GitHub Actions

## Version pinning

- use refs to pin third-party actions
- always include the releases-link comment line directly above the pinned `uses:` (matched indentation), and a `# <tag>`
  trailing comment with the concrete release tag

<details><summary>Reference</summary>

```yaml
# before
- uses: actions/checkout@v6
```

```yaml
# after
# https://github.com/actions/checkout/releases
- uses: actions/checkout@<sha> # v6.0.0
```

</details>

## Permissions

- use least privilege principles
- ensure that the permissions are only needed for the specific action

<details><summary>Reference</summary>

```yaml
# before
permissions:
  contents: write
```

```yaml
# after
permissions:
  contents: read

release:
  permissions:
    contents: write
    id-token: write
```

</details>
