[![GitHub License](https://img.shields.io/github/license/foomo/claude-code?style=flat-square)](https://github.com/foomo/claude-code/blob/main/LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/foomo/claude-code.svg?style=flat-square&logo=github)](https://github.com/foomo/claude-code)

<p align="center">
  <img alt="obacht" src="docs/public/logo.png" width="400" height="400"/>
</p>

# Claude Code

> Claude Code marketplace

## Plugins

- [`obacht`](plugins/obacht) — runs the `obacht` security scanner and presents results as a severity-grouped report
- [`skills`](plugins/skills) — common shared skills (GitHub Actions hardening, PR descriptions)
- [`superpowers`](plugins/superpowers) — foomo defaults layered on top of the upstream `superpowers` plugin

## Installation

```shell
/plugin marketplace add foomo/claude-code
/plugin install obacht@foomo
/plugin install skills@foomo
/plugin install superpowers@foomo
```

## How to Contribute

Contributions are welcome! Open an issue or pull request.

![Contributors](https://contributors-table.vercel.app/image?repo=foomo/claude-code&width=50&columns=15)

## License

Distributed under MIT License, please see license file within the code for more details.

_Made with ♥ [foomo](https://www.foomo.org) by [bestbytes](https://www.bestbytes.com)_
