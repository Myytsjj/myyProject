///|
fn post_layout() -> String {
  (
    #|<!doctype html>
    #|<html lang="en">
    #|<head>
    #|  <meta charset="utf-8">
    #|  <title>{{title}}</title>
    #|</head>
    #|<body>
    #|  <article>
    #|    <h1>{{title}}</h1>
    #|    <p class="date">{{date}}</p>
    #|    {{categories}}
    #|    <section class="content">{{content}}</section>
    #|    {{tags}}
    #|  </article>
    #|</body>
    #|</html>
  )
}

///|
fn index_layout() -> String {
  (
    #|<!doctype html>
    #|<html lang="en">
    #|<head>
    #|  <meta charset="utf-8">
    #|  <title>{{title}}</title>
    #|</head>
    #|<body>
    #|  <h1>{{title}}</h1>
    #|  {{posts}}
    #|  {{pagination}}
    #|</body>
    #|</html>
  )
}

///|
fn tag_layout() -> String {
  (
    #|<!doctype html>
    #|<html lang="en">
    #|<head><meta charset="utf-8"><title>Tag {{tag}}</title></head>
    #|<body><h1>Tag {{tag}}</h1>{{posts}}</body>
    #|</html>
  )
}

///|
fn category_layout() -> String {
  (
    #|<!doctype html>
    #|<html lang="en">
    #|<head><meta charset="utf-8"><title>Category {{category}}</title></head>
    #|<body><h1>Category {{category}}</h1>{{posts}}</body>
    #|</html>
  )
}

///|
fn page_source(
  title : String,
  date : String,
  tags : String,
  categories : String,
  body : String,
) -> String {
  "---\n" +
  "title: " +
  title +
  "\n" +
  "date: " +
  date +
  "\n" +
  "tags: [" +
  tags +
  "]\n" +
  "categories: [" +
  categories +
  "]\n" +
  "---\n" +
  body
}

///|
fn draft_source() -> String {
  (
    #|---
    #|title: Future Draft
    #|date: 2026-08-01
    #|draft: true
    #|tags: [Draft]
    #|categories: [Planning]
    #|---
    #|# Future Draft
    #|
    #|This draft should only appear when explicitly requested.
  )
}

///|
fn showcase_sources() -> Array[(String, String)] {
  [
    (
      "getting-started.md",
      page_source(
        "Getting Started", "2026-07-01", "MoonBit, Guide", "Docs", "# Getting Started\n\nInstall the toolchain and run `moon test`.",
      ),
    ),
    (
      "cli-reference.md",
      page_source(
        "CLI Reference", "2026-07-02", "CLI, Tooling", "Reference", "# CLI Reference\n\nUse `moon run src/main -- --help` for options.",
      ),
    ),
    (
      "markdown-pipeline.md",
      page_source(
        "Markdown Pipeline", "2026-07-03", "Markdown, Parser", "Architecture", "# Markdown Pipeline\n\nThe parser emits blocks, events, and HTML.",
      ),
    ),
    (
      "security-hardening.md",
      page_source(
        "Security Hardening", "2026-07-04", "Security, HTML", "Hardening", "# Security\n\nUnsafe links such as [bad](javascript:alert(1)) are blocked.",
      ),
    ),
    (
      "taxonomy-pages.md",
      page_source(
        "Taxonomy Pages", "2026-07-05", "Tags, Categories", "Features", "# Taxonomy\n\nTags and categories generate listing pages.",
      ),
    ),
    (
      "rss-search-sitemap.md",
      page_source(
        "RSS Search Sitemap", "2026-07-06", "RSS, Search, Sitemap", "Features", "# Feeds\n\nRSS, search JSON, and sitemap XML are generated together.",
      ),
    ),
    (
      "pagination.md",
      page_source(
        "Pagination", "2026-07-07", "Pagination, UX", "Features", "# Pagination\n\nIndex pages split posts using `posts_per_page`.",
      ),
    ),
    (
      "moonbit-targets.md",
      page_source(
        "MoonBit Targets", "2026-07-08", "MoonBit, CI", "Tooling", "# Targets\n\nThe project is checked against all MoonBit backends.",
      ),
    ),
    (
      "release-process.md",
      page_source(
        "Release Process", "2026-07-09", "Release, Mooncakes", "Governance", "# Release\n\nRun checks before publishing to Mooncakes.",
      ),
    ),
    ("future-draft.md", draft_source()),
  ]
}

///|
fn config() -> @ssg.Config {
  @ssg.Config::make(
    "Moon SSG Showcase", "A complete in-memory example site", "https://example.com/showcase",
    3, "content", "layouts", "public", "static",
  )
}

///|
fn generate_showcase(include_drafts : Bool) -> Array[@ssg.GeneratedPage] {
  @ssg.generate_site(
    showcase_sources(),
    post_layout(),
    index_layout(),
    tag_layout(),
    category_layout(),
    config(),
    include_drafts,
  )
}

///|
fn find_page(pages : Array[@ssg.GeneratedPage], path : String) -> String {
  for page in pages {
    if page.path == path {
      return page.html
    }
  }
  abort("missing page: " + path)
}

///|
fn assert_contains(label : String, text : String, expected : String) -> Unit {
  if !text.contains(expected) {
    abort(label + " missing expected fragment: " + expected)
  }
}

///|
fn assert_not_contains(label : String, text : String, blocked : String) -> Unit {
  if text.contains(blocked) {
    abort(label + " contained blocked fragment: " + blocked)
  }
}

///|
fn assert_page_exists(pages : Array[@ssg.GeneratedPage], path : String) -> Unit {
  ignore(find_page(pages, path))
}

