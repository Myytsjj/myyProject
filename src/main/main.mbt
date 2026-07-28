// Main entry point for moon-ssg CLI tool

///|
struct CliOptions {
  config_path : String
  include_drafts : Bool
  show_help : Bool
  show_version : Bool
  content_dir : String?
  layouts_dir : String?
  public_dir : String?
  static_dir : String?
  site_url : String?
  error_message : String?
} derive(Debug, Eq)

///|
fn CliOptions::default() -> CliOptions {
  {
    config_path: "ssg.config.json",
    include_drafts: false,
    show_help: false,
    show_version: false,
    content_dir: None,
    layouts_dir: None,
    public_dir: None,
    static_dir: None,
    site_url: None,
    error_message: None,
  }
}

///|
fn parse_cli_args(args : Array[String]) -> CliOptions {
  let mut opts = CliOptions::default()
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      opts = { ..opts, show_help: true }
      i += 1
    } else if arg == "--version" || arg == "-V" {
      opts = { ..opts, show_version: true }
      i += 1
    } else if arg == "--drafts" || arg == "-d" {
      opts = { ..opts, include_drafts: true }
      i += 1
    } else if arg == "--config" || arg == "-c" {
      match read_cli_value(args, i, "--config") {
        Some(value) => {
          opts = { ..opts, config_path: value }
          i += 2
        }
        None => {
          opts = {
            ..opts,
            error_message: Some("--config requires a path parameter"),
          }
          i = args.length()
        }
      }
    } else if arg.has_prefix("--config=") {
      opts = { ..opts, config_path: arg[9:].to_owned() }
      i += 1
    } else if arg.has_prefix("-c=") {
      opts = { ..opts, config_path: arg[3:].to_owned() }
      i += 1
    } else if arg == "--content" {
      match read_cli_value(args, i, "--content") {
        Some(value) => {
          opts = { ..opts, content_dir: Some(value) }
          i += 2
        }
        None => {
          opts = {
            ..opts,
            error_message: Some("--content requires a path parameter"),
          }
          i = args.length()
        }
      }
    } else if arg.has_prefix("--content=") {
      opts = { ..opts, content_dir: Some(arg[10:].to_owned()) }
      i += 1
    } else if arg == "--layouts" {
      match read_cli_value(args, i, "--layouts") {
        Some(value) => {
          opts = { ..opts, layouts_dir: Some(value) }
          i += 2
        }
        None => {
          opts = {
            ..opts,
            error_message: Some("--layouts requires a path parameter"),
          }
          i = args.length()
        }
      }
    } else if arg.has_prefix("--layouts=") {
      opts = { ..opts, layouts_dir: Some(arg[10:].to_owned()) }
      i += 1
    } else if arg == "--public" {
      match read_cli_value(args, i, "--public") {
        Some(value) => {
          opts = { ..opts, public_dir: Some(value) }
          i += 2
        }
        None => {
          opts = {
            ..opts,
            error_message: Some("--public requires a path parameter"),
          }
          i = args.length()
        }
      }
    } else if arg.has_prefix("--public=") {
      opts = { ..opts, public_dir: Some(arg[9:].to_owned()) }
      i += 1
    } else if arg == "--static" {
      match read_cli_value(args, i, "--static") {
        Some(value) => {
          opts = { ..opts, static_dir: Some(value) }
          i += 2
        }
        None => {
          opts = {
            ..opts,
            error_message: Some("--static requires a path parameter"),
          }
          i = args.length()
        }
      }
    } else if arg.has_prefix("--static=") {
      opts = { ..opts, static_dir: Some(arg[9:].to_owned()) }
      i += 1
    } else if arg == "--base-url" {
      match read_cli_value(args, i, "--base-url") {
        Some(value) => {
          opts = { ..opts, site_url: Some(value) }
          i += 2
        }
        None => {
          opts = {
            ..opts,
            error_message: Some("--base-url requires a URL parameter"),
          }
          i = args.length()
        }
      }
    } else if arg.has_prefix("--base-url=") {
      opts = { ..opts, site_url: Some(arg[11:].to_owned()) }
      i += 1
    } else {
      opts = { ..opts, error_message: Some("unknown argument: " + arg) }
      i = args.length()
    }
  }
  opts
}

///|
fn read_cli_value(args : Array[String], index : Int, _name : String) -> String? {
  if index + 1 < args.length() {
    Some(args[index + 1])
  } else {
    None
  }
}

