///|
fn find_page_for_security_test(
  pages : Array[GeneratedPage],
  path : String,
) -> String {
  for page in pages {
    if page.path == path {
      return page.html
    }
  }
  abort("missing generated page: " + path)
}

///|
fn has_page_for_security_test(
  pages : Array[GeneratedPage],
  path : String,
) -> Bool {
  for page in pages {
    if page.path == path {
      return true
    }
  }
  false
}

///|
test "generate site escapes template values and slugifies taxonomy paths" {
  let post_src =
    #|---
    #|title: <script>alert(1)</script>
    #|date: 2026-07-28" onclick="x
    #|tags: [MoonBit Tips, ../escape]
    #|categories: [News & Notes]
    #|---
    #|Hello <b>safe text</b>.

  let layout =
    #|<html><head><title>{{title}}</title></head><body>
    #|<h1>{{title}}</h1>
    #|<time>{{date}}</time>
    #|{{categories}}
    #|{{content}}
    #|{{tags}}
    #|</body></html>
  let index_layout = "<html><head><title>{{title}}</title></head><body>{{posts}}{{pagination}}</body></html>"
  let tag_layout = "<html><body><h1>{{tag}}</h1>{{posts}}</body></html>"
  let category_layout = "<html><body><h1>{{category}}</h1>{{posts}}</body></html>"
  let config = Config::make(
    "Site <Name>", "Description", "https://example.com/docs", 10, "content", "layouts",
    "public", "static",
  )

  let pages = generate_site(
    [("unsafe post.md", post_src)],
    layout,
    index_layout,
    tag_layout,
    category_layout,
    config,
    false,
  )

  let post_html = find_page_for_security_test(pages, "unsafe-post.html")
  assert_true(post_html.contains("&lt;script&gt;alert(1)&lt;/script&gt;"))
  assert_true(post_html.contains("2026-07-28&quot; onclick=&quot;x"))
  assert_true(post_html.contains("tag-moonbit-tips.html"))
  assert_true(post_html.contains("tag-escape.html"))
  assert_true(post_html.contains("category-news-notes.html"))
  assert_false(post_html.contains("<script>"))
  assert_false(post_html.contains("tag-../escape"))

  assert_true(has_page_for_security_test(pages, "tag-moonbit-tips.html"))
  assert_true(has_page_for_security_test(pages, "tag-escape.html"))
  assert_true(has_page_for_security_test(pages, "category-news-notes.html"))
  assert_true(has_page_for_security_test(pages, "sitemap.xml"))
}
