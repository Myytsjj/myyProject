# Moon-ssg Proposal

- Participant: Myytsjj
- GitHub: https://github.com/Myytsjj/moon-ssg
- GitLink: https://gitlink.org.cn/Myyafa/moon-ssg
- Direction: MoonBit static-site and documentation tooling
- Type: Original MoonBit implementation

`moon-ssg` is a reusable Markdown-to-HTML and static-site generator core for small documentation sites and personal blogs. It targets MoonBit developers who need a buildable, cross-target site generator without a JavaScript runtime.

The delivered scope includes Markdown parsing and HTML rendering, front matter, escaped output, slugged post and taxonomy paths, pagination, draft filtering, RSS, search JSON, sitemap generation, a filesystem CLI, examples, tests, and benchmark smoke coverage.

The implementation is organized into Markdown AST/parser/renderer, a pure SSG generator, and a filesystem CLI. The current release intentionally does not claim full CommonMark compliance, arbitrary template expressions, incremental builds, file watching, or remote deployment.

The project is original MoonBit code. CommonMark, Zola, Hugo, and `moonbitlang/x` are documented as syntax, design, or dependency references in `THIRD_PARTY_NOTICES.md`; no third-party parser or SSG source is copied.

Expected deliverables are the public GitHub and GitLink repositories, reproducible MoonBit checks, runnable examples, a MIT license, and a Mooncakes package release after final validation.