///|
fn apply_cli_overrides(config : @ssg.Config, opts : CliOptions) -> @ssg.Config {
  @ssg.Config::make(
    config.site_title,
    config.site_description,
    opts.site_url.unwrap_or(config.site_url),
    config.posts_per_page,
    opts.content_dir.unwrap_or(config.content_dir),
    opts.layouts_dir.unwrap_or(config.layouts_dir),
    opts.public_dir.unwrap_or(config.public_dir),
    opts.static_dir.unwrap_or(config.static_dir),
  )
}

///|
fn normalize_runtime_args(args : Array[String]) -> Array[String] {
  if args.length() == 0 {
    []
  } else {
    let first = args[0]
    if first.has_suffix(".wasm") ||
      first.has_suffix(".js") ||
      first.has_suffix(".exe") {
      let normalized = []
      for i in 1..<args.length() {
        normalized.push(args[i])
      }
      normalized
    } else {
      args
    }
  }
}

///|
fn print_usage() -> Unit {
  println("moon-ssg 0.3.1")
  println("Usage: moon run src/main -- [options]")
  println("")
  println("Options:")
  println("  -h, --help                 Show this help text")
  println("  -V, --version              Show version")
  println("  -d, --drafts               Include draft posts")
  println("  -c, --config <path>        Read or create config JSON")
  println("      --content <dir>        Override content directory")
  println("      --layouts <dir>        Override layouts directory")
  println("      --public <dir>         Override output directory")
  println("      --static <dir>         Override static assets directory")
  println("      --base-url <url>       Override site URL for RSS and sitemap")
}

