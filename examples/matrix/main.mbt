///|
struct Scenario {
  name : String
  posts_per_page : Int
  include_drafts : Bool
  base_url : String
  expected_indexes : Int
  expected_draft : Bool
} derive(Debug, Eq)

///|
fn post_layout() -> String {
  "<article><h1>{{title}}</h1><time>{{date}}</time>{{content}}{{tags}}{{categories}}</article>"
}

///|
fn index_layout() -> String {
  "<main><h1>{{title}}</h1>{{posts}}{{pagination}}</main>"
}

///|
fn tag_layout() -> String {
  "<section><h1>{{tag}}</h1>{{posts}}</section>"
}

///|
fn category_layout() -> String {
  "<section><h1>{{category}}</h1>{{posts}}</section>"
}

///|
fn config(scenario : Scenario) -> @ssg.Config {
  @ssg.Config::make(
    "Matrix " + scenario.name,
    "Scenario matrix for moon-ssg",
    scenario.base_url,
    scenario.posts_per_page,
    "content",
    "layouts",
    "public",
    "static",
  )
}

///|
fn source(
  title : String,
  date : String,
  tags : String,
  categories : String,
  draft : Bool,
  body : String,
) -> String {
  "---\n" +
  "title: " +
  title +
  "\n" +
  "date: " +
  date +
  "\n" +
  "draft: " +
  (if draft { "true" } else { "false" }) +
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
fn sources() -> Array[(String, String)] {
  [
    (
      "alpha.md",
      source(
        "Alpha", "2026-07-01", "MoonBit, Alpha", "Docs", false, "# Alpha\n\nAlpha body with **strong** text.",
      ),
    ),
    (
      "beta.md",
      source(
        "Beta", "2026-07-02", "MoonBit, Beta", "Docs", false, "# Beta\n\nBeta body with *emphasis*.",
      ),
    ),
    (
      "gamma.md",
      source(
        "Gamma", "2026-07-03", "Gamma", "Examples", false, "# Gamma\n\nGamma body with `code`.",
      ),
    ),
    (
      "delta draft.md",
      source(
        "Delta Draft", "2026-07-04", "Draft", "Planning", true, "# Delta\n\nDraft body.",
      ),
    ),
  ]
}

///|
fn scenarios() -> Array[Scenario] {
  [
    {
      name: "single-page",
      posts_per_page: 10,
      include_drafts: false,
      base_url: "https://example.com/a",
      expected_indexes: 1,
      expected_draft: false,
    },
    {
      name: "paginated",
      posts_per_page: 2,
      include_drafts: false,
      base_url: "https://example.com/b/",
      expected_indexes: 2,
      expected_draft: false,
    },
    {
      name: "drafts",
      posts_per_page: 2,
      include_drafts: true,
      base_url: "https://example.com/c",
      expected_indexes: 2,
      expected_draft: true,
    },
    {
      name: "fallback-limit",
      posts_per_page: 0,
      include_drafts: true,
      base_url: "https://example.com/d/",
      expected_indexes: 1,
      expected_draft: true,
    },
  ]
}

///|
fn generate(scenario : Scenario) -> Array[@ssg.GeneratedPage] {
  @ssg.generate_site(
    sources(),
    post_layout(),
    index_layout(),
    tag_layout(),
    category_layout(),
    config(scenario),
    scenario.include_drafts,
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
fn has_page(pages : Array[@ssg.GeneratedPage], path : String) -> Bool {
  for page in pages {
    if page.path == path {
      return true
    }
  }
  false
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
fn count_index_pages(pages : Array[@ssg.GeneratedPage]) -> Int {
  let mut count = 0
  for page in pages {
    if page.path == "index.html" ||
      (page.path.has_prefix("index") && page.path.has_suffix(".html")) {
      count += 1
    }
  }
  count
}

///|
fn validate_posts(
  scenario : Scenario,
  pages : Array[@ssg.GeneratedPage],
) -> Unit {
  assert_contains(
    "alpha",
    find_page(pages, "alpha.html"),
    "<strong>strong</strong>",
  )
  assert_contains("beta", find_page(pages, "beta.html"), "<em>emphasis</em>")
  assert_contains("gamma", find_page(pages, "gamma.html"), "<code>code</code>")
  if scenario.expected_draft {
    assert_contains("draft", find_page(pages, "delta-draft.html"), "Draft body")
  } else if has_page(pages, "delta-draft.html") {
    abort(scenario.name + " unexpectedly generated draft page")
  }
}

///|
fn validate_indexes(
  scenario : Scenario,
  pages : Array[@ssg.GeneratedPage],
) -> Unit {
  let actual_indexes = count_index_pages(pages)
  if actual_indexes != scenario.expected_indexes {
    abort(
      scenario.name +
      " expected " +
      scenario.expected_indexes.to_string() +
      " index pages, got " +
      actual_indexes.to_string(),
    )
  }
  let index = find_page(pages, "index.html")
  assert_contains("index", index, "gamma.html")
  if scenario.expected_draft {
    assert_contains("index", index, "delta-draft.html")
    if scenario.posts_per_page == 2 {
      let index2 = find_page(pages, "index2.html")
      assert_contains("index2", index2, "beta.html")
      assert_contains("index2", index2, "alpha.html")
    } else {
      assert_contains("index", index, "beta.html")
      assert_contains("index", index, "alpha.html")
    }
  } else {
    assert_contains("index", index, "beta.html")
    assert_not_contains("index", index, "delta-draft.html")
  }
}

///|
fn validate_taxonomies(
  scenario : Scenario,
  pages : Array[@ssg.GeneratedPage],
) -> Unit {
  ignore(scenario)
  assert_contains(
    "tag moonbit",
    find_page(pages, "tag-moonbit.html"),
    "alpha.html",
  )
  assert_contains(
    "tag moonbit",
    find_page(pages, "tag-moonbit.html"),
    "beta.html",
  )
  assert_contains(
    "category docs",
    find_page(pages, "category-docs.html"),
    "alpha.html",
  )
  assert_contains(
    "category docs",
    find_page(pages, "category-docs.html"),
    "beta.html",
  )
  assert_contains(
    "category examples",
    find_page(pages, "category-examples.html"),
    "gamma.html",
  )
}

///|
fn validate_machine_outputs(
  scenario : Scenario,
  pages : Array[@ssg.GeneratedPage],
) -> Unit {
  let rss = find_page(pages, "rss.xml")
  let search = find_page(pages, "search.json")
  let sitemap = find_page(pages, "sitemap.xml")
  assert_contains("rss", rss, scenario.base_url)
  assert_contains("search", search, "\"title\": \"Gamma\"")
  assert_contains("search", search, "\"url\": \"gamma.html\"")
  assert_contains("sitemap", sitemap, "gamma.html")
  assert_not_contains("sitemap", sitemap, "rss.xml")
  if scenario.expected_draft {
    assert_contains("search", search, "Delta Draft")
  } else {
    assert_not_contains("search", search, "Delta Draft")
  }
}

///|
fn run_scenario(scenario : Scenario) -> Int {
  let pages = generate(scenario)
  validate_posts(scenario, pages)
  validate_indexes(scenario, pages)
  validate_taxonomies(scenario, pages)
  validate_machine_outputs(scenario, pages)
  pages.length()
}

///|
fn main {
  let mut total_pages = 0
  for scenario in scenarios() {
    let page_count = run_scenario(scenario)
    total_pages += page_count
    println(scenario.name + ": " + page_count.to_string() + " pages")
  }
  println("matrix generated page-count sum: " + total_pages.to_string())
}
