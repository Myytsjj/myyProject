///|
fn assert_html_equals(
  name : String,
  events : Array[Event],
  expected : String,
) -> Unit {
  let html = render_html(events)
  if html != expected {
    abort(
      name +
      " rendered unexpected html:\nexpected:\n" +
      expected +
      "\nactual:\n" +
      html,
    )
  }
}

///|
fn assert_markdown_html(
  name : String,
  markdown : String,
  expected : String,
) -> Unit {
  let html = render_html(to_events(Parser::new(markdown).parse()))
  if html != expected {
    abort(
      name +
      " rendered unexpected html:\nexpected:\n" +
      expected +
      "\nactual:\n" +
      html,
    )
  }
}

///|
fn assert_markdown_has(
  name : String,
  markdown : String,
  expected : String,
) -> Unit {
  let html = render_html(to_events(Parser::new(markdown).parse()))
  if !html.contains(expected) {
    abort(name + " missing expected fragment: " + expected)
  }
}

///|
fn assert_markdown_lacks(
  name : String,
  markdown : String,
  blocked : String,
) -> Unit {
  let html = render_html(to_events(Parser::new(markdown).parse()))
  if html.contains(blocked) {
    abort(name + " contained blocked fragment: " + blocked)
  }
}

///|
test "render html direct event stream for block nesting" {
  assert_html_equals(
    "paragraph",
    [Event::StartBlock("p"), Event::TextEvent("Hello"), Event::EndBlock("p")],
    "<p>\nHello</p>\n",
  )
  assert_html_equals(
    "heading",
    [Event::StartBlock("h2"), Event::TextEvent("Title"), Event::EndBlock("h2")],
    "<h2>\nTitle</h2>\n",
  )
  assert_html_equals(
    "list item",
    [
      Event::StartBlock("ul"),
      Event::StartBlock("li"),
      Event::StartBlock("p"),
      Event::TextEvent("Item"),
      Event::EndBlock("p"),
      Event::EndBlock("li"),
      Event::EndBlock("ul"),
    ],
    "<ul>\n<li>\n<p>\nItem</p>\n</li>\n</ul>\n",
  )
}

///|
test "render html direct event stream escapes text" {
  assert_html_equals(
    "text escaping",
    [
      Event::StartBlock("p"),
      Event::TextEvent("<tag attr=\"x\">A & B</tag>"),
      Event::EndBlock("p"),
    ],
    "<p>\n&lt;tag attr=&quot;x&quot;&gt;A &amp; B&lt;/tag&gt;</p>\n",
  )
  assert_html_equals(
    "inline code text escaping",
    [
      Event::StartInline("code"),
      Event::TextEvent("<MoonBit>"),
      Event::EndInline("code"),
    ],
    "<code>&lt;MoonBit&gt;</code>",
  )
}

///|
test "render html direct event stream handles attributes on closing tags" {
  assert_html_equals(
    "code class closes as code",
    [
      Event::StartBlock("pre"),
      Event::StartBlock("code class=\"language-mbt\""),
      Event::TextEvent("fn main {}"),
      Event::EndBlock("code class=\"language-mbt\""),
      Event::EndBlock("pre"),
    ],
    "<pre>\n<code class=\"language-mbt\">\nfn main {}</code>\n</pre>\n",
  )
  assert_html_equals(
    "link attributes close as anchor",
    [
      Event::StartInline("a href=\"https://example.com\" title=\"Docs\""),
      Event::TextEvent("docs"),
      Event::EndInline("a href=\"https://example.com\""),
    ],
    "<a href=\"https://example.com\" title=\"Docs\">docs</a>",
  )
}

///|
test "render html self closing events" {
  assert_html_equals("thematic break", [Event::SelfClosing("hr")], "<hr />\n")
  assert_html_equals(
    "image",
    [Event::SelfClosing("img src=\"a.png\" alt=\"A\"")],
    "<img src=\"a.png\" alt=\"A\" />\n",
  )
  assert_html_equals("line break", [Event::SelfClosing("br")], "<br />\n")
}

///|
test "markdown event conversion handles nested inline combinations" {
  assert_markdown_has(
    "strong inside link", "[**MoonBit** docs](https://example.com)", "<a href=\"https://example.com\"><strong>MoonBit</strong> docs</a>",
  )
  assert_markdown_has(
    "emphasis inside strong", "**fast *and* safe**", "<strong>fast <em>and</em> safe</strong>",
  )
  assert_markdown_has(
    "code inside link label", "[`moon test`](https://example.com)", "<a href=\"https://example.com\"><code>moon test</code></a>",
  )
}

///|
test "markdown code info string is escaped as an attribute" {
  assert_markdown_has(
    "language quote", "```mbt\" onmouseover=\"x\nlet x = 1\n```", "class=\"language-mbt&quot; onmouseover=&quot;x\"",
  )
  assert_markdown_lacks(
    "language quote does not create attribute", "```mbt\" onmouseover=\"x\nlet x = 1\n```",
    "onmouseover=\"x\"",
  )
}

///|
test "markdown link and image titles are escaped" {
  assert_markdown_has(
    "link title", "[docs](https://example.com \"A & B\")", "title=\"A &amp; B\"",
  )
  assert_markdown_has(
    "image title", "![diagram](diagram.png \"A < B\")", "title=\"A &lt; B\"",
  )
  assert_markdown_lacks(
    "image title does not leak raw angle", "![diagram](diagram.png \"A < B\")", "title=\"A < B\"",
  )
}

///|
test "markdown paragraph joining remains stable" {
  assert_markdown_html(
    "single paragraph joins soft line", "alpha\nbeta\ngamma", "<p>\nalpha beta gamma</p>\n",
  )
  assert_markdown_html(
    "paragraphs split on blank line", "alpha\n\nbeta", "<p>\nalpha</p>\n<p>\nbeta</p>\n",
  )
}

///|
test "markdown list continuation remains inside item" {
  assert_markdown_has(
    "unordered continuation", "* first\n  continued\n* second", "first continued",
  )
  assert_markdown_has(
    "ordered continuation", "1. first\n   continued\n2. second", "first continued",
  )
}

///|
test "markdown blockquote lazy continuation remains quoted" {
  assert_markdown_has(
    "lazy quote continuation", "> first\ncontinued", "first continued",
  )
  assert_markdown_has(
    "quote with nested emphasis", "> *quoted* text", "<blockquote>",
  )
  assert_markdown_has(
    "quote with nested emphasis html", "> *quoted* text", "<em>quoted</em>",
  )
}
