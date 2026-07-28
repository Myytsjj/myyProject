///|
fn test_config(posts_per_page : Int) -> Config {
  Config::make(
    "Moon SSG Acceptance", "Regression coverage for the MoonBit static site generator",
    "https://example.com/docs", posts_per_page, "content", "layouts", "public", "static",
  )
}

///|
fn post_layout_fixture() -> String {
  (
    #|<html>
    #|<head><title>{{title}}</title></head>
    #|<body>
    #|<article>
    #|<h1>{{title}}</h1>
    #|<time>{{date}}</time>
    #|{{categories}}
    #|<main>{{content}}</main>
    #|{{tags}}
    #|</article>
    #|</body>
    #|</html>
  )
}

///|
fn index_layout_fixture() -> String {
  (
    #|<html>
    #|<head><title>{{title}}</title></head>
    #|<body>
    #|<nav>{{pagination}}</nav>
    #|<section>{{posts}}</section>
    #|</body>
    #|</html>
  )
}

///|
fn tag_layout_fixture() -> String {
  (
    #|<html>
    #|<body>
    #|<h1>Tag {{tag}}</h1>
    #|{{posts}}
    #|</body>
    #|</html>
  )
}

///|
fn category_layout_fixture() -> String {
  (
    #|<html>
    #|<body>
    #|<h1>Category {{category}}</h1>
    #|{{posts}}
    #|</body>
    #|</html>
  )
}

///|
fn acceptance_sources() -> Array[(String, String)] {
  [
    (
      "01 Getting Started.md",
      (
        #|---
        #|title: Getting Started
        #|date: 2026-07-01
        #|tags: [MoonBit, Guide]
        #|categories: [Docs]
        #|---
        #|# Getting Started
        #|
        #|Install MoonBit, clone the repository, and run `moon test`.
      ),
    ),
    (
      "02 CLI & Build.md",
      (
        #|---
        #|title: CLI & Build
        #|date: 2026-07-02
        #|tags:
        #|  - CLI
        #|  - Build
        #|categories:
        #|  - Docs
        #|  - Tooling
        #|---
        #|# CLI
        #|
        #|Use `moon run src/main -- --help` to inspect commands.
      ),
    ),
    (
      "03 Security Notes.md",
      (
        #|---
        #|title: Security <Notes>
        #|date: 2026-07-03
        #|tags: [Security, HTML]
        #|categories: [Hardening]
        #|---
        #|# Security
        #|
        #|Links like [bad](javascript:alert(1)) must be blocked.
      ),
    ),
    (
      "04 Search Index.md",
      (
        #|---
        #|title: Search Index
        #|date: 2026-07-04
        #|tags: [Search, JSON]
        #|categories: [Features]
        #|---
        #|# Search
        #|
        #|Search snippets strip HTML tags and escape JSON strings.
      ),
    ),
    (
      "05 Draft Plan.md",
      (
        #|---
        #|title: Draft Plan
        #|date: 2026-07-05
        #|draft: true
        #|tags: [Draft]
        #|categories: [Planning]
        #|---
        #|# Draft
        #|
        #|This page is hidden unless drafts are included.
      ),
    ),
  ]
}

///|
fn generated_pages(
  include_drafts : Bool,
  posts_per_page : Int,
) -> Array[GeneratedPage] {
  generate_site(
    acceptance_sources(),
    post_layout_fixture(),
    index_layout_fixture(),
    tag_layout_fixture(),
    category_layout_fixture(),
    test_config(posts_per_page),
    include_drafts,
  )
}

///|
fn find_page_html(pages : Array[GeneratedPage], path : String) -> String {
  for page in pages {
    if page.path == path {
      return page.html
    }
  }
  abort("missing generated page: " + path)
}

///|
fn assert_page_exists(pages : Array[GeneratedPage], path : String) -> Unit {
  ignore(find_page_html(pages, path))
}

///|
fn assert_page_missing(pages : Array[GeneratedPage], path : String) -> Unit {
  for page in pages {
    if page.path == path {
      abort("unexpected generated page: " + path)
    }
  }
}

///|
fn assert_html_contains(
  page_name : String,
  html : String,
  expected : String,
) -> Unit {
  if !html.contains(expected) {
    abort(
      page_name +
      " did not contain expected fragment:\nexpected: " +
      expected +
      "\nactual:\n" +
      html,
    )
  }
}

///|
fn assert_html_not_contains(
  page_name : String,
  html : String,
  blocked : String,
) -> Unit {
  if html.contains(blocked) {
    abort(
      page_name +
      " contained blocked fragment:\nblocked: " +
      blocked +
      "\nactual:\n" +
      html,
    )
  }
}

///|
test "ssg generates stable page paths and core artifacts" {
  let pages = generated_pages(false, 2)
  assert_page_exists(pages, "01-getting-started.html")
  assert_page_exists(pages, "02-cli-build.html")
  assert_page_exists(pages, "03-security-notes.html")
  assert_page_exists(pages, "04-search-index.html")
  assert_page_exists(pages, "index.html")
  assert_page_exists(pages, "index2.html")
  assert_page_exists(pages, "rss.xml")
  assert_page_exists(pages, "search.json")
  assert_page_exists(pages, "sitemap.xml")
  assert_page_missing(pages, "05-draft-plan.html")
}