///|
fn assert_page_missing(
  pages : Array[@ssg.GeneratedPage],
  path : String,
) -> Unit {
  for page in pages {
    if page.path == path {
      abort("unexpected page: " + path)
    }
  }
}

///|
fn validate_core_pages(pages : Array[@ssg.GeneratedPage]) -> Unit {
  assert_page_exists(pages, "getting-started.html")
  assert_page_exists(pages, "cli-reference.html")
  assert_page_exists(pages, "markdown-pipeline.html")
  assert_page_exists(pages, "security-hardening.html")
  assert_page_exists(pages, "taxonomy-pages.html")
  assert_page_exists(pages, "rss-search-sitemap.html")
  assert_page_exists(pages, "pagination.html")
  assert_page_exists(pages, "moonbit-targets.html")
  assert_page_exists(pages, "release-process.html")
  assert_page_exists(pages, "index.html")
  assert_page_exists(pages, "index2.html")
  assert_page_exists(pages, "index3.html")
  assert_page_exists(pages, "rss.xml")
  assert_page_exists(pages, "search.json")
  assert_page_exists(pages, "sitemap.xml")
}

///|
fn validate_taxonomies(pages : Array[@ssg.GeneratedPage]) -> Unit {
  assert_page_exists(pages, "tag-moonbit.html")
  assert_page_exists(pages, "tag-guide.html")
  assert_page_exists(pages, "tag-cli.html")
  assert_page_exists(pages, "tag-tooling.html")
  assert_page_exists(pages, "tag-markdown.html")
  assert_page_exists(pages, "tag-parser.html")
  assert_page_exists(pages, "tag-security.html")
  assert_page_exists(pages, "tag-html.html")
  assert_page_exists(pages, "tag-tags.html")
  assert_page_exists(pages, "tag-categories.html")
  assert_page_exists(pages, "tag-rss.html")
  assert_page_exists(pages, "tag-search.html")
  assert_page_exists(pages, "tag-sitemap.html")
  assert_page_exists(pages, "tag-pagination.html")
  assert_page_exists(pages, "tag-ux.html")
  assert_page_exists(pages, "tag-ci.html")
  assert_page_exists(pages, "tag-release.html")
  assert_page_exists(pages, "tag-mooncakes.html")
  assert_page_exists(pages, "category-docs.html")
  assert_page_exists(pages, "category-reference.html")
  assert_page_exists(pages, "category-architecture.html")
  assert_page_exists(pages, "category-hardening.html")
  assert_page_exists(pages, "category-features.html")
  assert_page_exists(pages, "category-tooling.html")
  assert_page_exists(pages, "category-governance.html")
}

///|
fn validate_security_output(pages : Array[@ssg.GeneratedPage]) -> Unit {
  let security = find_page(pages, "security-hardening.html")
  assert_contains("security page", security, "href=\"#unsafe-url\"")
  assert_not_contains("security page", security, "href=\"javascript:")
}

///|
fn validate_indexes(pages : Array[@ssg.GeneratedPage]) -> Unit {
  let index1 = find_page(pages, "index.html")
  let index2 = find_page(pages, "index2.html")
  let index3 = find_page(pages, "index3.html")
  assert_contains("index1", index1, "release-process.html")
  assert_contains("index1", index1, "moonbit-targets.html")
  assert_contains("index1", index1, "pagination.html")
  assert_contains("index2", index2, "rss-search-sitemap.html")
  assert_contains("index2", index2, "taxonomy-pages.html")
  assert_contains("index2", index2, "security-hardening.html")
  assert_contains("index3", index3, "markdown-pipeline.html")
  assert_contains("index3", index3, "cli-reference.html")
  assert_contains("index3", index3, "getting-started.html")
}

///|
fn validate_machine_indexes(pages : Array[@ssg.GeneratedPage]) -> Unit {
  let rss = find_page(pages, "rss.xml")
  let search = find_page(pages, "search.json")
  let sitemap = find_page(pages, "sitemap.xml")
  assert_contains(
    "rss", rss, "https://example.com/showcase/release-process.html",
  )
  assert_contains("rss", rss, "<generator>moon-ssg</generator>")
  assert_contains("search", search, "\"title\": \"Release Process\"")
  assert_contains("search", search, "\"url\": \"release-process.html\"")
  assert_contains(
    "sitemap", sitemap, "https://example.com/showcase/release-process.html",
  )
  assert_not_contains("sitemap", sitemap, "rss.xml")
  assert_not_contains("sitemap", sitemap, "search.json")
}

///|
fn validate_without_drafts(pages : Array[@ssg.GeneratedPage]) -> Unit {
  assert_page_missing(pages, "future-draft.html")
  let search = find_page(pages, "search.json")
  assert_not_contains("search", search, "Future Draft")
}

///|
fn validate_with_drafts(pages : Array[@ssg.GeneratedPage]) -> Unit {
  assert_page_exists(pages, "future-draft.html")
  let draft = find_page(pages, "future-draft.html")
  assert_contains("draft", draft, "This draft should only appear")
}

///|
fn report_pages(pages : Array[@ssg.GeneratedPage]) -> Unit {
  println("showcase generated pages: " + pages.length().to_string())
  println("sample post: release-process.html")
  println("sample taxonomy: tag-mooncakes.html")
  println("machine indexes: rss.xml, search.json, sitemap.xml")
}

///|
fn main {
  let pages = generate_showcase(false)
  validate_core_pages(pages)
  validate_taxonomies(pages)
  validate_security_output(pages)
  validate_indexes(pages)
  validate_machine_indexes(pages)
  validate_without_drafts(pages)

  let draft_pages = generate_showcase(true)
  validate_with_drafts(draft_pages)

  report_pages(pages)
}
