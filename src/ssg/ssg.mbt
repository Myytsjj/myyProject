// Static Site Generator Engine for moon-ssg

///|
pub struct Config {
  site_title : String
  site_description : String
  site_url : String
  posts_per_page : Int
  content_dir : String
  layouts_dir : String
  public_dir : String
  static_dir : String
} derive(FromJson, ToJson, Debug)

///|
pub fn Config::make(
  site_title : String,
  site_description : String,
  site_url : String,
  posts_per_page : Int,
  content_dir : String,
  layouts_dir : String,
  public_dir : String,
  static_dir : String,
) -> Config {
  {
    site_title,
    site_description,
    site_url,
    posts_per_page,
    content_dir,
    layouts_dir,
    public_dir,
    static_dir,
  }
}

///|
pub fn Config::default() -> Config {
  {
    site_title: "My MoonBit Blog",
    site_description: "A beautiful static site generated with MoonBit.",
    site_url: "https://example.com",
    posts_per_page: 5,
    content_dir: "content",
    layouts_dir: "layouts",
    public_dir: "public",
    static_dir: "static",
  }
}

///|
pub struct BlogPost {
  title : String
  date : String
  filename : String
  content_html : String
  tags : Array[String]
  categories : Array[String]
  draft : Bool
  metadata : Map[String, String]
} derive(Debug, Eq)

///|
pub struct GeneratedPage {
  path : String
  html : String
} derive(Debug, Eq)

///|
pub struct BlogPostMetadata {
  title : String
  date : String
  draft : Bool
  tags : Array[String]
  categories : Array[String]
  raw : Map[String, String]
} derive(Debug)

// Helper to extract front matter and body
// Front matter format:
// ---
// title: My Post
// date: 2026-07-03
// ---
// Body content here...

///|
pub fn parse_front_matter(source : String) -> (BlogPostMetadata, String) {
  let raw = Map([])
  let mut title = "Untitled"
  let mut date = "Unknown Date"
  let mut draft = false
  let mut tags : Array[String] = []
  let mut categories : Array[String] = []
  let mut body = source

  // Only a marker on its own line can open or close front matter.
  let mut first_line_is_marker = false
  let mut second_fm_idx = -1
  let mut line_start = 0
  let mut line_index = 0
  for line in source.split("\n") {
    if line_index == 0 {
      first_line_is_marker = line.trim() == "---"
    } else if first_line_is_marker &&
      second_fm_idx == -1 &&
      line.trim() == "---" {
      second_fm_idx = line_start
    }
    line_start = line_start + line.length() + 1
    line_index = line_index + 1
  }

  if first_line_is_marker {
    if second_fm_idx != -1 {
      let fm_block = source[3:second_fm_idx]

      // Extract body
      let body_start = second_fm_idx + 3
      body = source[body_start:source.length()].to_owned()

      // Parse fm_block lines
      let lines = fm_block.split("\n")
      let mut current_list_key = ""
      let mut current_list_vals = []

      let commit_list = fn() {
        if current_list_key != "" {
          let list_copy = current_list_vals.copy()
          if current_list_key == "tags" {
            tags = list_copy
          } else if current_list_key == "categories" {
            categories = list_copy
          } else {
            let mut list_str = ""
            for idx, val in current_list_vals {
              if idx > 0 {
                list_str += ", "
              }
              list_str += val
            }
            raw.set(current_list_key, list_str)
          }
          current_list_key = ""
          current_list_vals = []
        }
      }

      for line in lines {
        let trimmed = line.trim().to_owned()
        if trimmed == "" {
          continue
        }

        // Check if line is a list item under a list key
        if current_list_key != "" &&
          (trimmed.has_prefix("- ") || trimmed.has_prefix("* ")) {
          let item_val = trimmed[2:].trim().to_owned()
          current_list_vals.push(item_val)
          continue
        }

        let mut colon_idx = -1
        for i = 0; i < trimmed.length(); i = i + 1 {
          if trimmed[i] == ':' {
            colon_idx = i
            break
          }
        }

        if colon_idx != -1 {
          commit_list()
          let key = trimmed[0:colon_idx].trim().to_owned()
          let val = trimmed[colon_idx + 1:].trim().to_owned()

          if key == "tags" || key == "categories" {
            if val.has_prefix("[") && val.has_suffix("]") {
              // Parse inline list [A, B, C]
              let content = val[1:val.length() - 1].trim()
              if content != "" {
                let parts = content.split(",")
                let vals = []
                for p in parts {
                  vals.push(p.trim().to_owned())
                }
                if key == "tags" {
                  tags = vals
                } else {
                  categories = vals
                }
              }
            } else if val == "" {
              current_list_key = key
              current_list_vals = []
            } else {
              // Comma-separated or single value
              let parts = val.split(",")
              let vals = []
              for p in parts {
                vals.push(p.trim().to_owned())
              }
              if key == "tags" {
                tags = vals
              } else {
                categories = vals
              }
            }
            // Regular key-value
          } else if key == "title" {
            title = val
          } else if key == "date" {
            date = val
          } else if key == "draft" {
            draft = val == "true"
          } else if val == "" {
            current_list_key = key
            current_list_vals = []
          } else {
            raw.set(key, val)
          }
        } else {
          commit_list()
        }
      }
      commit_list()
    }
  }

  ({ title, date, draft, tags, categories, raw }, body)
}

