///|
fn assert_meta_text(name : String, actual : String, expected : String) -> Unit {
  if actual != expected {
    abort(name + " expected '" + expected + "', got '" + actual + "'")
  }
}

///|
fn assert_meta_bool(name : String, actual : Bool, expected : Bool) -> Unit {
  if actual != expected {
    abort(
      name + " expected " + expected.to_string() + ", got " + actual.to_string(),
    )
  }
}

///|
fn assert_meta_list(
  name : String,
  actual : Array[String],
  expected : Array[String],
) -> Unit {
  if actual != expected {
    abort(name + " had unexpected list value")
  }
}

///|
test "front matter defaults when no metadata exists" {
  let (meta, body) = parse_front_matter("# Plain Post\n\nBody")
  assert_meta_text("title", meta.title, "Untitled")
  assert_meta_text("date", meta.date, "Unknown Date")
  assert_meta_bool("draft", meta.draft, false)
  assert_meta_list("tags", meta.tags, [])
  assert_meta_list("categories", meta.categories, [])
  assert_meta_text("body", body, "# Plain Post\n\nBody")
}

///|
test "front matter ignores opening delimiter without closing delimiter" {
  let source =
    #|---
    #|title: Missing Close
    #|date: 2026-07-28
    #|# Body
  let (meta, body) = parse_front_matter(source)
  assert_meta_text("title", meta.title, "Untitled")
  assert_meta_text("date", meta.date, "Unknown Date")
  assert_meta_text("body", body, source)
}

///|
test "front matter parses scalar fields and preserves raw values" {
  let source =
    #|---
    #|title: Scalar Fields
    #|date: 2026-07-28
    #|draft: true
    #|author: Bin Yuli
    #|summary: MoonBit SSG acceptance work
    #|---
    #|Body
  let (meta, body) = parse_front_matter(source)
  assert_meta_text("title", meta.title, "Scalar Fields")
  assert_meta_text("date", meta.date, "2026-07-28")
  assert_meta_bool("draft", meta.draft, true)
  assert_meta_text("author", meta.raw["author"], "Bin Yuli")
  assert_meta_text(
    "summary",
    meta.raw["summary"],
    "MoonBit SSG acceptance work",
  )
  assert_meta_text("body", body.trim().to_owned(), "Body")
}

///|
test "front matter treats draft as true only for lowercase true" {
  let lower =
    #|---
    #|draft: true
    #|---
    #|Body
  let upper =
    #|---
    #|draft: True
    #|---
    #|Body
  let yes =
    #|---
    #|draft: yes
    #|---
    #|Body
  let (lower_meta, _) = parse_front_matter(lower)
  let (upper_meta, _) = parse_front_matter(upper)
  let (yes_meta, _) = parse_front_matter(yes)
  assert_meta_bool("lower true", lower_meta.draft, true)
  assert_meta_bool("upper true", upper_meta.draft, false)
  assert_meta_bool("yes", yes_meta.draft, false)
}

///|
test "front matter parses inline list values" {
  let source =
    #|---
    #|tags: [MoonBit, SSG, Tests]
    #|categories: [Docs, Tooling]
    #|---
    #|Body
  let (meta, _) = parse_front_matter(source)
  assert_meta_list("tags", meta.tags, ["MoonBit", "SSG", "Tests"])
  assert_meta_list("categories", meta.categories, ["Docs", "Tooling"])
}

///|
test "front matter parses comma separated values without brackets" {
  let source =
    #|---
    #|tags: MoonBit, SSG, Tests
    #|categories: Docs, Tooling
    #|---
    #|Body
  let (meta, _) = parse_front_matter(source)
  assert_meta_list("tags", meta.tags, ["MoonBit", "SSG", "Tests"])
  assert_meta_list("categories", meta.categories, ["Docs", "Tooling"])
}

///|
test "front matter parses dash multiline lists" {
  let source =
    #|---
    #|tags:
    #|  - MoonBit
    #|  - SSG
    #|categories:
    #|  - Docs
    #|  - Examples
    #|---
    #|Body
  let (meta, _) = parse_front_matter(source)
  assert_meta_list("tags", meta.tags, ["MoonBit", "SSG"])
  assert_meta_list("categories", meta.categories, ["Docs", "Examples"])
}

///|
test "front matter parses star multiline lists" {
  let source =
    #|---
    #|tags:
    #|  * MoonBit
    #|  * Parser
    #|categories:
    #|  * Markdown
    #|  * Rendering
    #|---
    #|Body
  let (meta, _) = parse_front_matter(source)
  assert_meta_list("tags", meta.tags, ["MoonBit", "Parser"])
  assert_meta_list("categories", meta.categories, ["Markdown", "Rendering"])
}

///|
test "front matter stores unknown multiline list as raw comma string" {
  let source =
    #|---
    #|related:
    #|  - alpha
    #|  - beta
    #|---
    #|Body
  let (meta, _) = parse_front_matter(source)
  assert_meta_text("related", meta.raw["related"], "alpha, beta")
}

///|
test "front matter keeps colon content after the first separator" {
  let source =
    #|---
    #|title: Colon Test
    #|summary: A title: with colon: inside value
    #|---
    #|Body
  let (meta, _) = parse_front_matter(source)
  assert_meta_text("title", meta.title, "Colon Test")
  assert_meta_text(
    "summary",
    meta.raw["summary"],
    "A title: with colon: inside value",
  )
}

///|
test "front matter commits multiline list before next scalar" {
  let source =
    #|---
    #|tags:
    #|  - MoonBit
    #|  - SSG
    #|title: After List
    #|---
    #|Body
  let (meta, _) = parse_front_matter(source)
  assert_meta_list("tags", meta.tags, ["MoonBit", "SSG"])
  assert_meta_text("title", meta.title, "After List")
}

///|
test "front matter ignores blank lines inside metadata block" {
  let source =
    #|---
    #|
    #|title: Blank Lines
    #|
    #|tags: [A, B]
    #|
    #|---
    #|Body
  let (meta, _) = parse_front_matter(source)
  assert_meta_text("title", meta.title, "Blank Lines")
  assert_meta_list("tags", meta.tags, ["A", "B"])
}

///|
test "front matter body starts after closing delimiter" {
  let source =
    #|---
    #|title: Body Start
    #|---
    #|
    #|# Heading
    #|
    #|Body
  let (_, body) = parse_front_matter(source)
  assert_meta_text("body", body.trim().to_owned(), "# Heading\n\nBody")
}
