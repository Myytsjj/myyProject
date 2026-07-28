///|
fn assert_render_contains(
  name : String,
  markdown : String,
  expected : String,
) -> Unit {
  let html = render_html(to_events(Parser::new(markdown).parse()))
  if !html.contains(expected) {
    abort(
      "render case '" +
      name +
      "' did not contain expected fragment:\nexpected: " +
      expected +
      "\nactual:\n" +
      html,
    )
  }
}

///|
fn assert_render_not_contains(
  name : String,
  markdown : String,
  blocked : String,
) -> Unit {
  let html = render_html(to_events(Parser::new(markdown).parse()))
  if html.contains(blocked) {
    abort(
      "render case '" +
      name +
      "' contained blocked fragment:\nblocked: " +
      blocked +
      "\nactual:\n" +
      html,
    )
  }
}

///|
test "markdown regression matrix for inline rendering" {
  assert_render_contains(
    "strong text", "MoonBit has **fast feedback**.", "<strong>fast feedback</strong>",
  )
  assert_render_contains(
    "emphasis text", "MoonBit has *clear syntax*.", "<em>clear syntax</em>",
  )
  assert_render_contains(
    "code span escapes tags", "`<script>alert(1)</script>`", "&lt;script&gt;alert(1)&lt;/script&gt;",
  )
  assert_render_contains(
    "link with nested parentheses", "[docs](https://example.com/a(b)c)", "href=\"https://example.com/a(b)c\"",
  )
  assert_render_contains(
    "link with query string", "[query](https://example.com/search?q=moonbit&lang=en)",
    "href=\"https://example.com/search?q=moonbit&amp;lang=en\"",
  )
  assert_render_contains(
    "image alt escapes quotes", "![a \"quote\" alt](https://example.com/a.png)",
    "alt=\"a &quot;quote&quot; alt\"",
  )
  assert_render_contains(
    "image source escapes ampersand", "![diagram](https://example.com/a.png?x=1&y=2)",
    "src=\"https://example.com/a.png?x=1&amp;y=2\"",
  )
  assert_render_contains("plain ampersand text", "A & B", "A &amp; B")
  assert_render_contains("angle bracket text", "<MoonBit>", "&lt;MoonBit&gt;")
  assert_render_contains("quote text", "\"MoonBit\"", "&quot;MoonBit&quot;")
}

///|
test "markdown regression matrix for block rendering" {
  assert_render_contains("h1 heading", "# Title", "<h1>\nTitle</h1>")
  assert_render_contains("h6 heading", "###### Tiny", "<h6>\nTiny</h6>")
  assert_render_contains("unordered list", "* one\n* two", "<ul>")
  assert_render_contains("ordered list", "1. one\n2. two", "<ol>")
  assert_render_contains("blockquote", "> quoted text", "<blockquote>")
  assert_render_contains("thematic break", "---", "<hr />")
  assert_render_contains(
    "fenced code language", "```moonbit\nfn main {}\n```", "class=\"language-moonbit\"",
  )
  assert_render_contains("fenced code body", "```\nlet x = 1\n```", "let x = 1")
  assert_render_contains("paragraph split", "first\n\nsecond", "second</p>")
  assert_render_contains("mixed blocks", "# Title\n\n> quote\n\n* item", "<li>")
}

///|
test "markdown unsafe url schemes are blocked consistently" {
  assert_render_contains(
    "javascript link blocked", "[x](javascript:alert(1))", "href=\"#unsafe-url\"",
  )
  assert_render_contains(
    "uppercase javascript blocked", "[x](JaVaScRiPt:alert(1))", "href=\"#unsafe-url\"",
  )
  assert_render_contains(
    "vbscript blocked", "[x](vbscript:msgbox(1))", "href=\"#unsafe-url\"",
  )
  assert_render_contains(
    "data link blocked", "[x](data:text/html,<script>x</script>)", "href=\"#unsafe-url\"",
  )
  assert_render_contains(
    "javascript image blocked", "![x](javascript:alert(1))", "src=\"#unsafe-url\"",
  )
  assert_render_not_contains(
    "unsafe link does not leak script", "[x](javascript:alert(1))", "href=\"javascript:",
  )
  assert_render_not_contains(
    "unsafe image does not leak script", "![x](javascript:alert(1))", "src=\"javascript:",
  )
}

///|
test "markdown safe url schemes and relative paths survive" {
  assert_render_contains(
    "https link", "[x](https://example.com)", "href=\"https://example.com\"",
  )
  assert_render_contains(
    "http link", "[x](http://example.com)", "href=\"http://example.com\"",
  )
  assert_render_contains(
    "relative link", "[x](docs/getting-started.html)", "href=\"docs/getting-started.html\"",
  )
  assert_render_contains(
    "root absolute link", "[x](/docs/index.html)", "href=\"/docs/index.html\"",
  )
  assert_render_contains("anchor link", "[x](#install)", "href=\"#install\"")
  assert_render_contains(
    "mailto link", "[x](mailto:team@example.com)", "href=\"mailto:team@example.com\"",
  )
}

///|
test "markdown malformed constructs degrade to text instead of crashing" {
  assert_render_contains("unclosed strong", "before **after", "**after")
  assert_render_contains("unclosed emphasis", "before *after", "*after")
  assert_render_contains("unclosed link label", "[label", "[label")
  assert_render_contains("unclosed image label", "![label", "![label")
  assert_render_contains("missing link url", "[label]()", "label")
  assert_render_contains("missing image url", "![alt]()", "alt")
}

///|
test "markdown unicode and emoji text does not loop or corrupt output" {
  assert_render_contains(
    "cjk paragraph", "你好，MoonBit。", "你好，MoonBit。",
  )
  assert_render_contains(
    "emoji paragraph", "Build 🚀 with MoonBit", "Build 🚀 with MoonBit",
  )
  assert_render_contains("emoji emphasis", "*🚀 fast*", "<em>🚀 fast</em>")
  assert_render_contains(
    "emoji link label", "[🚀](https://example.com)", ">🚀</a>",
  )
  assert_render_contains("cjk code span", "`中文`", "<code>中文</code>")
}