// Generate the site
// Takes an array of (filename, markdown_source) tuples

///|
pub fn generate_site(
  sources : Array[(String, String)],
  layout : String,
  index_layout : String,
  tag_layout : String,
  category_layout : String,
  config : Config,
  include_drafts : Bool,
) -> Array[GeneratedPage] {
  let pages = []
  let posts = []

  // 1. Process all markdown posts
  for src in sources {
    let (filename, content) = src
    let (meta, body) = parse_front_matter(content)

    if meta.draft && !include_drafts {
      continue
    }

    // Parse Markdown to HTML
    let parser = @markdown.Parser::new(body)
    let blocks = parser.parse()
    let events = @markdown.to_events(blocks)
    let html_content = @markdown.render_html(events)

    let title = meta.title
    let date = meta.date

    let post = {
      title,
      date,
      filename,
      content_html: html_content,
      tags: meta.tags,
      categories: meta.categories,
      draft: meta.draft,
      metadata: meta.raw,
    }
    posts.push(post)

    // Render the post page using the layout template
    let rendered_html = render_post(post, layout)
    let out_filename = slugify_path(filename.replace(old=".md", new="")) +
      ".html"

    pages.push({ path: out_filename, html: rendered_html })
  }

  // Sort posts by date descending for lists
  posts.sort_by(fn(a, b) { b.date.compare(a.date) })

  // 2. Generate the home/index page with pagination
  let paginated_pages = generate_paginated_index(posts, index_layout, config)
  for p in paginated_pages {
    pages.push(p)
  }

  // 3. Generate tag and category pages
  let taxonomy_pages = generate_taxonomy_pages(
    posts, tag_layout, category_layout,
  )
  for p in taxonomy_pages {
    pages.push(p)
  }

  // 4. Generate RSS/Atom feed
  let rss_xml = generate_rss(posts, config)
  pages.push({ path: "rss.xml", html: rss_xml })

  // 5. Generate search index JSON
  let search_json = generate_search_json(posts)
  pages.push({ path: "search.json", html: search_json })

  // 6. Generate sitemap
  let sitemap_xml = generate_sitemap(pages, config)
  pages.push({ path: "sitemap.xml", html: sitemap_xml })

  pages
}

///|
fn render_post(post : BlogPost, template : String) -> String {
  let mut res = template
  res = res.replace_all(old="{{title}}", new=escape_html_text(post.title))
  res = res.replace_all(old="{{date}}", new=escape_html_text(post.date))
  res = res.replace_all(old="{{content}}", new=post.content_html)

  // Render tags list in post
  let mut tags_html = ""
  if post.tags.length() > 0 {
    tags_html = "<div class=\"post-tags\">Tags: "
    for idx, tag in post.tags {
      if idx > 0 {
        tags_html += ", "
      }
      tags_html += "<a href=\"tag-" +
        slugify_path(tag) +
        ".html\">" +
        escape_html_text(tag) +
        "</a>"
    }
    tags_html += "</div>"
  }
  res = res.replace_all(old="{{tags}}", new=tags_html)

  // Render categories list in post
  let mut cats_html = ""
  if post.categories.length() > 0 {
    cats_html = "<div class=\"post-categories\">Categories: "
    for idx, cat in post.categories {
      if idx > 0 {
        cats_html += ", "
      }
      cats_html += "<a href=\"category-" +
        slugify_path(cat) +
        ".html\">" +
        escape_html_text(cat) +
        "</a>"
    }
    cats_html += "</div>"
  }
  res = res.replace_all(old="{{categories}}", new=cats_html)

  res
}

