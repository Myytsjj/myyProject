# moon-ssg

`moon-ssg` is a MoonBit-native static site generator for small documentation sites and personal blogs. It includes a Markdown parser, HTML renderer, front matter parser, taxonomy pages, pagination, RSS, search JSON, sitemap generation, and a filesystem CLI.

The project is designed for the MoonBit OSC2026 open-source track: buildable, reproducible, testable across MoonBit targets, and useful as a compact SSG foundation for the MoonBit ecosystem.

## Scope

`moon-ssg` supports:

- Markdown headings, paragraphs, thematic breaks, blockquotes, unordered/ordered lists, fenced code blocks, emphasis, strong text, code spans, links, and images.
- Front matter fields: `title`, `date`, `draft`, `tags`, `categories`, plus raw metadata retention.
- HTML output with escaped text, escaped attributes, unsafe URL scheme blocking, and slugified output paths.
- Blog index pagination, tag pages, category pages, RSS 2.0, `search.json`, and `sitemap.xml`.
- CLI generation from `content/`, `layouts/`, and `static/` into `public/`.

Non-goals for the current release:

- Full CommonMark compliance.
- Theme engines with arbitrary template expressions.
- Incremental builds and file watching.
- Remote deployment.

## Install

Install MoonBit from the official installer, then check the toolchain:

```bash
moon version --all
moon update
```

Use the current published package from Mooncakes:

```bash
moon add Myytsjj/moon-ssg@0.3.0
```

This repository checkout prepares `0.3.1` as the next publishable version. After it is released to Mooncakes, use `moon add Myytsjj/moon-ssg@0.3.1`.

## Build And Test

```bash
git clone https://github.com/Myytsjj/moon-ssg.git
cd moon-ssg

moon fmt --check
moon check --target all
moon check --deny-warn
moon build
moon test --target all
moon test --deny-warn
moon info
git diff --exit-code
```

Current MoonBit 0.10.4 does not support `moon info --deny-warn`; use `moon info` and `git diff --exit-code`.

## Quick Start

Run the CLI:

```bash
moon run src/main
```

First run creates `ssg.config.json`, default content, layouts, and static CSS when missing. Output goes to `public/`.

Useful flags:

```bash
moon run src/main -- --help
moon run src/main -- --version
moon run src/main -- --drafts
moon run src/main -- --config site.json
moon run src/main -- --content posts --layouts templates --public dist --static assets
moon run src/main -- --base-url https://example.com/blog
```

## Library API

The pure generator API lives in `src/ssg`:

```moonbit
import {
  "Myytsjj/moon-ssg/src/ssg"
}

fn main {
  let markdown_source = "# Hello MoonBit\n\nThis is a generated page."
  let post_layout = "<article><h1>{{title}}</h1>{{content}}</article>"
  let index_layout = "<main>{{posts}}{{pagination}}</main>"
  let tag_layout = "<section><h1>{{tag}}</h1>{{posts}}</section>"
  let category_layout = "<section><h1>{{category}}</h1>{{posts}}</section>"
  let config = @ssg.Config::make(
    "Example Site", "Description", "https://example.com", 10,
    "content", "layouts", "public", "static",
  )
  let pages = @ssg.generate_site(
    [("hello moonbit.md", markdown_source)],
    post_layout,
    index_layout,
    tag_layout,
    category_layout,
    config,
    false,
  )
  println("generated pages: " + pages.length().to_string())
}
```

The Markdown package can also be used directly:

```moonbit
let parser = @markdown.Parser::new("# Hello")
let html = @markdown.render_html(@markdown.to_events(parser.parse()))
```

## Examples

Run the pure API example:

```bash
moon run examples/basic
```

Run the full in-memory showcase with built-in output assertions:

```bash
moon run examples/showcase
```

Run the multi-configuration matrix example:

```bash
moon run examples/matrix
```

Run the benchmark smoke workload:

```bash
moon run benchmarks/main
```

The benchmark is a reproducible smoke test, not a formal performance claim. Use it to ensure the generator handles a larger in-memory source set.

## Architecture

- `src/markdown`: Markdown AST, inline parser, block parser, event conversion, and HTML renderer.
- `src/ssg`: front matter parsing, post model, page generation, pagination, taxonomy pages, RSS, search JSON, sitemap, slugging, and output escaping.
- `src/main`: filesystem CLI and argument parsing.
- `examples/basic`: minimal downstream usage of the pure API.
- `benchmarks/main`: repeatable generator workload for sanity checks.
- `scripts/verify_acceptance.ps1`: local acceptance command runner.

The core generator is pure: it maps `(filename, markdown source)` inputs plus templates into generated pages. Filesystem work is isolated in the CLI.

## CI

GitHub Actions runs on Linux, macOS, and Windows:

- `moon version --all`
- `moon update`
- `moon fmt --check`
- `moon check --target all`
- `moon check --deny-warn`
- `moon build`
- `moon test --target all`
- `moon test --deny-warn`
- `moon info`
- `git diff --exit-code`

Publishing is intentionally not part of pull-request CI because it requires a Mooncakes credential.
The repository also contains a manual `workflow_dispatch` publishing workflow. Configure
`MOONCAKES_MOONBIT_COMMUNITY_TOKEN` as a GitHub Actions secret before using it.

## Acceptance Self-Check

On Windows:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\verify_acceptance.ps1 -SkipPublishDryRun
```

For release preparation, omit `-SkipPublishDryRun`:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\verify_acceptance.ps1
```

See `docs/acceptance-checklist.md` for the full checklist.

## Release

1. Update `moon.mod` version and `CHANGELOG.md`.
2. Run the acceptance script.
3. Confirm `moon publish --dry-run`.
4. Create a tag and GitHub Release only after checks pass.
5. Publish to Mooncakes only with safe credentials.
6. Sync GitHub and GitLink intentionally.

Do not rewrite real history to fabricate contributors, test results, CI, benchmarks, or release state.

## License

MIT. See `LICENSE`.

## References And Acknowledgements

This project is original MoonBit implementation work. It references CommonMark, Zola, Hugo, and MoonBit `moonbitlang/x` at the design/API level described in `THIRD_PARTY_NOTICES.md`.

Thanks to the MoonBit project and community workflow templates for the build and packaging practices used by this repository.
