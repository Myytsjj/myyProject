# OSC2026 Acceptance Checklist

This checklist records the repository state expected before final submission.

## Required Commands

```bash
moon version --all
moon fmt --check
moon check --target all
moon check --deny-warn
moon build
moon test --target all
moon test --deny-warn
moon info
git diff --exit-code
moon run src/main -- --help
moon run examples/basic
moon run benchmarks/main
moon publish --dry-run
```

`moon info --deny-warn` is not supported by the MoonBit 0.10.4 toolchain used during this audit. Use `moon info` plus `git diff --exit-code` for the current stable workflow.

## Repository Criteria

- Source code is public on GitHub.
- GitLink mirror is synchronized intentionally after final validation.
- README contains project scope, install, build, test, CLI, API, examples, architecture, performance notes, Mooncakes install, contribution, release, license, references, and acknowledgements.
- CI covers format, check, build, tests, and interface generation.
- Mooncakes package version matches `moon.mod` before release.
- Tags and GitHub Releases are created only after validation.
- License is OSI-approved and third-party references are documented.

## Current Known Release Notes

- `0.3.0` already exists on Mooncakes, so this remediation uses `0.3.1` for the next publishable version.
- Publishing requires safe Mooncakes credentials. Do not paste tokens or passwords into chat.
- GitLink credentials pasted earlier should be rotated before any push.

