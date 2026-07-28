///|
fn assert_config_text(
  name : String,
  actual : String,
  expected : String,
) -> Unit {
  if actual != expected {
    abort(name + " expected '" + expected + "', got '" + actual + "'")
  }
}

///|
fn assert_config_int(name : String, actual : Int, expected : Int) -> Unit {
  if actual != expected {
    abort(
      name + " expected " + expected.to_string() + ", got " + actual.to_string(),
    )
  }
}

///|
test "config default is usable for cli initialization" {
  let config = Config::default()
  assert_config_text("site title", config.site_title, "My MoonBit Blog")
  assert_config_text(
    "site description",
    config.site_description,
    "A beautiful static site generated with MoonBit.",
  )
  assert_config_text("site url", config.site_url, "https://example.com")
  assert_config_int("posts per page", config.posts_per_page, 5)
  assert_config_text("content dir", config.content_dir, "content")
  assert_config_text("layouts dir", config.layouts_dir, "layouts")
  assert_config_text("public dir", config.public_dir, "public")
  assert_config_text("static dir", config.static_dir, "static")
}

///|
test "config make stores all fields without hidden normalization" {
  let config = Config::make(
    "Docs", "MoonBit documentation", "https://example.com/docs/", 12, "articles",
    "theme", "dist", "assets",
  )
  assert_config_text("site title", config.site_title, "Docs")
  assert_config_text(
    "site description",
    config.site_description,
    "MoonBit documentation",
  )
  assert_config_text("site url", config.site_url, "https://example.com/docs/")
  assert_config_int("posts per page", config.posts_per_page, 12)
  assert_config_text("content dir", config.content_dir, "articles")
  assert_config_text("layouts dir", config.layouts_dir, "theme")
  assert_config_text("public dir", config.public_dir, "dist")
  assert_config_text("static dir", config.static_dir, "assets")
}

///|
test "config json round trip preserves cli fields" {
  let config = Config::make(
    "JSON Site", "Round trip config", "https://example.com/json", 8, "posts", "layouts",
    "public", "static",
  )
  let json_value = config.to_json()
  let parsed_value = @json.parse(json_value.stringify())
  let parsed : Config = @json.from_json(parsed_value)
  assert_config_text("site title", parsed.site_title, "JSON Site")
  assert_config_text(
    "site description",
    parsed.site_description,
    "Round trip config",
  )
  assert_config_text("site url", parsed.site_url, "https://example.com/json")
  assert_config_int("posts per page", parsed.posts_per_page, 8)
  assert_config_text("content dir", parsed.content_dir, "posts")
  assert_config_text("layouts dir", parsed.layouts_dir, "layouts")
  assert_config_text("public dir", parsed.public_dir, "public")
  assert_config_text("static dir", parsed.static_dir, "static")
}

///|
test "config json string contains expected package fields" {
  let config = Config::make(
    "Fields", "Field coverage", "https://example.com/fields", 3, "content", "templates",
    "site", "assets",
  )
  let encoded = config.to_json().stringify()
  if !encoded.contains("\"site_title\"") {
    abort("config json missing site_title")
  }
  if !encoded.contains("\"site_description\"") {
    abort("config json missing site_description")
  }
  if !encoded.contains("\"site_url\"") {
    abort("config json missing site_url")
  }
  if !encoded.contains("\"posts_per_page\"") {
    abort("config json missing posts_per_page")
  }
  if !encoded.contains("\"content_dir\"") {
    abort("config json missing content_dir")
  }
  if !encoded.contains("\"layouts_dir\"") {
    abort("config json missing layouts_dir")
  }
  if !encoded.contains("\"public_dir\"") {
    abort("config json missing public_dir")
  }
  if !encoded.contains("\"static_dir\"") {
    abort("config json missing static_dir")
  }
}

///|
test "config posts per page zero uses generator fallback" {
  let post =
    #|---
    #|title: One
    #|date: 2026-07-28
    #|---
    #|# One
  let config = Config::make(
    "Fallback", "Fallback posts_per_page", "https://example.com", 0, "content", "layouts",
    "public", "static",
  )
  let pages = generate_site(
    [("one.md", post)],
    "<article>{{content}}</article>",
    "<main>{{posts}}{{pagination}}</main>",
    "<section>{{posts}}</section>",
    "<section>{{posts}}</section>",
    config,
    false,
  )
  let mut found_index = false
  let mut found_second_index = false
  for page in pages {
    if page.path == "index.html" {
      found_index = true
    } else if page.path == "index2.html" {
      found_second_index = true
    }
  }
  if !found_index {
    abort("expected index.html with fallback posts_per_page")
  }
  if found_second_index {
    abort("did not expect index2.html with a single post")
  }
}