///|
fn generate_paginated_index(
  posts : Array[BlogPost],
  template : String,
  config : Config,
) -> Array[GeneratedPage] {
  let pages = []
  let total_posts = posts.length()
  let limit = if config.posts_per_page > 0 { config.posts_per_page } else { 10 }
  let total_pages = if total_posts == 0 {
    1
  } else {
    (total_posts + limit - 1) / limit
  }

  for page_num = 1; page_num <= total_pages; page_num = page_num + 1 {
    let start = (page_num - 1) * limit
    let mut end = start + limit
    if end > total_posts {
      end = total_posts
    }

    let mut list_html = "<ul>\n"
    for i = start; i < end; i = i + 1 {
      let post = posts[i]
      let link = slugify_path(post.filename.replace_all(old=".md", new="")) +
        ".html"
      list_html += "  <li><span class=\"date\">" +
        escape_html_text(post.date) +
        "</span> - <a href=\"" +
        link +
        "\">" +
        escape_html_text(post.title) +
        "</a>"
      if post.tags.length() > 0 {
        list_html += " <span class=\"tags\">("
        for j, t in post.tags {
          if j > 0 {
            list_html += ", "
          }
          list_html += "<a href=\"tag-" +
            slugify_path(t) +
            ".html\">" +
            escape_html_text(t) +
            "</a>"
        }
        list_html += ")</span>"
      }
      list_html += "</li>\n"
    }
    list_html += "</ul>"

    // Pagination controls
    let mut pagination_html = "<div class=\"pagination\">\n"
    if page_num > 1 {
      let prev_link = if page_num == 2 {
        "index.html"
      } else {
        "index" + (page_num - 1).to_string() + ".html"
      }
      pagination_html += "  <a href=\"" + prev_link + "\">« Previous</a>\n"
    }
    pagination_html += "  <span class=\"page-number\">Page " +
      page_num.to_string() +
      " of " +
      total_pages.to_string() +
      "</span>\n"
    if page_num < total_pages {
      let next_link = "index" + (page_num + 1).to_string() + ".html"
      pagination_html += "  <a href=\"" + next_link + "\">Next »</a>\n"
    }
    pagination_html += "</div>"

    let mut res = template
    res = res.replace_all(
      old="{{title}}",
      new=escape_html_text(config.site_title),
    )
    res = res.replace_all(old="{{posts}}", new=list_html)
    res = res.replace_all(old="{{pagination}}", new=pagination_html)

    let path = if page_num == 1 {
      "index.html"
    } else {
      "index" + page_num.to_string() + ".html"
    }

    pages.push({ path, html: res })
  }

  pages
}

///|
fn generate_taxonomy_pages(
  posts : Array[BlogPost],
  tag_layout : String,
  category_layout : String,
) -> Array[GeneratedPage] {
  let pages = []
  let tag_map : Map[String, Array[BlogPost]] = Map([])
  let cat_map : Map[String, Array[BlogPost]] = Map([])

  // Group posts
  for post in posts {
    for tag in post.tags {
      let arr = tag_map.get(tag).unwrap_or([])
      arr.push(post)
      tag_map.set(tag, arr)
    }
    for cat in post.categories {
      let arr = cat_map.get(cat).unwrap_or([])
      arr.push(post)
      cat_map.set(cat, arr)
    }
  }

  // Generate tag pages
  for tag, tposts in tag_map {
    let mut list_html = "<ul>\n"
    for post in tposts {
      let link = slugify_path(post.filename.replace_all(old=".md", new="")) +
        ".html"
      list_html += "  <li><span class=\"date\">" +
        escape_html_text(post.date) +
        "</span> - <a href=\"" +
        link +
        "\">" +
        escape_html_text(post.title) +
        "</a></li>\n"
    }
    list_html += "</ul>"

    let mut res = tag_layout
    res = res.replace_all(old="{{tag}}", new=escape_html_text(tag))
    res = res.replace_all(old="{{posts}}", new=list_html)

    pages.push({ path: "tag-" + slugify_path(tag) + ".html", html: res })
  }

  // Generate category pages
  for cat, cposts in cat_map {
    let mut list_html = "<ul>\n"
    for post in cposts {
      let link = slugify_path(post.filename.replace_all(old=".md", new="")) +
        ".html"
      list_html += "  <li><span class=\"date\">" +
        escape_html_text(post.date) +
        "</span> - <a href=\"" +
        link +
        "\">" +
        escape_html_text(post.title) +
        "</a></li>\n"
    }
    list_html += "</ul>"

    let mut res = category_layout
    res = res.replace_all(old="{{category}}", new=escape_html_text(cat))
    res = res.replace_all(old="{{posts}}", new=list_html)

    pages.push({ path: "category-" + slugify_path(cat) + ".html", html: res })
  }

  pages
}

