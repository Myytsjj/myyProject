# Changelog

## 0.3.1 - 2026-07-28

- Harden Markdown HTML rendering by escaping link, image, and code-language attributes.
- Replace unsafe `javascript:`, `vbscript:`, and `data:` link targets with `#unsafe-url`.
- Normalize generated post, tag, and category paths with stable ASCII slugs.
- Escape title, date, tag, and category template substitutions.
- Generate `sitemap.xml` alongside HTML pages, RSS, and search JSON.
- Add CLI `--help`, `--version`, directory override flags, and `--base-url`.
- Add acceptance verification script, example package, benchmark smoke package, and expanded tests.

## 0.3.0

- Added pagination, taxonomy pages, RSS, search JSON, stricter CI, and generated interface files.

## 0.2.0

- Added CLI site generation and Mooncakes packaging metadata.

## 0.1.0

- Initial Markdown parser, HTML renderer, and static site generation core.

