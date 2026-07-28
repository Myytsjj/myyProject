///|
fn make_post(index : Int) -> (String, String) {
  let filename = "post-" + index.to_string() + ".md"
  let source =
    #|---
    #|title: Benchmark Post
    #|date: 2026-07-28
    #|tags: [bench, moonbit]
    #|categories: [performance]
    #|---
    #|# Benchmark Post
    #|
    #|This post contains **strong text**, *emphasis*, `code`, a [link](https://example.com), and a list.
    #|
    #|* item one
    #|* item two
  (filename, source)
}

///|
fn main {
  let sources = []
  for i = 0; i < 100; i = i + 1 {
    sources.push(make_post(i))
  }
  let post_layout = "<html><body><h1>{{title}}</h1>{{content}}</body></html>"
  let index_layout = "<html><body>{{posts}}{{pagination}}</body></html>"
  let tag_layout = "<html><body><h1>{{tag}}</h1>{{posts}}</body></html>"
  let category_layout = "<html><body><h1>{{category}}</h1>{{posts}}</body></html>"
  let config = @ssg.Config::make(
    "Benchmark", "Benchmark run", "https://example.com", 20, "content", "layouts",
    "public", "static",
  )
  let mut total_pages = 0
  for repeat = 0; repeat < 20; repeat = repeat + 1 {
    let pages = @ssg.generate_site(
      sources, post_layout, index_layout, tag_layout, category_layout, config, false,
    )
    total_pages += pages.length()
  }
  println(
    "benchmark smoke generated page-count sum: " + total_pages.to_string(),
  )
}