///|
fn generate_rss(posts : Array[BlogPost], config : Config) -> String {
  let mut xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
  xml += "<rss version=\"2.0\">\n"
  xml += "<channel>\n"
  xml += "  <title>" + escape_xml(config.site_title) + "</title>\n"
  xml += "  <link>" + escape_xml(config.site_url) + "</link>\n"
  xml += "  <description>" +
    escape_xml(config.site_description) +
    "</description>\n"
  xml += "  <generator>moon-ssg</generator>\n"

  let limit = if posts.length() < 10 { posts.length() } else { 10 }
  for i = 0; i < limit; i = i + 1 {
    let post = posts[i]
    let link = config.site_url +
      "/" +
      slugify_path(post.filename.replace(old=".md", new="")) +
      ".html"
    xml += "  <item>\n"
    xml += "    <title>" + escape_xml(post.title) + "</title>\n"
    xml += "    <link>" + escape_xml(link) + "</link>\n"
    xml += "    <guid isPermaLink=\"true\">" + escape_xml(link) + "</guid>\n"
    xml += "    <pubDate>" + escape_xml(post.date) + "</pubDate>\n"
    xml += "    <description><![CDATA[" +
      post.content_html +
      "]]></description>\n"
    xml += "  </item>\n"
  }

  xml += "</channel>\n"
  xml += "</rss>\n"
  xml
}

///|
fn generate_search_json(posts : Array[BlogPost]) -> String {
  let items = []
  for post in posts {
    let mut snippet = strip_html_tags(post.content_html)
    if snippet.length() > 150 {
      snippet = snippet[0:150].to_owned() + "..."
    }

    let mut item = "  {\n"
    item += "    \"title\": \"" + escape_json_str(post.title) + "\",\n"
    item += "    \"url\": \"" +
      escape_json_str(
        slugify_path(post.filename.replace(old=".md", new="")) + ".html",
      ) +
      "\",\n"
    item += "    \"date\": \"" + escape_json_str(post.date) + "\",\n"
    item += "    \"snippet\": \"" + escape_json_str(snippet) + "\"\n"
    item += "  }"
    items.push(item)
  }

  let mut json = "[\n"
  for idx, item in items {
    if idx > 0 {
      json += ",\n"
    }
    json += item
  }
  json += "\n]"
  json
}

///|
fn generate_sitemap(pages : Array[GeneratedPage], config : Config) -> String {
  let mut xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
  xml += "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
  for page in pages {
    if page.path.has_suffix(".html") {
      xml += "  <url><loc>" +
        escape_xml(join_url(config.site_url, page.path)) +
        "</loc></url>\n"
    }
  }
  xml += "</urlset>\n"
  xml
}

///|
fn join_url(base : String, path : String) -> String {
  if base.has_suffix("/") {
    base + path
  } else {
    base + "/" + path
  }
}

///|
pub fn slugify_path(text : String) -> String {
  let mut slug = ""
  let mut last_was_dash = false
  for i = 0; i < text.length(); i = i + 1 {
    let ch = text[i]
    if (ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9') {
      slug += ch.to_int().unsafe_to_char().to_string()
      last_was_dash = false
    } else if ch >= 'A' && ch <= 'Z' {
      slug += (ch.to_int() + 32).unsafe_to_char().to_string()
      last_was_dash = false
    } else if !last_was_dash && slug != "" {
      slug += "-"
      last_was_dash = true
    }
  }
  while slug.has_suffix("-") {
    slug = slug[0:slug.length() - 1].to_owned()
  }
  if slug == "" {
    "untitled"
  } else {
    slug
  }
}

///|
fn escape_html_text(text : String) -> String {
  let mut res = ""
  for i = 0; i < text.length(); i = i + 1 {
    let char_str = text[i:i + 1].to_owned()
    match char_str {
      "<" => res += "&lt;"
      ">" => res += "&gt;"
      "&" => res += "&amp;"
      "\"" => res += "&quot;"
      "'" => res += "&#39;"
      _ => res += char_str
    }
  }
  res
}

///|
fn escape_xml(text : String) -> String {
  let mut res = ""
  for i = 0; i < text.length(); i = i + 1 {
    let char_str = text[i:i + 1].to_owned()
    match char_str {
      "<" => res += "&lt;"
      ">" => res += "&gt;"
      "&" => res += "&amp;"
      "\"" => res += "&quot;"
      "'" => res += "&apos;"
      _ => res += char_str
    }
  }
  res
}

///|
pub fn escape_json_str(text : String) -> String {
  let mut res = ""
  for i = 0; i < text.length(); i = i + 1 {
    let char_str = text[i:i + 1].to_owned()
    match char_str {
      "\"" => res += "\\\""
      "\\" => res += "\\\\"
      "\n" => res += "\\n"
      "\r" => res += "\\r"
      "\t" => res += "\\t"
      _ => res += char_str
    }
  }
  res
}

///|
fn strip_html_tags(html : String) -> String {
  let mut res = ""
  let mut inside_tag = false
  for i = 0; i < html.length(); i = i + 1 {
    let char_str = html[i:i + 1].to_owned()
    if char_str == "<" {
      inside_tag = true
    } else if char_str == ">" {
      inside_tag = false
    } else if !inside_tag {
      res += char_str
    }
  }
  res.trim().to_owned()
}
