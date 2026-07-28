# Contributing

`moon-ssg` is a MoonBit static site generator. Contributions should keep the project buildable, reproducible, and honest about provenance.

## Local Setup

Install the current stable MoonBit toolchain, then run:

```bash
moon version --all
moon update
moon fmt --check
moon check --target all
moon build
moon test --target all
moon info
```

On Windows you can run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\verify_acceptance.ps1 -SkipPublishDryRun
```

## Development Rules

- Keep MoonBit packages small and cohesive.
- Add tests before behavior changes.
- Do not add generated `_build`, `.moon`, `.mooncakes`, `public`, or local config output.
- Do not fabricate benchmark, CI, Mooncakes, GitHub, or GitLink results.
- Update `pkg.generated.mbti` with `moon info` when public APIs change.
- Update `CHANGELOG.md` for user-visible changes.

## Release Checklist

1. Bump `moon.mod` version.
2. Run `scripts\verify_acceptance.ps1`.
3. Confirm `moon publish --dry-run` succeeds, or document the exact server response.
4. Create a Git tag only after checks pass.
5. Publish to Mooncakes only with a new version and safe credentials.
6. Sync GitHub and GitLink without rewriting real history to fabricate contributors.

