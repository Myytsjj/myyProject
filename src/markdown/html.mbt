///|

///|
pub enum Event {
  StartBlock(String) // Tag name
  EndBlock(String)
  StartInline(String)
  EndInline(String)
  TextEvent(String)
  SelfClosing(String)
}

// Convert AST to Event Stream

///|
pub fn to_events(blocks : Array[Block]) -> Array[Event] {
  let events = []

  fn block_to_events(b : Block) {
    match b {
      Heading(level, inlines) => {
        let tag = "h" + level.to_string()
        events.push(Event::StartBlock(tag))
        for inline in inlines {
          inline_to_events(inline, events)
        }
        events.push(Event::EndBlock(tag))
      }
      Paragraph(inlines) => {
        events.push(Event::StartBlock("p"))
        for inline in inlines {
          inline_to_events(inline, events)
        }
        events.push(Event::EndBlock("p"))
      }
      ThematicBreak => events.push(Event::SelfClosing("hr"))
      CodeBlock(info, content) => {
        events.push(Event::StartBlock("pre"))
        if info != "" {
          events.push(
            Event::StartBlock(
              "code class=\"language-" + escape_html_attr(info) + "\"",
            ),
          )
        } else {
          events.push(Event::StartBlock("code"))
        }
        events.push(Event::TextEvent(content))
        events.push(Event::EndBlock("code"))
        events.push(Event::EndBlock("pre"))
      }
      Blockquote(nested) => {
        events.push(Event::StartBlock("blockquote"))
        for nb in nested {
          block_to_events(nb)
        }
        events.push(Event::EndBlock("blockquote"))
      }
      List(is_ordered, items) => {
        let tag = if is_ordered { "ol" } else { "ul" }
        events.push(Event::StartBlock(tag))
        for item in items {
          events.push(Event::StartBlock("li"))
          for b in item {
            block_to_events(b)
          }
          events.push(Event::EndBlock("li"))
        }
        events.push(Event::EndBlock(tag))
      }
    }
  }

  for b in blocks {
    block_to_events(b)
  }

  events
}

///|
fn inline_to_events(inline : Inline, events : Array[Event]) -> Unit {
  match inline {
    Text(t) => events.push(Event::TextEvent(t))
    CodeSpan(c) => {
      events.push(Event::StartInline("code"))
      events.push(Event::TextEvent(c))
      events.push(Event::EndInline("code"))
    }
    Emphasis(children) => {
      events.push(Event::StartInline("em"))
      for child in children {
        inline_to_events(child, events)
      }
      events.push(Event::EndInline("em"))
    }
    Strong(children) => {
      events.push(Event::StartInline("strong"))
      for child in children {
        inline_to_events(child, events)
      }
      events.push(Event::EndInline("strong"))
    }
    Link(url, title, content) => {
      let mut tag = "a href=\"" + sanitize_url(url) + "\""
      if title != "" {
        tag += " title=\"" + escape_html_attr(title) + "\""
      }
      events.push(Event::StartInline(tag))
      for child in content {
        inline_to_events(child, events)
      }
      events.push(Event::EndInline("a"))
    }
    Image(url, title, alt) => {
      let mut tag = "img src=\"" +
        sanitize_url(url) +
        "\" alt=\"" +
        escape_html_attr(alt) +
        "\""
      if title != "" {
        tag += " title=\"" + escape_html_attr(title) + "\""
      }
      events.push(Event::SelfClosing(tag))
    }
    HardBreak => events.push(Event::SelfClosing("br"))
    SoftBreak => events.push(Event::TextEvent("\n"))
  }
}

///|
pub fn render_html(events : Array[Event]) -> String {
  let mut output = ""
  for ev in events {
    match ev {
      StartBlock(tag) => output += "<" + tag + ">\n"
      EndBlock(tag) => {
        // Tag name can be followed by attributes, extract only tag name
        let space_idx = tag.find(" ")
        let tag_name = match space_idx {
          Some(idx) => tag[0:idx].to_owned()
          None => tag
        }
        output += "</" + tag_name + ">\n"
      }
      StartInline(tag) => output += "<" + tag + ">"
      EndInline(tag) => {
        let space_idx = tag.find(" ")
        let tag_name = match space_idx {
          Some(idx) => tag[0:idx].to_owned()
          None => tag
        }
        output += "</" + tag_name + ">"
      }
      TextEvent(t) => output += escape_html(t)
      SelfClosing(tag) => output += "<" + tag + " />\n"
    }
  }
  output
}

///|
fn escape_html(text : String) -> String {
  let mut res = ""
  for i = 0; i < text.length(); i = i + 1 {
    match char_at(text, i) {
      '<' => res += "&lt;"
      '>' => res += "&gt;"
      '&' => res += "&amp;"
      '"' => res += "&quot;"
      c => res += c.to_string()
    }
  }
  res
}

///|
fn escape_html_attr(text : String) -> String {
  let mut res = ""
  for i = 0; i < text.length(); i = i + 1 {
    match char_at(text, i) {
      '<' => res += "&lt;"
      '>' => res += "&gt;"
      '&' => res += "&amp;"
      '"' => res += "&quot;"
      '\'' => res += "&#39;"
      c => res += c.to_string()
    }
  }
  res
}

///|
fn to_ascii_lower(text : String) -> String {
  let mut res = ""
  for i = 0; i < text.length(); i = i + 1 {
    let ch = text[i]
    if ch >= 'A' && ch <= 'Z' {
      res += (ch.to_int() + 32).unsafe_to_char().to_string()
    } else {
      res += char_at(text, i).to_string()
    }
  }
  res
}

///|
fn sanitize_url(url : String) -> String {
  let trimmed = url.trim().to_owned()
  let lower = to_ascii_lower(trimmed)
  if lower.has_prefix("javascript:") ||
    lower.has_prefix("vbscript:") ||
    lower.has_prefix("data:") {
    "#unsafe-url"
  } else {
    escape_html_attr(trimmed)
  }
}