///|
test "ssg excludes drafts by default and includes them on request" {
  let without_drafts = generated_pages(false, 2)
  assert_page_missing(without_drafts, "05-draft-plan.html")
  let with_drafts = generated_pages(true, 2)
  assert_page_exists(with_drafts, "05-draft-plan.html")
  let draft_html = find_page_html(with_drafts, "05-draft-plan.html")
  assert_html_contains("draft page", draft_html, "This page is hidden")
}

///|
test "ssg escapes title date taxonomy text in templates" {
  let pages = generated_pages(false, 2)
  let security_html = find_page_html(pages, "03-security-notes.html")
  assert_html_contains(
    "security page", security_html, "<title>Security &lt;Notes&gt;</title>",
  )
  assert_html_contains(
    "security page", security_html, "<h1>Security &lt;Notes&gt;</h1>",
  )
  assert_html_contains("security page", security_html, "href=\"#unsafe-url\"")
  assert_html_not_contains("security page", security_html, "href=\"javascript:")
}

///|
test "ssg taxonomy pages use slugified paths and escaped display names" {
  let pages = generated_pages(false, 2)
  assert_page_exists(pages, "tag-moonbit.html")
  assert_page_exists(pages, "tag-guide.html")
  assert_page_exists(pages, "tag-cli.html")
  assert_page_exists(pages, "tag-build.html")
  assert_page_exists(pages, "tag-security.html")
  assert_page_exists(pages, "tag-html.html")
  assert_page_exists(pages, "category-docs.html")
  assert_page_exists(pages, "category-tooling.html")
  assert_page_exists(pages, "category-hardening.html")
  let html_tag = find_page_html(pages, "tag-html.html")
  assert_html_contains("html tag page", html_tag, "<h1>Tag HTML</h1>")
  assert_html_contains("html tag page", html_tag, "03-security-notes.html")
}

///|
test "ssg pagination sorts newest first and links both directions" {
  let pages = generated_pages(false, 2)
  let index1 = find_page_html(pages, "index.html")
  let index2 = find_page_html(pages, "index2.html")
  assert_html_contains("index page 1", index1, "04-search-index.html")
  assert_html_contains("index page 1", index1, "03-security-notes.html")
  assert_html_contains("index page 1", index1, "Next")
  assert_html_contains("index page 2", index2, "02-cli-build.html")
  assert_html_contains("index page 2", index2, "01-getting-started.html")
  assert_html_contains("index page 2", index2, "Previous")
}

///|
test "ssg rss uses absolute escaped links and latest posts" {
  let pages = generated_pages(false, 2)
  let rss = find_page_html(pages, "rss.xml")
  assert_html_contains("rss", rss, "<title>Moon SSG Acceptance</title>")
  assert_html_contains(
    "rss", rss, "https://example.com/docs/04-search-index.html",
  )
  assert_html_contains(
    "rss", rss, "https://example.com/docs/03-security-notes.html",
  )
  assert_html_not_contains("rss", rss, "05-draft-plan.html")
  assert_html_contains("rss", rss, "&lt;Notes&gt;")
}

///|
test "ssg search json escapes strings and strips html tags" {
  let pages = generated_pages(false, 2)
  let search = find_page_html(pages, "search.json")
  assert_html_contains("search", search, "\"title\": \"Search Index\"")
  assert_html_contains("search", search, "\"url\": \"04-search-index.html\"")
  assert_html_contains("search", search, "Search snippets strip HTML")
  assert_html_not_contains("search", search, "<h1>")
  assert_html_not_contains("search", search, "05-draft-plan.html")
}

///|
test "ssg sitemap only includes html pages and joins base url" {
  let pages = generated_pages(false, 2)
  let sitemap = find_page_html(pages, "sitemap.xml")
  assert_html_contains(
    "sitemap", sitemap, "<loc>https://example.com/docs/index.html</loc>",
  )
  assert_html_contains(
    "sitemap", sitemap, "<loc>https://example.com/docs/04-search-index.html</loc>",
  )
  assert_html_not_contains("sitemap", sitemap, "rss.xml")
  assert_html_not_contains("sitemap", sitemap, "search.json")
}

///|
test "ssg slugify path normalizes edge cases" {
  assert_eq(slugify_path("Hello MoonBit.md"), "hello-moonbit-md")
  assert_eq(slugify_path("  Multiple   Spaces  "), "multiple-spaces")
  assert_eq(slugify_path("../escape<script>"), "escape-script")
  assert_eq(slugify_path("中文"), "untitled")
  assert_eq(slugify_path("MoonBit_0.10.4"), "moonbit-0-10-4")
  assert_eq(slugify_path("A---B"), "a-b")
}

///|
test "front matter parser preserves raw metadata and list forms" {
  let source =
    #|---
    #|title: Metadata Test
    #|date: 2026-07-28
    #|draft: false
    #|author: MoonBit Team
    #|summary: Uses colon: safely after first separator
    #|tags: alpha, beta, gamma
    #|categories:
    #|  - Docs
    #|  - Tests
    #|---
    #|Body
  let (meta, body) = parse_front_matter(source)
  assert_eq(meta.title, "Metadata Test")
  assert_eq(meta.date, "2026-07-28")
  assert_false(meta.draft)
  assert_eq(meta.tags, ["alpha", "beta", "gamma"])
  assert_eq(meta.categories, ["Docs", "Tests"])
  assert_eq(meta.raw["author"], "MoonBit Team")
  assert_eq(meta.raw["summary"], "Uses colon: safely after first separator")
  assert_eq(body.trim(), "Body")
}
