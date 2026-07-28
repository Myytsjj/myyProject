///|
test "parse cli flags for help version drafts config and directory overrides" {
  let opts = parse_cli_args([
    "--config", "site.json", "--drafts", "--content", "posts", "--layouts=templates",
    "--public", "dist", "--static=assets", "--base-url", "https://example.com/blog",
  ])
  assert_false(opts.show_help)
  assert_false(opts.show_version)
  assert_true(opts.include_drafts)
  assert_eq(opts.config_path, "site.json")
  assert_eq(opts.content_dir, Some("posts"))
  assert_eq(opts.layouts_dir, Some("templates"))
  assert_eq(opts.public_dir, Some("dist"))
  assert_eq(opts.static_dir, Some("assets"))
  assert_eq(opts.site_url, Some("https://example.com/blog"))
  assert_eq(opts.error_message, None)
}

///|
test "parse cli reports missing values without running generation" {
  let opts = parse_cli_args(["--content"])
  assert_eq(opts.error_message, Some("--content requires a path parameter"))
}

///|
test "parse cli accepts compact config spellings" {
  let long_eq = parse_cli_args(["--config=site.json"])
  assert_eq(long_eq.config_path, "site.json")
  assert_eq(long_eq.error_message, None)

  let short_pair = parse_cli_args(["-c", "dev.json"])
  assert_eq(short_pair.config_path, "dev.json")
  assert_eq(short_pair.error_message, None)

  let short_eq = parse_cli_args(["-c=prod.json"])
  assert_eq(short_eq.config_path, "prod.json")
  assert_eq(short_eq.error_message, None)
}

///|
test "parse cli accepts version and help aliases" {
  let help_long = parse_cli_args(["--help"])
  assert_true(help_long.show_help)
  assert_false(help_long.show_version)

  let help_short = parse_cli_args(["-h"])
  assert_true(help_short.show_help)
  assert_false(help_short.show_version)

  let version_long = parse_cli_args(["--version"])
  assert_false(version_long.show_help)
  assert_true(version_long.show_version)

  let version_short = parse_cli_args(["-V"])
  assert_false(version_short.show_help)
  assert_true(version_short.show_version)
}

///|
test "parse cli accepts every directory override with equals form" {
  let opts = parse_cli_args([
    "--content=articles", "--layouts=theme", "--public=dist", "--static=assets",
    "--base-url=https://example.com/docs",
  ])
  assert_eq(opts.content_dir, Some("articles"))
  assert_eq(opts.layouts_dir, Some("theme"))
  assert_eq(opts.public_dir, Some("dist"))
  assert_eq(opts.static_dir, Some("assets"))
  assert_eq(opts.site_url, Some("https://example.com/docs"))
  assert_eq(opts.error_message, None)
}

///|
test "parse cli reports missing values for every valued option" {
  assert_eq(
    parse_cli_args(["--config"]).error_message,
    Some("--config requires a path parameter"),
  )
  assert_eq(
    parse_cli_args(["-c"]).error_message,
    Some("--config requires a path parameter"),
  )
  assert_eq(
    parse_cli_args(["--layouts"]).error_message,
    Some("--layouts requires a path parameter"),
  )
  assert_eq(
    parse_cli_args(["--public"]).error_message,
    Some("--public requires a path parameter"),
  )
  assert_eq(
    parse_cli_args(["--static"]).error_message,
    Some("--static requires a path parameter"),
  )
  assert_eq(
    parse_cli_args(["--base-url"]).error_message,
    Some("--base-url requires a URL parameter"),
  )
}

///|
test "parse cli stops at first unknown argument" {
  let opts = parse_cli_args(["--drafts", "--unknown", "--content", "ignored"])
  assert_true(opts.include_drafts)
  assert_eq(opts.error_message, Some("unknown argument: --unknown"))
  assert_eq(opts.content_dir, None)
}

///|
test "normalize runtime args skips moon run executable path" {
  let args = normalize_runtime_args([
    "_build/wasm-gc/debug/build/src/main/main.wasm", "--help",
  ])
  assert_eq(args.length(), 1)
  assert_eq(args[0], "--help")
  let opts = parse_cli_args(args)
  assert_true(opts.show_help)
  assert_eq(opts.error_message, None)
}

///|
test "normalize runtime args skips generated js and native paths" {
  let js_args = normalize_runtime_args([
    "_build/js/debug/build/src/main/main.js", "--version",
  ])
  assert_eq(js_args.length(), 1)
  assert_eq(js_args[0], "--version")

  let exe_args = normalize_runtime_args([
    "_build/native/debug/build/src/main/main.exe", "--drafts",
  ])
  assert_eq(exe_args.length(), 1)
  assert_eq(exe_args[0], "--drafts")
}

///|
test "normalize runtime args keeps real user args untouched" {
  let args = normalize_runtime_args(["--content", "posts", "--public", "dist"])
  assert_eq(args.length(), 4)
  assert_eq(args[0], "--content")
  assert_eq(args[1], "posts")
  assert_eq(args[2], "--public")
  assert_eq(args[3], "dist")
}

///|
test "normalize runtime args handles empty runtime list" {
  let args = normalize_runtime_args([])
  assert_eq(args.length(), 0)
}

///|
test "apply cli overrides keeps unspecified config fields" {
  let config = @ssg.Config::make(
    "Site", "Desc", "https://old.example", 7, "content", "layouts", "public", "static",
  )
  let opts = parse_cli_args([
    "--content=posts", "--base-url=https://new.example",
  ])
  let updated = apply_cli_overrides(config, opts)
  assert_eq(updated.content_dir, "posts")
  assert_eq(updated.site_url, "https://new.example")
  assert_eq(updated.layouts_dir, "layouts")
  assert_eq(updated.public_dir, "public")
  assert_eq(updated.static_dir, "static")
  assert_eq(updated.posts_per_page, 7)
}
