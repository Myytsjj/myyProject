# Third-Party Notices

`moon-ssg` is implemented in MoonBit and does not vendor third-party parser or static-site-generator source code.

## References

| Project / Specification | Source | License | Reference Scope |
| --- | --- | --- | --- |
| [CommonMark Specification](https://spec.commonmark.org/current/) | https://spec.commonmark.org/current/ | Specification text | Markdown block and inline behavior was used as a syntax reference. No source code was copied. |
| [Zola](https://github.com/getzola/zola) | https://github.com/getzola/zola | MIT | Project structure and front matter concepts were studied at a design level. No source code was copied or ported. |
| [Hugo](https://github.com/gohugoio/hugo) | https://github.com/gohugoio/hugo | Apache-2.0 | Content/layout/static/public directory conventions and taxonomy concepts were studied at a design level. No source code was copied or ported. |
| [MoonBit `moonbitlang/x`](https://github.com/moonbitlang/x) | https://github.com/moonbitlang/x | Apache-2.0 | Runtime dependency declared in `moon.mod`, used for filesystem support in the CLI. |

## Originality Boundary

The Markdown parser, renderer, front matter parser, path slugging, RSS/search/sitemap output, examples, tests, and CLI code in this repository are original MoonBit implementation work for this project.

If future changes copy, port, embed, or adapt third-party code beyond design-level study, this file and the license compatibility analysis must be updated in the same change.