///|
fn main {
  let args = normalize_runtime_args(@env.args())
  let opts = parse_cli_args(args)

  match opts.error_message {
    Some(message) => {
      println("Error: " + message)
      print_usage()
      return
    }
    None => ()
  }

  if opts.show_help {
    print_usage()
    return
  }
  if opts.show_version {
    println("moon-ssg 0.3.1")
    return
  }

  println("[moon-ssg] Starting static site generation...")
  println("[moon-ssg] Using configuration: " + opts.config_path)

  try {
    // 1. Read or generate configuration
    let loaded_config : @ssg.Config = if !@fs.path_exists(opts.config_path) {
      let default_config = @ssg.Config::default()
      let json_val = default_config.to_json()
      @fs.write_string_to_file(opts.config_path, json_val.stringify())
      println(
        "[moon-ssg] Generated default configuration file: " + opts.config_path,
      )
      default_config
    } else {
      let config_str = @fs.read_file_to_string(opts.config_path)
      let json_val = @json.parse(config_str)
      let parsed_config : @ssg.Config = @json.from_json(json_val)
      parsed_config
    }
    let config = apply_cli_overrides(loaded_config, opts)

    let content_dir = config.content_dir
    let layouts_dir = config.layouts_dir
    let public_dir = config.public_dir
    let static_dir = config.static_dir

    // 2. Initialize default structures if missing
    if !@fs.path_exists(content_dir) {
      @fs.create_dir(content_dir)
      println("[moon-ssg] Created '" + content_dir + "' directory.")
    }

    if !@fs.path_exists(content_dir + "/hello-world.md") {
      let default_post =
        #|---
        #|title: Hello MoonBit!
        #|date: 2026-07-06
        #|tags: [MoonBit, WebAssembly, Programming]
        #|categories: [Technology]
        #|draft: false
        #|---
        #|# Welcome to MoonBit Static Site Generator
        #|
        #|This is your first post generated by `moon-ssg`.
        #|
        #|## Features Supported
        #|
        #|* **Markdown Parsing**: Write in standard Markdown.
        #|* **Taxonomies**: Categorize posts with tags and categories.
        #|* **Pagination**: Automatically page home listing page.
        #|* **RSS Feed**: Out-of-the-box RSS 2.0 XML support.
        #|* **Search Index**: Generated JSON index for client-side search.
        #|* **Static Files**: Automatic recursive copying of style assets.
        #|
        #|Enjoy writing!
      @fs.write_string_to_file(content_dir + "/hello-world.md", default_post)
      println("[moon-ssg] Created default post hello-world.md.")
    }

    if !@fs.path_exists(layouts_dir) {
      @fs.create_dir(layouts_dir)
      println("[moon-ssg] Created '" + layouts_dir + "' directory.")
    }

    if !@fs.path_exists(layouts_dir + "/post.html") {
      let post_layout =
        #|<!DOCTYPE html>
        #|<html lang="en">
        #|<head>
        #|  <meta charset="UTF-8">
        #|  <meta name="viewport" content="width=device-width, initial-scale=1.0">
        #|  <title>{{title}}</title>
        #|  <link rel="stylesheet" href="style.css">
        #|</head>
        #|<body>
        #|  <div class="container">
        #|    <p><a href="index.html">← Back to Home</a></p>
        #|    <article>
        #|      <h1>{{title}}</h1>
        #|      <div class="date">{{date}}</div>
        #|      {{categories}}
        #|      <div class="content">{{content}}</div>
        #|      {{tags}}
        #|    </article>
        #|  </div>
        #|</body>
        #|</html>
      @fs.write_string_to_file(layouts_dir + "/post.html", post_layout)
      println("[moon-ssg] Created default layout post.html.")
    }

    if !@fs.path_exists(layouts_dir + "/index.html") {
      let index_layout =
        #|<!DOCTYPE html>
        #|<html lang="en">
        #|<head>
        #|  <meta charset="UTF-8">
        #|  <meta name="viewport" content="width=device-width, initial-scale=1.0">
        #|  <title>{{title}}</title>
        #|  <link rel="stylesheet" href="style.css">
        #|</head>
        #|<body>
        #|  <div class="container">
        #|    <header>
        #|      <h1>Welcome to My Blog</h1>
        #|      <p>Generated with <a href="https://github.com/Myytsjj/moon-ssg">moon-ssg</a> (written in MoonBit).</p>
        #|    </header>
        #|    <main>
        #|      {{posts}}
        #|      {{pagination}}
        #|    </main>
        #|  </div>
        #|</body>
        #|</html>
      @fs.write_string_to_file(layouts_dir + "/index.html", index_layout)
      println("[moon-ssg] Created default layout index.html.")
    }

    if !@fs.path_exists(layouts_dir + "/tag.html") {
      let tag_layout =
        #|<!DOCTYPE html>
        #|<html lang="en">
        #|<head>
        #|  <meta charset="UTF-8">
        #|  <meta name="viewport" content="width=device-width, initial-scale=1.0">
        #|  <title>Tag: {{tag}}</title>
        #|  <link rel="stylesheet" href="style.css">
        #|</head>
        #|<body>
        #|  <div class="container">
        #|    <p><a href="index.html">← Back to Home</a></p>
        #|    <h1>Posts tagged with "{{tag}}"</h1>
        #|    {{posts}}
        #|  </div>
        #|</body>
        #|</html>
      @fs.write_string_to_file(layouts_dir + "/tag.html", tag_layout)
      println("[moon-ssg] Created default layout tag.html.")
    }

    if !@fs.path_exists(layouts_dir + "/category.html") {
      let category_layout =
        #|<!DOCTYPE html>
        #|<html lang="en">
        #|<head>
        #|  <meta charset="UTF-8">
        #|  <meta name="viewport" content="width=device-width, initial-scale=1.0">
        #|  <title>Category: {{category}}</title>
        #|  <link rel="stylesheet" href="style.css">
        #|</head>
        #|<body>
        #|  <div class="container">
        #|    <p><a href="index.html">← Back to Home</a></p>
        #|    <h1>Category: "{{category}}"</h1>
        #|    {{posts}}
        #|  </div>
        #|</body>
        #|</html>
      @fs.write_string_to_file(layouts_dir + "/category.html", category_layout)
      println("[moon-ssg] Created default layout category.html.")
    }

    if !@fs.path_exists(static_dir) {
      @fs.create_dir(static_dir)
      println("[moon-ssg] Created '" + static_dir + "' directory.")
    }

    if !@fs.path_exists(static_dir + "/style.css") {
      let default_css =
        #|/* Premium Glassmorphism & Dark-Accent Theme for moon-ssg */
        #|:root {
        #|  --primary: #6f46ff;
        #|  --primary-hover: #5732d6;
        #|  --bg: #0b0c10;
        #|  --card-bg: rgba(26, 29, 38, 0.6);
        #|  --text: #c5c6c7;
        #|  --text-heading: #ffffff;
        #|  --accent: #45f3ff;
        #|  --border: rgba(255, 255, 255, 0.08);
        #|}
        #|
        #|body {
        #|  font-family: 'Outfit', -apple-system, BlinkMacSystemFont, sans-serif;
        #|  line-height: 1.7;
        #|  background: var(--bg);
        #|  color: var(--text);
        #|  margin: 0;
        #|  padding: 0;
        #|}
        #|
        #|.container {
        #|  max-width: 800px;
        #|  margin: 0 auto;
        #|  padding: 3rem 1.5rem;
        #|}
        #|
        #|header {
        #|  border-bottom: 1px solid var(--border);
        #|  padding-bottom: 2rem;
        #|  margin-bottom: 3rem;
        #|}
        #|
        #|h1, h2, h3 {
        #|  color: var(--text-heading);
        #|  font-weight: 700;
        #|  letter-spacing: -0.02em;
        #|}
        #|
        #|h1 { font-size: 2.5rem; margin-top: 0; }
        #|
        #|a {
        #|  color: var(--accent);
        #|  text-decoration: none;
        #|  transition: color 0.2s ease;
        #|}
        #|
        #|a:hover {
        #|  color: var(--primary);
        #|}
        #|
        #|.date {
        #|  color: #888;
        #|  font-size: 0.9rem;
        #|  margin-bottom: 1.5rem;
        #|}
        #|
        #|ul {
        #|  list-style: none;
        #|  padding: 0;
        #|}
        #|
        #|li {
        #|  background: var(--card-bg);
        #|  border: 1px solid var(--border);
        #|  border-radius: 12px;
        #|  padding: 1.5rem;
        #|  margin-bottom: 1.25rem;
        #|  transition: transform 0.2s ease, box-shadow 0.2s ease;
        #|  backdrop-filter: blur(8px);
        #|}
        #|
        #|li:hover {
        #|  transform: translateY(-2px);
        #|  box-shadow: 0 8px 30px rgba(0,0,0,0.3);
        #|}
        #|
        #|pre {
        #|  background: rgba(0, 0, 0, 0.4);
        #|  border: 1px solid var(--border);
        #|  border-radius: 8px;
        #|  padding: 1.25rem;
        #|  overflow-x: auto;
        #|  font-family: 'Fira Code', monospace;
        #|}
        #|
        #|blockquote {
        #|  border-left: 4px solid var(--primary);
        #|  background: rgba(111, 70, 255, 0.05);
        #|  padding: 1rem 1.5rem;
        #|  margin: 1.5rem 0;
        #|  border-radius: 0 8px 8px 0;
        #|}
        #|
        #|.pagination {
        #|  display: flex;
        #|  justify-content: space-between;
        #|  align-items: center;
        #|  margin-top: 3rem;
        #|}
        #|
        #|.post-tags, .post-categories {
        #|  margin: 1.5rem 0;
        #|  font-size: 0.9rem;
        #|}
      @fs.write_string_to_file(static_dir + "/style.css", default_css)
      println("[moon-ssg] Created default stylesheet style.css.")
    }

    // 3. Read templates
    let post_template = @fs.read_file_to_string(layouts_dir + "/post.html")
    let index_template = @fs.read_file_to_string(layouts_dir + "/index.html")
    let tag_template = @fs.read_file_to_string(layouts_dir + "/tag.html")
    let category_template = @fs.read_file_to_string(
      layouts_dir + "/category.html",
    )

    // 4. Scan content files
    let sources = []
    let files = @fs.read_dir(content_dir)
    for file in files {
      if file.has_suffix(".md") {
        let content = @fs.read_file_to_string(content_dir + "/" + file)
        sources.push((file, content))
      }
    }

    if sources.length() == 0 {
      println(
        "[moon-ssg] Warning: No markdown files found in '" +
        content_dir +
        "' folder.",
      )
    }

    // 5. Generate the site
    let pages = @ssg.generate_site(
      sources,
      post_template,
      index_template,
      tag_template,
      category_template,
      config,
      opts.include_drafts,
    )

    // 6. Ensure public directory exists
    if !@fs.path_exists(public_dir) {
      @fs.create_dir(public_dir)
    }

    // 7. Write generated pages
    for page in pages {
      let out_path = public_dir + "/" + page.path
      @fs.write_string_to_file(out_path, page.html)
      println("  -> Generated " + out_path)
    }

    // 8. Copy static assets recursive
    if @fs.path_exists(static_dir) {
      copy_dir_recursive(static_dir, public_dir)
      println("[moon-ssg] Copied static assets recursively.")
    }

    println("[moon-ssg] Site successfully generated!")
  } catch {
    err => {
      println("[moon-ssg] Error occurred during generation:")
      println(to_repr(err).to_string())
    }
  }
}

///|
fn copy_dir_recursive(src : String, dst : String) -> Unit raise Error {
  if !@fs.path_exists(dst) {
    @fs.create_dir(dst)
  }
  let files = @fs.read_dir(src)
  for file in files {
    let src_path = src + "/" + file
    let dst_path = dst + "/" + file
    if @fs.is_dir(src_path) {
      copy_dir_recursive(src_path, dst_path)
    } else {
      let bytes = @fs.read_file_to_bytes(src_path)
      @fs.write_bytes_to_file(dst_path, bytes)
    }
  }
}
